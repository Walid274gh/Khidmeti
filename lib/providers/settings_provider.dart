// lib/providers/settings_provider.dart
//
// MOVED FROM: lib/screens/settings/settings_provider.dart
// REASON: A StateNotifier has no business living inside a screen folder.
//         All other providers live in lib/providers/. This move corrects the
//         dependency direction so settings_screen.dart imports upward from
//         lib/providers/ rather than importing from its own folder.
//
// FIX (Settings Audit P1): SettingsNotifier was calling
// FirebaseAnalytics.instance.logEvent() directly from the state layer,
// creating a second direct Firebase dependency and making the notifier
// untestable without a real Firebase instance.
// Fix: replaced with ref.read(analyticsServiceProvider) calls.
//
// IMPORT PATHS updated for new location (lib/providers/ → lib/utils/ is ../utils/):
//   OLD: '../../providers/auth_providers.dart'  → './auth_providers.dart'
//   OLD: '../../providers/core_providers.dart'  → './core_providers.dart'
//   OLD: '../../utils/constants.dart'           → '../utils/constants.dart'

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_providers.dart';
import 'core_providers.dart';
import 'user_role_provider.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

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
  /// FIX (Settings Audit P1): replaced FirebaseAnalytics.instance.logEvent()
  ///   with ref.read(analyticsServiceProvider).logUserSignedOut().
  Future<void> signOut() async {
    if (!mounted) return;
    if (state.isSigningOut) return;

    state = state.copyWith(isSigningOut: true);

    final cachedRoleNotifier = _ref.read(cachedUserRoleProvider.notifier);
    final authService        = _ref.read(authServiceProvider);
    final firestoreService   = _ref.read(firestoreServiceProvider);
    final uid                = authService.user?.uid;

    // FIX: Fire-and-forget analytics via service layer (no direct Firebase call).
    _ref.read(analyticsServiceProvider).logUserSignedOut(
      accountType: state.isWorkerAccount ? 'worker' : 'client',
    );

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
  /// FIX (Settings Audit P1): replaced FirebaseAnalytics.instance.logEvent()
  ///   with ref.read(analyticsServiceProvider).logUserDeletedAccount().
  Future<String?> deleteAccount() async {
    if (!mounted) return null;
    if (state.isDeletingAccount) return null;

    state = state.copyWith(isDeletingAccount: true);

    final cachedRoleNotifier = _ref.read(cachedUserRoleProvider.notifier);
    final authService        = _ref.read(authServiceProvider);

    // FIX: Fire-and-forget analytics via service layer.
    _ref.read(analyticsServiceProvider).logUserDeletedAccount(
      accountType: state.isWorkerAccount ? 'worker' : 'client',
    );

    try {
      cachedRoleNotifier.state = UserRole.unknown;

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final errorKey = await authService.deleteAccount();
      if (errorKey != null) {
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
