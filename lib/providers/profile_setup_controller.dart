// lib/providers/profile_setup_controller.dart
//
// Controls the profile setup flow for both client and worker accounts.
//
// KEY DESIGN DECISIONS:
//
//   1. On successful submit, `accountRole` is saved to SharedPreferences
//      immediately.  This is the signal SplashController uses as a fallback
//      when the backend is temporarily unreachable on the next cold start.
//      Without this write, a new user who set up their profile while the
//      server was unreachable would be routed back to role-selection on
//      every reopen — or worse, to /home with an empty profile.
//
//   2. State transitions during submit:
//        idle → submitting → uploadingImage (if avatar) → submitting → success|error
//      The button's `canSubmitClient/Worker` gate and `isLoading` computed
//      getter keep the CTA disabled for the entire operation.
//
//   3. Every async state write is guarded with `if (!mounted) return` to
//      prevent StateError when the provider is disposed mid-operation
//      (e.g. user presses back while upload is running).
//
//   4. Exponential back-off between upload retries with a mounted check
//      between sleeps so a disposed provider doesn't hold a sleeping Future.

import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_setup_state.dart';
import '../models/user_model.dart';
import '../models/profession_model.dart';
import '../services/api_service.dart';
import '../services/local_ai_service.dart';
import '../services/media_service.dart';
import '../utils/constants.dart';
import 'core_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────

class ProfileSetupController extends StateNotifier<ProfileSetupState> {
  final ApiService     _api;
  final MediaService   _media;
  final LocalAiService _ai;

  static const int      _uploadRetries = 3;
  static const Duration _submitTimeout = Duration(seconds: 20);

  ProfileSetupController({
    required ApiService     api,
    required MediaService   media,
    required LocalAiService ai,
  })  : _api   = api,
        _media = media,
        _ai    = ai,
        super(const ProfileSetupState());

  // ══════════════════════════════════════════════════════════════════════════
  // Field setters
  // ══════════════════════════════════════════════════════════════════════════

  void setName(String name) {
    state = state.copyWith(name: name, clearError: true);
  }

  void setAvatarPath(String? localPath) {
    state = state.copyWith(
      avatarLocalPath: localPath,
      clearAvatar:     localPath == null,
    );
  }

  void setAvatarEmoji(String emoji) {
    state = state.copyWith(
      avatarEmoji:     emoji,
      avatarLocalPath: null,
    );
  }

  void setProfession(String key) {
    if (!kValidProfessionKeys.contains(key)) return;
    state = state.copyWith(profession: key, clearError: true);
  }

  void clearProfession() {
    state = state.copyWith(clearProfession: true);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Voice profession detection
  // ══════════════════════════════════════════════════════════════════════════

  Future<String?> setProfessionByVoice(
    Uint8List audioBytes, {
    String mime = 'audio/m4a',
  }) async {
    if (audioBytes.isEmpty || state.isVoiceProcessing) return null;

    state = state.copyWith(isVoiceProcessing: true);

    try {
      final intent = await _ai.extractFromAudio(audioBytes, mime: mime);
      final key    = intent.profession;

      if (!mounted) return null;

      if (key != null && kValidProfessionKeys.contains(key)) {
        state = state.copyWith(
          profession:        key,
          isVoiceProcessing: false,
          clearError:        true,
        );
        _log('Voice detected profession: $key');
        return key;
      }

      state = state.copyWith(
        isVoiceProcessing: false,
        errorKey:          'errors.voice_profession_not_found',
      );
      return null;
    } catch (e) {
      if (!mounted) return null;
      _logError('setProfessionByVoice', e);
      state = state.copyWith(
        isVoiceProcessing: false,
        errorKey:          'errors.voice_generic',
      );
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Submit
  // ══════════════════════════════════════════════════════════════════════════

  Future<bool> submitClientProfile() async {
    if (!state.canSubmitClient) return false;
    return _submit(isWorker: false);
  }

  Future<bool> submitWorkerProfile() async {
    if (!state.canSubmitWorker) return false;
    return _submit(isWorker: true);
  }

  Future<bool> _submit({required bool isWorker}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      state = state.copyWith(
        status:   ProfileSetupStatus.error,
        errorKey: 'errors.no_user',
      );
      return false;
    }

    // Transition to submitting immediately — keeps the CTA button disabled
    // and the UI showing a loading indicator for the whole operation.
    state = state.copyWith(
      status:     ProfileSetupStatus.submitting,
      clearError: true,
    );

    // ── Step 1: upload avatar ─────────────────────────────────────────────
    String? storedPath;
    if (state.avatarLocalPath != null) {
      state = state.copyWith(status: ProfileSetupStatus.uploadingImage);

      storedPath = await _uploadImageWithRetry(state.avatarLocalPath!);
      if (storedPath == null) return false; // error state set inside

      if (!mounted) return false;
      state = state.copyWith(status: ProfileSetupStatus.submitting);
    }

    // ── Step 2: build model ───────────────────────────────────────────────
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

    final userModel = UserModel(
      id:              uid,
      name:            state.name.trim(),
      email:           '',
      phoneNumber:     phone,
      role:            isWorker ? 'worker' : 'client',
      profession:      isWorker ? state.profession : null,
      profileImageUrl: storedPath,
      lastUpdated:     DateTime.now(),
    );

    // ── Step 3: POST to backend ───────────────────────────────────────────
    try {
      if (isWorker) {
        await _api.createOrUpdateWorker(userModel).timeout(_submitTimeout);
      } else {
        await _api.createOrUpdateUser(userModel).timeout(_submitTimeout);
      }

      if (!mounted) return false;

      // Persist the role immediately so SplashController can resolve it from
      // SharedPreferences on the next cold start, even when the backend is
      // temporarily unreachable.  This is the single write that prevents the
      // "failed submit → works on reopen" symptom.
      await _persistRoleToPrefs(isWorker: isWorker);

      if (!mounted) return false;
      state = state.copyWith(
        status:     ProfileSetupStatus.success,
        clearError: true,
      );
      _log('Profile created: uid=$uid isWorker=$isWorker');
      return true;

    } catch (e) {
      if (!mounted) return false;
      _logError('_submit', e);
      state = state.copyWith(
        status:   ProfileSetupStatus.error,
        errorKey: 'errors.submit_failed',
      );
      return false;
    }
  }

  // ── SharedPreferences helper ──────────────────────────────────────────────

  /// Writes the resolved role to SharedPreferences so SplashController can
  /// recover it when the backend is offline on the next app start.
  Future<void> _persistRoleToPrefs({required bool isWorker}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        PrefKeys.accountRole,
        isWorker ? UserType.worker : UserType.user,
      );
    } catch (e) {
      // Non-fatal — SplashController will just fall back to roleSelection.
      _logError('_persistRoleToPrefs', e);
    }
  }

  // ── Image upload with retry ───────────────────────────────────────────────

  Future<String?> _uploadImageWithRetry(String localPath) async {
    for (int attempt = 1; attempt <= _uploadRetries; attempt++) {
      try {
        final result = await _media.uploadImage(File(localPath));

        if (!mounted) return null;
        state = state.copyWith(uploadProgress: 1.0);
        return result.storedPath;

      } catch (e) {
        _logError('uploadImage attempt $attempt/$_uploadRetries', e);

        if (attempt == _uploadRetries) {
          if (mounted) {
            state = state.copyWith(
              status:         ProfileSetupStatus.error,
              uploadProgress: 0.0,
              errorKey:       'errors.image_upload_failed',
            );
          }
          return null;
        }

        if (!mounted) return null;
        await Future.delayed(Duration(seconds: attempt * 2));
        if (!mounted) return null;
      }
    }
    return null;
  }

  // ── Logging ───────────────────────────────────────────────────────────────

  void _log(String msg) {
    if (kDebugMode) debugPrint('[ProfileSetupController] $msg');
  }

  void _logError(String method, Object error) {
    if (kDebugMode) debugPrint('[ProfileSetupController] ✗ $method: $error');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final profileSetupControllerProvider =
    StateNotifierProvider.autoDispose<ProfileSetupController, ProfileSetupState>((ref) {
  return ProfileSetupController(
    api:   ref.read(apiServiceProvider),
    media: ref.read(mediaServiceProvider),
    ai:    ref.read(localAiServiceProvider),
  );
});
