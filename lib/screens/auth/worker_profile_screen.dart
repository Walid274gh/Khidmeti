// lib/screens/auth/worker_profile_screen.dart
//
// Worker profile SETUP screen — shown once to new users who chose the
// "worker" role. Distinct from lib/screens/worker_profile/worker_profile_screen.dart.
//
// CLASS NAME: WorkerProfileSetupScreen
//
// NAVIGATION FIX (same root cause as user_profile_screen.dart):
//   Previously relied on "router watching firebaseAuthStreamProvider" which
//   never fires during profile setup (auth state doesn't change — user is
//   already signed in). submitWorkerProfile() now explicitly sets
//   cachedUserRoleProvider to UserRole.worker and navigates to /home.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/profile_setup_state.dart';
import '../../providers/profile_setup_controller.dart';
import '../../providers/user_role_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import 'widgets/auth_background.dart';
import 'widgets/auth_submit_button.dart';
import 'widgets/avatar_picker_widget.dart';
import 'widgets/profession_picker_v2.dart';
import 'widgets/voice_profession_button.dart';

// ─────────────────────────────────────────────────────────────────────────────

/// New-user worker profile setup. Called after role selection.
/// See [lib/screens/worker_profile/worker_profile_screen.dart] for the
/// public worker profile viewer.
class WorkerProfileSetupScreen extends ConsumerStatefulWidget {
  const WorkerProfileSetupScreen({super.key});

  @override
  ConsumerState<WorkerProfileSetupScreen> createState() =>
      _WorkerProfileSetupScreenState();
}

class _WorkerProfileSetupScreenState
    extends ConsumerState<WorkerProfileSetupScreen>
    with TickerProviderStateMixin {

  final _nameCtrl  = TextEditingController();
  final _nameFocus = FocusNode();

  final GlobalKey<ProfessionPickerV2State> _pickerKey =
      GlobalKey<ProfessionPickerV2State>();

  late final AnimationController _slideCtrl;
  late final Animation<double>    _fade;
  late final Animation<Offset>    _slide;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync:    this,
      duration: AppConstants.authCardEntranceDuration,
    )..forward();
    _fade  = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Voice detection callback ───────────────────────────────────────────────

  void _onVoiceProfessionDetected(String key) {
    ref.read(profileSetupControllerProvider.notifier).setProfession(key);
    _pickerKey.currentState?.autoSelect(key);
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    ref.read(profileSetupControllerProvider.notifier).setName(_nameCtrl.text);

    final success =
        await ref.read(profileSetupControllerProvider.notifier).submitWorkerProfile();

    if (success && mounted) {
      // FIX: Set the cached role to worker so MainNavigationScreen shows the
      // three-tab worker bar immediately, then navigate to /home.
      setCachedUserRole(
        ref.read(cachedUserRoleProvider.notifier),
        UserRole.worker,
        force: true,
      );
      context.go(AppRoutes.home);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(profileSetupControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: Stack(
          children: [
            AuthBackground(isDark: isDark),
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.only(
                          left:   AppConstants.paddingLg,
                          right:  AppConstants.paddingLg,
                          top:    AppConstants.paddingXl,
                          bottom: MediaQuery.of(context).viewInsets.bottom +
                                  AppConstants.paddingXl,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([

                            // ── Header ─────────────────────────────────────
                            Semantics(
                              header: true,
                              child: Text(
                                context.tr('worker_profile.title'),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight:    FontWeight.w700,
                                      letterSpacing: -0.5,
                                      color: isDark
                                          ? AppTheme.darkText
                                          : AppTheme.lightText,
                                    ),
                              ),
                            ),

                            const SizedBox(height: AppConstants.spacingXs),

                            Text(
                              context.tr('worker_profile.subtitle'),
                              style: TextStyle(
                                fontSize: AppConstants.fontSizeMd,
                                color: isDark
                                    ? AppTheme.darkSecondaryText
                                    : AppTheme.lightSecondaryText,
                              ),
                            ),

                            const SizedBox(height: AppConstants.spacingXl),

                            // ── Avatar ─────────────────────────────────────
                            AvatarPickerWidget(
                              selectedImagePath: state.avatarLocalPath,
                              selectedEmoji:     state.avatarEmoji,
                              onImagePathSelected: (path) => ref
                                  .read(profileSetupControllerProvider.notifier)
                                  .setAvatarPath(path),
                              onEmojiSelected: (emoji) => ref
                                  .read(profileSetupControllerProvider.notifier)
                                  .setAvatarEmoji(emoji ?? '👷'),
                            ),

                            if (state.status ==
                                ProfileSetupStatus.uploadingImage) ...[
                              const SizedBox(height: AppConstants.spacingMd),
                              LinearProgressIndicator(
                                value: state.uploadProgress,
                                backgroundColor: accent.withOpacity(0.20),
                                valueColor:      AlwaysStoppedAnimation(accent),
                              ),
                            ],

                            const SizedBox(height: AppConstants.spacingXl),

                            // ── Name field ─────────────────────────────────
                            AutofillGroup(
                              child: TextFormField(
                                controller:         _nameCtrl,
                                focusNode:          _nameFocus,
                                textCapitalization: TextCapitalization.words,
                                textInputAction:    TextInputAction.done,
                                autofillHints:      const [AutofillHints.name],
                                maxLength:          AppConstants.maxUsernameLength,
                                onChanged: (v) => ref
                                    .read(profileSetupControllerProvider.notifier)
                                    .setName(v),
                                decoration: InputDecoration(
                                  labelText:   context.tr('profile.full_name'),
                                  prefixIcon:  const Icon(AppIcons.person),
                                  counterText: '',
                                ),
                              ),
                            ),

                            const SizedBox(height: AppConstants.spacingXl),

                            // ── Profession section label ───────────────────
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    context.tr('register.service_label'),
                                    style: TextStyle(
                                      fontSize:   AppConstants.fontSizeCaption,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppTheme.darkSecondaryText
                                          : AppTheme.lightSecondaryText,
                                    ),
                                  ),
                                ),
                                if (state.profession != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppConstants.paddingSm,
                                      vertical:   2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(
                                        AppConstants.radiusCircle,
                                      ),
                                    ),
                                    child: Text(
                                      state.profession!,
                                      style: TextStyle(
                                        fontSize:   AppConstants.fontSizeSm,
                                        fontWeight: FontWeight.w600,
                                        color:      accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: AppConstants.spacingMd),

                            // ── Voice button ───────────────────────────────
                            VoiceProfessionButton(
                              onProfessionDetected: _onVoiceProfessionDetected,
                            ),

                            const SizedBox(height: AppConstants.spacingMd),

                            // ── Profession picker V2 ───────────────────────
                            ProfessionPickerV2(
                              key:             _pickerKey,
                              selectedKey:     state.profession,
                              showVoiceButton: false,
                              onSelected: (key) {
                                if (key != null) {
                                  ref
                                      .read(profileSetupControllerProvider
                                          .notifier)
                                      .setProfession(key);
                                } else {
                                  ref
                                      .read(profileSetupControllerProvider
                                          .notifier)
                                      .clearProfession();
                                }
                              },
                            ),

                            // ── Error ──────────────────────────────────────
                            if (state.hasError && state.errorKey != null) ...[
                              const SizedBox(height: AppConstants.spacingMd),
                              Text(
                                context.tr(state.errorKey!),
                                style: TextStyle(
                                  fontSize: AppConstants.fontSizeSm,
                                  color: isDark
                                      ? AppTheme.darkError
                                      : AppTheme.lightError,
                                ),
                              ),
                            ],

                            const SizedBox(height: AppConstants.spacingXl),

                            // ── CTA ────────────────────────────────────────
                            AuthSubmitButton(
                              isLoading: state.isLoading,
                              isDark:    isDark,
                              onPressed: (!state.isLoading &&
                                      state.canSubmitWorker)
                                  ? _submit
                                  : null,
                              labelKey: 'worker_profile.cta',
                            ),

                            const SizedBox(height: AppConstants.spacingMd),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
