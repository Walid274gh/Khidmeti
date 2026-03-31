// lib/screens/settings/settings_provider.dart

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/user_role_provider.dart';
import '../../utils/constants.dart';
import '../../utils/logger.dart';

// ============================================================================
// SETTINGS STATE
// ============================================================================

enum SettingsStatus { idle, loading, error }

class SettingsState {
  final SettingsStatus status;
  final String? userName;
  final String? professionLabel;
  final String? profileImageUrl;
  final UserRole activeRole;
  final bool isWorkerAccount;

  // Separate flag for sign-out / delete-account so SettingsStatus.loading
  // is not misused — skeleton loader during those operations is semantically wrong.
  final bool isSigningOut;
  final bool isDeletingAccount;

  final double? workerAverageRating;
  final int?    workerRatingCount;

  final String? errorMessage;

  const SettingsState({
    this.status              = SettingsStatus.loading,
    this.userName,
    this.professionLabel,
    this.profileImageUrl,
    this.activeRole          = UserRole.client,
    this.isWorkerAccount     = false,
    this.isSigningOut        = false,
    this.isDeletingAccount   = false,
    this.workerAverageRating,
    this.workerRatingCount,
    this.errorMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    String?  userName,
    String?  professionLabel,
    String?  profileImageUrl,
    UserRole? activeRole,
    bool?    isWorkerAccount,
    bool?    isSigningOut,
    bool?    isDeletingAccount,
    double?  workerAverageRating,
    int?     workerRatingCount,
    String?  errorMessage,
  }) {
    return SettingsState(
      status:              status              ?? this.status,
      userName:            userName            ?? this.userName,
      professionLabel:     professionLabel     ?? this.professionLabel,
      profileImageUrl:     profileImageUrl     ?? this.profileImageUrl,
      activeRole:          activeRole          ?? this.activeRole,
      isWorkerAccount:     isWorkerAccount     ?? this.isWorkerAccount,
      isSigningOut:        isSigningOut        ?? this.isSigningOut,
      isDeletingAccount:   isDeletingAccount   ?? this.isDeletingAccount,
      workerAverageRating: workerAverageRating ?? this.workerAverageRating,
      workerRatingCount:   workerRatingCount   ?? this.workerRatingCount,
      errorMessage:        errorMessage,
    );
  }
}

// ============================================================================
// SETTINGS NOTIFIER
// ============================================================================

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const SettingsState()) {
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final authService      = _ref.read(authServiceProvider);
      final firestoreService = _ref.read(firestoreServiceProvider);
      final uid              = authService.user?.uid;

      if (uid == null) {
        state = state.copyWith(
          status:       SettingsStatus.error,
          errorMessage: 'errors.no_user',
        );
        return;
      }

      final prefs            = await SharedPreferences.getInstance();
      final savedAccountRole = prefs.getString(PrefKeys.accountRole);

      // Fast path: accountRole already cached.
      if (savedAccountRole == UserType.worker) {
        final firebaseUser = authService.user;
        state = state.copyWith(
          status:          SettingsStatus.idle,
          userName:        firebaseUser?.displayName ?? '',
          activeRole:      UserRole.worker,
          isWorkerAccount: true,
        );

        final worker = await firestoreService.getWorker(uid);
        if (worker != null && mounted) {
          state = state.copyWith(
            userName:            worker.name,
            professionLabel:     worker.profession,
            profileImageUrl:     worker.profileImageUrl,
            workerAverageRating: worker.averageRating,
            workerRatingCount:   worker.ratingCount,
          );
        }
        AppLogger.info('Settings loaded: worker (cached)');
        return;
      }

      // Slow path: check Firestore.
      final worker = await firestoreService.getWorker(uid);
      if (worker != null) {
        await prefs.setString(PrefKeys.accountRole, UserType.worker);
        if (mounted) {
          state = state.copyWith(
            status:              SettingsStatus.idle,
            userName:            worker.name,
            professionLabel:     worker.profession,
            profileImageUrl:     worker.profileImageUrl,
            activeRole:          UserRole.worker,
            isWorkerAccount:     true,
            workerAverageRating: worker.averageRating,
            workerRatingCount:   worker.ratingCount,
          );
        }
        AppLogger.info('Settings loaded: worker (Firestore)');
        return;
      }

      final user = await firestoreService.getUser(uid);
      if (user != null && mounted) {
        state = state.copyWith(
          status:          SettingsStatus.idle,
          userName:        user.name,
          activeRole:      UserRole.client,
          isWorkerAccount: false,
        );
        AppLogger.info('Settings loaded: client');
        return;
      }

      final firebaseUser = authService.user;
      if (mounted) {
        state = state.copyWith(
          status:          SettingsStatus.idle,
          userName:        firebaseUser?.displayName ?? '',
          activeRole:      UserRole.client,
          isWorkerAccount: false,
        );
      }
    } catch (e, st) {
      AppLogger.error('SettingsNotifier._loadProfileData', e, st);
      if (mounted) {
        state = state.copyWith(
          status:       SettingsStatus.error,
          errorMessage: 'errors.load_failed',
        );
      }
    }
  }

  /// Signs the user out with a clean teardown sequence.
  ///
  /// FIX — Bug: isSigningOut guard prevents double-tap race condition.
  /// FIX — FCM token cleared from Firestore before sign-out to prevent
  ///   cross-user notification delivery on shared devices.
  /// FIX — Removed empty Future.microtask({}) — was a no-op with no effect
  ///   on Riverpod provider propagation.
  Future<void> signOut() async {
    if (!mounted) return;
    // Guard: prevent double-tap / concurrent sign-out calls.
    if (state.isSigningOut) return;

    state = state.copyWith(isSigningOut: true);

    final cachedRoleNotifier = _ref.read(cachedUserRoleProvider.notifier);
    final authService        = _ref.read(authServiceProvider);
    final firestoreService   = _ref.read(firestoreServiceProvider);
    final uid                = authService.user?.uid;

    // Fire-and-forget analytics before the session ends.
    FirebaseAnalytics.instance.logEvent(
      name: 'user_signed_out',
      parameters: {
        'account_type': state.isWorkerAccount ? 'worker' : 'client',
      },
    ).ignore();

    try {
      cachedRoleNotifier.state = UserRole.unknown;

      // Clear FCM token from Firestore so the next user on this device
      // receives their own notifications without inheriting the old token.
      if (uid != null) {
        try {
          await firestoreService.updateUserFcmToken(uid, '');
          if (state.isWorkerAccount) {
            await firestoreService.updateWorkerFcmToken(uid, '');
          }
          AppLogger.info('FCM token cleared for uid: $uid');
        } catch (fcmError) {
          // Non-fatal — sign-out continues even if FCM cleanup fails.
          AppLogger.warning('FCM cleanup failed: $fcmError');
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PrefKeys.accountRole);

      await authService.signOut();

    } catch (e) {
      AppLogger.error('SettingsNotifier.signOut', e);

      if (mounted) {
        cachedRoleNotifier.state = state.isWorkerAccount
            ? UserRole.worker
            : UserRole.client;
        state = state.copyWith(
          isSigningOut: false,
          status:       SettingsStatus.error,
          errorMessage: 'errors.signout_failed',
        );
      }
    }
  }

  /// Permanently deletes the Firebase Auth account and wipes local state.
  ///
  /// NOTE: Firestore data cleanup (users/workers documents, service requests,
  /// bids) is performed server-side by a Cloud Function triggered on
  /// Firebase Auth `user.delete` event — not client-side.
  ///
  /// If `errors.requires_recent_login` is returned, the UI must prompt the
  /// user to re-authenticate before retrying.
  Future<String?> deleteAccount() async {
    if (!mounted) return null;
    if (state.isDeletingAccount) return null;

    state = state.copyWith(isDeletingAccount: true);

    final cachedRoleNotifier = _ref.read(cachedUserRoleProvider.notifier);
    final authService        = _ref.read(authServiceProvider);

    FirebaseAnalytics.instance.logEvent(
      name: 'user_deleted_account',
      parameters: {
        'account_type': state.isWorkerAccount ? 'worker' : 'client',
      },
    ).ignore();

    try {
      cachedRoleNotifier.state = UserRole.unknown;

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Full clear — account is gone permanently.

      final errorKey = await authService.deleteAccount();
      if (errorKey != null) {
        // Restore role if deletion failed.
        if (mounted) {
          cachedRoleNotifier.state = state.isWorkerAccount
              ? UserRole.worker
              : UserRole.client;
          state = state.copyWith(
            isDeletingAccount: false,
            status:            SettingsStatus.error,
            errorMessage:      errorKey,
          );
        }
        return errorKey;
      }

      // On success Firebase authStateChanges emits null → router redirects.
      return null;

    } catch (e) {
      AppLogger.error('SettingsNotifier.deleteAccount', e);

      if (mounted) {
        cachedRoleNotifier.state = state.isWorkerAccount
            ? UserRole.worker
            : UserRole.client;
        state = state.copyWith(
          isDeletingAccount: false,
          status:            SettingsStatus.error,
          errorMessage:      'errors.delete_account_failed',
        );
      }
      return 'errors.delete_account_failed';
    }
  }

  Future<void> retry() async {
    if (mounted) state = const SettingsState();
    await _loadProfileData();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

final settingsProvider =
    StateNotifierProvider.autoDispose<SettingsNotifier, SettingsState>(
        (ref) => SettingsNotifier(ref));
