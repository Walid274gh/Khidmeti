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

// FIX (P1): renamed from SplashState to SplashPhase to free up the name for
// the immutable state class required by StateNotifier<T>. Screens that
// previously switched on SplashState.xxx must update to SplashPhase.xxx.
enum SplashPhase { initializing, animating, ready, error }

enum SplashErrorType { none, noInternet, serverError, timeout, unknown }

// ============================================================================
// STATE
// ============================================================================

// FIX (P1): replaces the scattered private fields on ChangeNotifier with a
// single immutable value type — the idiomatic Riverpod StateNotifier pattern.
// Consumers watch splashControllerProvider directly to get this value; no
// need to call .state on the controller object.
class SplashState {
  final SplashPhase phase;
  final SplashErrorType errorType;

  const SplashState({
    this.phase     = SplashPhase.initializing,
    this.errorType = SplashErrorType.none,
  });

  bool get canRetry => phase == SplashPhase.error;

  SplashState copyWith({
    SplashPhase?     phase,
    SplashErrorType? errorType,
  }) {
    return SplashState(
      phase:     phase     ?? this.phase,
      errorType: errorType ?? this.errorType,
    );
  }
}

// ============================================================================
// CONTROLLER
// ============================================================================

// FIX (P1): migrated from ChangeNotifier + ChangeNotifierProvider to
// StateNotifier<SplashState> + StateNotifierProvider. Benefits:
//   • Typed state value — consumers watch SplashState directly.
//   • mounted check replaces _isDisposed bool.
//   • No notifyListeners(); state assignments trigger rebuilds automatically.
//   • Fully overridable in ProviderScope for widget tests.
class SplashController extends StateNotifier<SplashState> {
  final Ref _ref;

  // Internal coordination gates — not part of the exposed state because
  // consumers only need to react to the resolved phase.
  bool  _isAnimationComplete  = false;
  bool  _isAuthChecked        = false;
  bool  _isMinDurationElapsed = false;

  // Mutex: prevents concurrent initialize() calls (e.g. double-tap retry).
  bool _isInitializing = false;

  /// Minimum time the splash is visible — prevents a jarring instant transition
  /// on fast devices where auth resolves before the logo animation finishes.
  static const Duration _kMinSplashDuration = Duration(seconds: 3);

  /// Global timeout for the full init sequence.
  static const Duration _globalInitTimeout  = Duration(seconds: 15);

  SplashController(this._ref) : super(const SplashState());

  // --------------------------------------------------------------------------
  // Initialization
  // --------------------------------------------------------------------------

  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      _isAnimationComplete  = false;
      _isAuthChecked        = false;
      _isMinDurationElapsed = false;

      if (!mounted) return;
      state = const SplashState(phase: SplashPhase.initializing);

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
      if (!mounted) return;
      _isAuthChecked = true;
      state = state.copyWith(
        phase:     SplashPhase.error,
        errorType: SplashErrorType.timeout,
      );
    } on FirebaseException catch (e) {
      AppLogger.error('SplashController.initialize (Firebase)', e);
      if (!mounted) return;
      _isAuthChecked = true;
      state = state.copyWith(
        phase:     SplashPhase.error,
        errorType: _mapFirebaseError(e),
      );
    } catch (e, stack) {
      AppLogger.error('SplashController.initialize', '$e\n$stack');
      if (!mounted) return;
      _isAuthChecked = true;
      state = state.copyWith(
        phase:     SplashPhase.error,
        errorType: SplashErrorType.unknown,
      );
    } finally {
      _isInitializing = false;
    }
  }

  /// Called by SplashScreen when the branding animation finishes.
  void onAnimationComplete() {
    _isAnimationComplete = true;
    _updateState();
  }

  Future<void> retry() => initialize();

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  void _armMinDurationTimer() {
    Future.delayed(_kMinSplashDuration, () {
      if (!mounted) return;
      _isMinDurationElapsed = true;
      _updateState();
    });
  }

  void _updateState() {
    if (!mounted) return;
    if (state.phase == SplashPhase.error) return;

    // All three gates must clear before the app navigates:
    //   1. _isAuthChecked       — Firebase auth + role resolved
    //   2. _isAnimationComplete — Branding animation finished
    //   3. _isMinDurationElapsed — Minimum visible time elapsed
    if (_isAnimationComplete && _isAuthChecked && _isMinDurationElapsed) {
      state = state.copyWith(phase: SplashPhase.ready);
      _ref.read(appInitializedProvider.notifier).state = true;
      _ref.read(authRedirectNotifierProvider).notifyAuthReady();
    } else if (_isAuthChecked && !_isAnimationComplete) {
      state = state.copyWith(phase: SplashPhase.animating);
    }
  }

  /// Resolves role from Firestore on cold launch and caches it in-memory
  /// and in SharedPreferences.
  Future<void> _resolveAndCacheRole(String uid) async {
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      final worker = await firestoreService.getWorker(uid);
      final role   = worker != null ? UserRole.worker : UserRole.client;

      // FIX (Suggestion 1): use setCachedUserRole helper instead of direct
      // state write so the write-guard contract is respected.
      setCachedUserRole(_ref, role);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        PrefKeys.accountRole,
        role == UserRole.worker ? UserType.worker : UserType.user,
      );

      AppLogger.info('SplashController: cached role=$role uid=$uid');
    } on FirebaseException catch (e) {
      // FIX (QA P0): permission-denied is a security issue — rethrow so the
      // outer handler sets phase=error instead of silently defaulting to client.
      if (e.code == 'permission-denied') {
        AppLogger.error(
          'SplashController._resolveAndCacheRole: PERMISSION_DENIED uid=$uid',
          e,
        );
        rethrow;
      }
      // On other Firestore errors, default to client — safest fallback.
      setCachedUserRole(_ref, UserRole.client);
      AppLogger.error('SplashController._resolveAndCacheRole', e);
    } catch (e) {
      setCachedUserRole(_ref, UserRole.client);
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
}

// ============================================================================
// PROVIDER
// ============================================================================

// FIX (P1): ChangeNotifierProvider.autoDispose → StateNotifierProvider.autoDispose.
// Consumers that previously watched the controller object directly now watch
// the typed SplashState value:
//   OLD: ref.watch(splashControllerProvider).state      → SplashState enum value
//   NEW: ref.watch(splashControllerProvider).phase      → SplashPhase enum value
//
// Method calls now route through .notifier:
//   OLD: ref.read(splashControllerProvider).initialize()
//   NEW: ref.read(splashControllerProvider.notifier).initialize()
final splashControllerProvider =
    StateNotifierProvider.autoDispose<SplashController, SplashState>(
  (ref) => SplashController(ref),
);
