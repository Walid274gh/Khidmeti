// lib/providers/splash_controller.dart

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_providers.dart';
import '../providers/user_role_provider.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import 'core_providers.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum SplashState { initializing, animating, ready, error }

enum SplashErrorType { none, noInternet, serverError, timeout, unknown }

// ============================================================================
// CONTROLLER
// ============================================================================

class SplashController extends ChangeNotifier {
  final Ref _ref;

  SplashState     _state    = SplashState.initializing;
  bool  _isAnimationComplete   = false;
  bool  _isAuthChecked         = false;
  // FIX (Architect): minimum splash duration was previously owned by
  // SplashScreen — broken separation of concerns. All timing logic now lives
  // in the controller. The screen only reports UI events (branding done) and
  // delegates the coordination gate entirely to the controller.
  bool  _isMinDurationElapsed  = false;
  SplashErrorType _errorType   = SplashErrorType.none;

  // Mutex: prevents concurrent initialize() calls (e.g. double-tap retry).
  bool _isInitializing = false;
  // Guard: prevents notifyListeners() on a disposed controller.
  bool _isDisposed     = false;

  /// Minimum time the splash is visible — prevents a jarring instant transition
  /// on fast devices where auth resolves before the logo animation finishes.
  static const Duration _kMinSplashDuration  = Duration(seconds: 3);

  /// Global timeout for the full init sequence.
  /// Prevents the splash blocking for up to 42s when Firestore retries accumulate.
  static const Duration _globalInitTimeout   = Duration(seconds: 15);

  SplashState     get state      => _state;
  SplashErrorType get errorType  => _errorType;
  bool            get canRetry   => _state == SplashState.error;

  SplashController(this._ref);

  // --------------------------------------------------------------------------
  // Initialization
  // --------------------------------------------------------------------------

  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      _state               = SplashState.initializing;
      _isAnimationComplete = false;
      _isAuthChecked       = false;
      _isMinDurationElapsed = false;
      _errorType           = SplashErrorType.none;
      _safeNotify();

      // Arm the minimum splash duration timer in parallel with auth init.
      _armMinDurationTimer();

      final authService = _ref.read(authServiceProvider);

      await Future.wait([
        authService.waitForInitialization(),
        Future.delayed(const Duration(seconds: 2)),
      ]).timeout(
        _globalInitTimeout,
        onTimeout: () {
          AppLogger.warning(
            'SplashController.initialize: ${_globalInitTimeout.inSeconds}s '
            'global timeout reached',
          );
          throw TimeoutException(
            'Initialization global timeout',
            _globalInitTimeout,
          );
        },
      );

      if (authService.isLoggedIn && authService.user != null) {
        await _resolveAndCacheRole(authService.user!.uid);
      }

      _isAuthChecked = true;
      _updateState();
    } on TimeoutException {
      AppLogger.warning('SplashController.initialize: timeout');
      _errorType     = SplashErrorType.timeout;
      _state         = SplashState.error;
      _isAuthChecked = true;
      _safeNotify();
    } on FirebaseException catch (e) {
      AppLogger.error('SplashController.initialize (Firebase)', e);
      _errorType     = _mapFirebaseError(e);
      _state         = SplashState.error;
      _isAuthChecked = true;
      _safeNotify();
    } catch (e, stack) {
      AppLogger.error('SplashController.initialize', '$e\n$stack');
      _errorType     = SplashErrorType.unknown;
      _state         = SplashState.error;
      _isAuthChecked = true;
      _safeNotify();
    } finally {
      _isInitializing = false;
    }
  }

  /// Called by SplashScreen when the branding animation finishes.
  /// The screen no longer needs to coordinate with a min-duration timer —
  /// it simply reports this single event and the controller handles the rest.
  void onAnimationComplete() {
    _isAnimationComplete = true;
    _updateState();
  }

  Future<void> retry() => initialize();

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  /// Arms the minimum splash duration timer.
  /// If the controller is disposed before the timer fires, the callback is
  /// a no-op thanks to the [_isDisposed] guard.
  void _armMinDurationTimer() {
    Future.delayed(_kMinSplashDuration, () {
      if (_isDisposed) return;
      _isMinDurationElapsed = true;
      _updateState();
    });
  }

  void _updateState() {
    if (_state == SplashState.error) return;

    // All three gates must clear before the app navigates:
    //   1. _isAuthChecked       — Firebase auth + role resolved
    //   2. _isAnimationComplete — Branding animation finished
    //   3. _isMinDurationElapsed — Minimum visible time elapsed
    if (_isAnimationComplete && _isAuthChecked && _isMinDurationElapsed) {
      _state = SplashState.ready;
      _ref.read(appInitializedProvider.notifier).state = true;
      _ref.read(authRedirectNotifierProvider).notifyAuthReady();
      _safeNotify();
    } else if (_isAuthChecked && !_isAnimationComplete) {
      _state = SplashState.animating;
      _safeNotify();
    }
  }

  /// Resolves role from Firestore on cold launch and caches it in-memory
  /// and in SharedPreferences.
  Future<void> _resolveAndCacheRole(String uid) async {
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      final worker = await firestoreService.getWorker(uid);
      final role   = worker != null ? UserRole.worker : UserRole.client;

      _ref.read(cachedUserRoleProvider.notifier).state = role;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        PrefKeys.accountRole,
        role == UserRole.worker ? UserType.worker : UserType.user,
      );

      AppLogger.info('SplashController: cached role=$role uid=$uid');
    } on FirebaseException catch (e) {
      // FIX (QA P0): distinguish permission-denied from generic Firestore
      // errors. A PERMISSION_DENIED means Firebase security rules rejected
      // this user — silently defaulting to client and letting them into the
      // app is a security risk. Rethrowing lets the outer FirebaseException
      // handler set state=error and force the user to retry (or sign out).
      if (e.code == 'permission-denied') {
        AppLogger.error(
          'SplashController._resolveAndCacheRole: PERMISSION_DENIED uid=$uid',
          e,
        );
        rethrow;
      }
      // On other Firestore errors, default to client — safest fallback.
      _ref.read(cachedUserRoleProvider.notifier).state = UserRole.client;
      AppLogger.error('SplashController._resolveAndCacheRole', e);
    } catch (e) {
      _ref.read(cachedUserRoleProvider.notifier).state = UserRole.client;
      AppLogger.error('SplashController._resolveAndCacheRole', e);
    }
  }

  SplashErrorType _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'network-request-failed':
        return SplashErrorType.noInternet;
      case 'internal-error':
      case 'unavailable':
      case 'permission-denied':
        return SplashErrorType.serverError;
      case 'deadline-exceeded':
        return SplashErrorType.timeout;
      default:
        return SplashErrorType.unknown;
    }
  }

  /// notifyListeners() guarded against post-dispose calls.
  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

final splashControllerProvider =
    ChangeNotifierProvider.autoDispose<SplashController>((ref) {
  return SplashController(ref);
});
