// lib/screens/auth/email_verification_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/core_providers.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/logger.dart';
import '../../utils/snack_utils.dart';
import '../../utils/system_ui_overlay.dart';
import 'widgets/auth_background.dart';

// ============================================================================
// EMAIL VERIFICATION SCREEN
// ============================================================================

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with TickerProviderStateMixin {
  bool _checkingVerification = false;
  bool _resending            = false;
  bool _resentSuccess        = false;
  bool _signingOut           = false;

  late final AnimationController _cardController;
  late final Animation<double>   _cardFade;

  // FIX (Cross-Screen Flow P1): automatic 30-second polling.
  // If the user verifies on another device or from the email link, the app
  // auto-redirects without requiring a manual tap.
  Timer? _pollingTimer;
  static const Duration _pollInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();

    _cardController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);

    _pollingTimer = Timer.periodic(_pollInterval, (_) => _pollVerification());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _cardController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Auto-poll — silent, triggers router redirect on success
  // --------------------------------------------------------------------------

  Future<void> _pollVerification() async {
    if (_checkingVerification || _signingOut || !mounted) return;
    final authService = ref.read(authServiceProvider);
    // Background poll uses the default forceReload: false — respects the
    // 3-second cooldown so we never hammer Firebase on high-frequency polling.
    final isVerified  = await authService.reloadAndCheckEmailVerification();
    if (isVerified && mounted) {
      AppLogger.info(
          'EmailVerificationScreen: auto-poll detected verification → redirecting');
      ref.read(authRedirectNotifierProvider).notifyAuthReady();
    }
  }

  // --------------------------------------------------------------------------
  // Manual check
  // --------------------------------------------------------------------------

  Future<void> _onCheckVerification() async {
    if (_checkingVerification) return;
    setState(() => _checkingVerification = true);

    final authService = ref.read(authServiceProvider);

    // FIX [A12]: pass forceReload: true so the 3-second cooldown is bypassed.
    // Without this, tapping "I Verified" within 3 seconds of the automatic
    // poll would skip the Firebase reload entirely and return the cached
    // (stale, unverified) result — making the button appear broken even when
    // the user has already clicked the verification link in their email.
    final isVerified  = await authService.reloadAndCheckEmailVerification(
      forceReload: true,
    );

    if (!mounted) return;
    setState(() => _checkingVerification = false);

    if (isVerified) {
      AppLogger.info('EmailVerificationScreen: verified, notifying router');
      ref.read(authRedirectNotifierProvider).notifyAuthReady();
    } else {
      showAuthSnackBar(
        context,
        context.tr('verify_email.not_verified_yet'),
        isError: true,
      );
    }
  }

  // --------------------------------------------------------------------------
  // Resend
  // --------------------------------------------------------------------------

  Future<void> _onResend() async {
    if (_resending) return;
    setState(() {
      _resending     = true;
      _resentSuccess = false;
    });
    final authService = ref.read(authServiceProvider);
    final errorKey    = await authService.resendVerificationEmail();
    if (!mounted) return;
    setState(() => _resending = false);
    if (errorKey == null) {
      setState(() => _resentSuccess = true);
      showAuthSnackBar(context, context.tr('verify_email.resent_success'));
    } else {
      showAuthSnackBar(context, context.tr(errorKey), isError: true);
    }
  }

  // --------------------------------------------------------------------------
  // Change account
  // --------------------------------------------------------------------------

  Future<void> _onChangeAccount() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    await ref.read(authServiceProvider).signOut();
    if (mounted) setState(() => _signingOut = false);
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    // FIX (Engineer P1): was ref.watch(authServiceProvider) — rebuilt on every
    // isLoading fluctuation. currentUserProvider rebuilds only when User changes.
    final user      = ref.watch(currentUserProvider);
    final userEmail = user?.email ?? '';
    final isAnyBusy = _checkingVerification || _resending || _signingOut;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: Stack(
          children: [
            AuthBackground(isDark: isDark),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 2),
                    FadeTransition(
                      opacity: _cardFade,
                      child: _VerificationCard(
                        isDark:               isDark,
                        userEmail:            userEmail,
                        checkingVerification: _checkingVerification,
                        resending:            _resending,
                        resentSuccess:        _resentSuccess,
                        signingOut:           _signingOut,
                        isAnyBusy:            isAnyBusy,
                        onCheckVerification:  _onCheckVerification,
                        onResend:             _onResend,
                        onChangeAccount:      _onChangeAccount,
                      ),
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// VERIFICATION CARD
// ============================================================================

class _VerificationCard extends StatelessWidget {
  final bool         isDark;
  final String       userEmail;
  final bool         checkingVerification;
  final bool         resending;
  final bool         resentSuccess;
  final bool         signingOut;
  final bool         isAnyBusy;
  final VoidCallback onCheckVerification;
  final VoidCallback onResend;
  final VoidCallback onChangeAccount;

  const _VerificationCard({
    required this.isDark,
    required this.userEmail,
    required this.checkingVerification,
    required this.resending,
    required this.resentSuccess,
    required this.signingOut,
    required this.isAnyBusy,
    required this.onCheckVerification,
    required this.onResend,
    required this.onChangeAccount,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingXl),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width:  56,
            height: 56,
            decoration: BoxDecoration(
              color:  accent.withOpacity(0.12),
              shape:  BoxShape.circle,
              border: Border.all(
                color: accent.withOpacity(0.25), width: 0.5),
            ),
            child: Icon(Icons.mark_email_unread_outlined,
                color: accent, size: 26),
          ),

          SizedBox(height: AppConstants.spacingMd),

          Semantics(
            header: true,
            child: Text(
              context.tr('verify_email.title'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: AppConstants.spacingXs),

          // FIX: using 'verify_email.description' — the existing key in all
          // 3 locales. Previously used 'verify_email.subtitle' which doesn't
          // exist and would have rendered as the raw key string.
          Text(
            context.tr('verify_email.description'),
            style: TextStyle(
              fontSize: AppConstants.fontSizeSm,
              color: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppConstants.spacingXs),

          Text(
            userEmail,
            style: TextStyle(
              fontSize:   AppConstants.fontSizeMd,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppConstants.spacingMd),

          // Primary CTA
          SizedBox(
            height: AppConstants.buttonHeight,
            child: ElevatedButton(
              onPressed: isAnyBusy ? null : onCheckVerification,
              child: checkingVerification
                  ? SizedBox(
                      width:  20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark
                            ? AppTheme.darkBackground
                            : AppTheme.lightBackground,
                      ),
                    )
                  // FIX: using 'verify_email.i_verified' — the existing key.
                  : Text(context.tr('verify_email.i_verified')),
            ),
          ),

          SizedBox(height: AppConstants.spacingMd),

          // Resend
          Semantics(
            button: true,
            label:  context.tr('verify_email.resend'),
            child: TextButton(
              onPressed: isAnyBusy ? null : onResend,
              child: resending
                  ? SizedBox(
                      width:  14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: accent),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr('verify_email.resend'),
                          style: TextStyle(
                            color:      accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (resentSuccess) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size:  16,
                            color: isDark
                                ? AppTheme.darkSuccess
                                : AppTheme.lightSuccess,
                          ),
                        ],
                      ],
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: AppConstants.spacingMd),
            child: Divider(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : AppTheme.lightBorder,
              height: 1,
            ),
          ),

          // Change account
          Semantics(
            button: true,
            label:  context.tr('verify_email.change_account'),
            child: TextButton.icon(
              onPressed: isAnyBusy ? null : onChangeAccount,
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                foregroundColor: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
              icon: signingOut
                  ? SizedBox(
                      width:  14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                    )
                  : const Icon(Icons.logout_rounded, size: 16),
              label: Text(
                context.tr('verify_email.change_account'),
                // FIX (Designer): was const TextStyle(fontSize: 13) — tokenised.
                style: const TextStyle(
                    fontSize: AppConstants.fontSizeCaption),
              ),
            ),
          ),

          // FIX (Designer): was const TextStyle(fontSize: 11) — tokenised.
          Text(
            context.tr('verify_email.change_account_hint'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppConstants.fontSizeXxs,
              color: isDark
                  ? AppTheme.darkSecondaryText.withOpacity(0.6)
                  : AppTheme.lightSecondaryText.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
