// lib/providers/auth_providers.dart
//
// Single home for all auth-adjacent state providers:
//   • appInitializedProvider
//   • AuthRedirectNotifier
//   • authRedirectNotifierProvider
//   • currentUserProvider
//   • currentUserIdProvider
//   • isAuthLoadingProvider
//   • isLoggedInProvider
//
// MERGE RATIONALE:
//   app_initialization_provider.dart was 31 lines imported by exactly 2 files.
//   auth_redirect_notifier.dart was 51 lines imported by exactly 2 files.
//   Both had zero growth potential — their contracts are frozen by design.
//   The four computed auth providers in core_providers.dart are logically
//   auth-domain and belong alongside their siblings.
//
// DEPENDENCY NOTE:
//   This file imports core_providers.dart to access authServiceProvider.
//   core_providers.dart exports this file via `export 'auth_providers.dart'`.
//   This is a one-directional import chain — NOT a circular dependency:
//     core_providers.dart EXPORTS auth_providers.dart (additive re-export).
//     auth_providers.dart IMPORTS core_providers.dart (to read authServiceProvider).
//   Dart's export directive does not create a compile-time cycle. The dependency
//   arrow is: auth_providers → core_providers, and core_providers re-exports
//   auth_providers for consumer convenience.
//   Consumers that only need auth symbols should import auth_providers.dart
//   directly to avoid pulling in the full core_providers graph.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_providers.dart';

// ============================================================================
// APP INITIALIZATION PROVIDER
// ============================================================================
//
// BUG-001 FIX
// ───────────
// appInitializedProvider is written ONCE by SplashController._updateState()
// when both conditions are met:
//   1. _isAnimationComplete = true  (splash animation finished)
//   2. _isAuthChecked = true        (auth + role resolution finished)
//
// The GoRouter redirect uses this as its primary gate: no routing decisions
// are made until this is true. This prevents premature redirect fires from
// authService.notifyListeners() (which fires as soon as Firebase resolves
// the credential, before Firestore role data has been fetched).
//
// CONTRACT: appInitializedProvider is set to true only AFTER both
//   cachedUserRoleProvider  and  resolvedViewModeIsWorkerProvider
// have been written by SplashController._resolveAndCacheRole().
// This guarantees the router can read them synchronously without async.

/// Tracks whether the app initialization sequence has completed.
///
/// false → SplashScreen is still running; no routing decisions made.
/// true  → Initialization done; router may redirect based on auth + role.
final appInitializedProvider = StateProvider<bool>((ref) => false);

// ============================================================================
// AUTH REDIRECT NOTIFIER
// ============================================================================
//
// WHY THIS EXISTS
// ───────────────
// GoRouter's `refreshListenable` triggers a full redirect re-evaluation every
// time the listenable notifies. If we use `AuthService` directly (which extends
// ChangeNotifier and calls notifyListeners() inside Firebase's authStateChanges
// stream), the router fires *before* the role is cached — because Firebase emits
// its stream event as soon as the credential resolves, not after our async
// Firestore role-fetch completes.
//
// This notifier is the *only* object passed to `refreshListenable` for
// login/register completion events. It is triggered manually by
// LoginController and RegisterController *after* both:
//   1. cachedUserRoleProvider has been written in memory.
//   2. SharedPreferences has been updated.
//
// For sign-out, the router uses a _UserIdentityListenable wrapper that
// filters AuthService notifications to only uid changes — so isLoading
// fluctuations no longer trigger redirect evaluations.

class AuthRedirectNotifier extends ChangeNotifier {
  /// Called by LoginController / RegisterController after the role has been
  /// fully cached in memory and SharedPreferences.
  void notifyAuthReady() {
    notifyListeners();
  }

  /// Called on sign-out. Resets no state here (controllers handle that),
  /// but triggers the router redirect so it can redirect to /login.
  void notifySignedOut() {
    notifyListeners();
  }
}

final authRedirectNotifierProvider =
    Provider<AuthRedirectNotifier>((ref) => AuthRedirectNotifier());

// ============================================================================
// COMPUTED AUTH PROVIDERS
// ============================================================================

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authServiceProvider).user;
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});

final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isLoading;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
