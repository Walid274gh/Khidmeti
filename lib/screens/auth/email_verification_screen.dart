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
import 'widgets/auth_submit_button.dart';

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

  Timer? _pollingTimer;
  static const Duration _pollInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();

    _cardController = AnimationController(
      vsync: this,
      duration: AppConstants.authCardEntranceDuration,
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

  Future<void> _pollVerification() async {
    if (_checkingVerification || _signingOut || !mounted) return;
    final authService = ref.read(authServiceProvider);
    final isVerified  = await authService.reloadAndCheckEmailVerification();
    if (isVerified && mounted) {
      AppLogger.info(
          'EmailVerificationScreen: auto-poll detected verification → redirecting');
      ref.read(authRedirectNotifierProvider).notifyAuthReady();
    }
  }

  Future<void> _onCheckVerification() async {
    if (_checkingVerification) return;
    setState(() => _checkingVerification = true);

    final authService = ref.read(authServiceProvider);
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

  Future<void> _onChangeAccount() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    await ref.read(authServiceProvider).signOut();
    if (mounted) setState(() => _signingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
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
          Container(
            width:  AppConstants.iconContainerFeature,
            height: AppConstants.iconContainerFeature,
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

          // FIX [BTN-SPLIT]: ElevatedButton primary CTA → AuthSubmitButton
          AuthSubmitButton(
            isLoading: checkingVerification,
            isDark:    isDark,
            onPressed: isAnyBusy ? null : onCheckVerification,
            labelKey:  'verify_email.i_verified',
          ),

          SizedBox(height: AppConstants.spacingMd),

          // FIX [A11Y-DUP]: removed redundant Semantics(button: true, label:)
          // wrapper — TextButton with visible text child already exposes correct
          // semantics. Double-labelling harms screen readers.
          TextButton(
            onPressed: isAnyBusy ? null : onResend,
            child: resending
                ? SizedBox(
                    width:  AppConstants.spinnerSizeSm,
                    height: AppConstants.spinnerSizeSm,
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
                        const SizedBox(width: AppConstants.spacingXs),
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size:  AppConstants.iconSizeXs,
                          color: isDark
                              ? AppTheme.darkSuccess
                              : AppTheme.lightSuccess,
                        ),
                      ],
                    ],
                  ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: AppConstants.spacingMd),
            child: Divider(
              color: isDark
                  ? AppTheme.darkBorder
                  : AppTheme.lightBorder,
              height: 1,
            ),
          ),

          // FIX [A11Y-DUP]: removed redundant Semantics(button: true, label:)
          // wrapper — TextButton.icon with visible text child already exposes
          // correct semantics. Double-labelling harms screen readers.
          TextButton.icon(
            onPressed: isAnyBusy ? null : onChangeAccount,
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, AppConstants.buttonHeightSm),
              foregroundColor: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
            icon: signingOut
                ? SizedBox(
                    width:  AppConstants.spinnerSizeSm,
                    height: AppConstants.spinnerSizeSm,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                  )
                : const Icon(Icons.logout_rounded, size: AppConstants.iconSizeXs),
            label: Text(
              context.tr('verify_email.change_account'),
              style: const TextStyle(
                  fontSize: AppConstants.fontSizeCaption),
            ),
          ),

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
