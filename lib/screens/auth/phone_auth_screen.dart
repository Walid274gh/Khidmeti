// lib/screens/auth/phone_auth_screen.dart
//
// Firebase Phone Authentication — three animated states:
//   State 0 — Phone entry  : country code picker + 9-digit input
//   State 1 — OTP entry    : 6-box grid, resend timer, auto-submit
//   State 2 — Success/loading: animated checkmark while router redirects
//
// State machine is driven by authControllerProvider (AuthController).
//
// NAVIGATION FIXES:
//   • ref.listen handles navigation on AuthStatus.success:
//       - isNewUser  → context.go(AppRoutes.roleSelection)
//       - existing   → fetch role via currentUserRoleProvider,
//                      set cachedUserRoleProvider, then navigate to /home.
//   • isOtpPhase now includes AuthStatus.success so the OTP card stays
//     visible (instead of the phone card flashing) while navigation occurs.
//   • Verify button now calls onCompleted with the real OTP code as fallback.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/auth_state.dart';
import '../../providers/auth_controller.dart';
import '../../providers/user_role_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/form_validators.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../auth/widgets/auth_background.dart';
import '../auth/widgets/auth_submit_button.dart';
import 'widgets/country_code_picker.dart';
import 'widgets/otp_input_row.dart';

// ─────────────────────────────────────────────────────────────────────────────

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen>
    with TickerProviderStateMixin {

  // ── Phone state ─────────────────────────────────────────────────────────────
  final _phoneController = TextEditingController();
  CountryCode _selectedCountry = kDefaultCountry;
  bool _phoneValid = false;

  // ── OTP state ───────────────────────────────────────────────────────────────
  final _otpKey  = GlobalKey<OtpInputRowState>();
  bool   _otpSubmitting = false;

  // ── Animations ──────────────────────────────────────────────────────────────
  late final AnimationController _cardController;
  late final Animation<double>    _cardFade;
  late final Animation<Offset>    _cardSlide;

  @override
  void initState() {
    super.initState();

    _phoneController.addListener(() {
      final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      final valid  = digits.length == 9;
      if (valid != _phoneValid) setState(() => _phoneValid = valid);
    });

    _cardController = AnimationController(
      vsync:    this,
      duration: AppConstants.authCardEntranceDuration,
    )..forward();

    _cardFade  = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  // ── Navigation after successful authentication ────────────────────────────
  //
  // FIX: The router redirect waits for cachedUserRoleProvider != unknown,
  // but nobody sets that provider after phone auth. We handle navigation
  // here instead, for both new users and returning users.

  /// Called by ref.listen when AuthStatus.success is reached for an
  /// existing user (isNewUser == false). Fetches the user's role from the
  /// API, writes it into cachedUserRoleProvider so MainNavigationScreen
  /// displays the correct tab bar, then navigates to /home.
  Future<void> _handleExistingUserLogin() async {
    try {
      final role = await ref.read(currentUserRoleProvider.future);
      if (!mounted) return;
      setCachedUserRole(ref, role, force: true);
    } catch (_) {
      // Degrade gracefully: treat as client if the API is unreachable.
      if (!mounted) return;
      setCachedUserRole(ref, UserRole.client, force: true);
    }
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  // ── Phone submission ────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (!_phoneValid) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    final raw  = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final e164 = '${_selectedCountry.dialCode}$raw';
    await ref.read(authControllerProvider.notifier).sendOtp(e164);

    // Replay card entrance animation for OTP state.
    if (mounted) {
      _cardController.reset();
      _cardController.forward();
    }
  }

  // ── OTP submission ──────────────────────────────────────────────────────────

  Future<void> _verifyOtp(String code) async {
    if (code.length != 6 || _otpSubmitting) return;
    HapticFeedback.mediumImpact();
    setState(() => _otpSubmitting = true);
    await ref.read(authControllerProvider.notifier).verifyOtp(code);
    if (mounted) setState(() => _otpSubmitting = false);
  }

  Future<void> _resendOtp() async {
    _otpKey.currentState?.clear();
    await ref.read(authControllerProvider.notifier).resendOtp();
    if (mounted) {
      _cardController.reset();
      _cardController.forward();
    }
  }

  // ── Back to phone ───────────────────────────────────────────────────────────

  void _backToPhone() {
    ref.invalidate(authControllerProvider);
    _phoneController.clear();
    _otpKey.currentState?.clear();
    _cardController.reset();
    _cardController.forward();
  }

  // ── Country picker ──────────────────────────────────────────────────────────

  Future<void> _pickCountry() async {
    FocusScope.of(context).unfocus();
    final result = await showCountryCodePicker(context);
    if (result != null && mounted) {
      setState(() => _selectedCountry = result);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    // ── Navigation listener ──────────────────────────────────────────────────
    // FIX: Navigate as soon as the controller reaches success.
    // This is the correct place for navigation since the router's redirect
    // function waits for cachedUserRoleProvider to be resolved, which only
    // happens here for freshly-authenticated users.
    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (!mounted) return;
      if (next.status != AuthStatus.success) return;

      if (next.isNewUser) {
        // New user has no profile yet — send to role selection.
        context.go(AppRoutes.roleSelection);
      } else {
        // Existing user — resolve role then go home.
        _handleExistingUserLogin();
      }
    });

    // FIX: Include AuthStatus.success so the OTP card stays visible while
    // the navigation animation plays. Without this, the phone card briefly
    // appears after successful verification (status changes to success which
    // is not otpSent/verifying → isOtpPhase was false → phone card shown).
    final isOtpPhase = authState.status == AuthStatus.otpSent    ||
                       authState.status == AuthStatus.verifying   ||
                       authState.status == AuthStatus.success;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: Stack(
          children: [
            AuthBackground(isDark: isDark),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left:   AppConstants.paddingLg,
                  right:  AppConstants.paddingLg,
                  top:    AppConstants.paddingXl,
                  bottom: MediaQuery.of(context).viewInsets.bottom + AppConstants.paddingXl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo / wordmark
                    _AuthHeader(isDark: isDark),

                    const SizedBox(height: AppConstants.spacingXl),

                    // Card — switches between phone and OTP
                    FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: AnimatedSwitcher(
                          duration:        const Duration(milliseconds: 320),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child:   child,
                          ),
                          child: isOtpPhase
                              ? _OtpCard(
                                  key:          const ValueKey('otp'),
                                  authState:    authState,
                                  isDark:       isDark,
                                  otpKey:       _otpKey,
                                  onCompleted:  _verifyOtp,
                                  onResend:     _resendOtp,
                                  onBack:       _backToPhone,
                                )
                              : _PhoneCard(
                                  key:          const ValueKey('phone'),
                                  authState:    authState,
                                  isDark:       isDark,
                                  controller:   _phoneController,
                                  country:      _selectedCountry,
                                  phoneValid:   _phoneValid,
                                  onPickCountry: _pickCountry,
                                  onSubmit:     _sendOtp,
                                ),
                        ),
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Auth header
// ─────────────────────────────────────────────────────────────────────────────

class _AuthHeader extends StatelessWidget {
  final bool isDark;
  const _AuthHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo orb
        Container(
          width:  AppConstants.logoOrbSize,
          height: AppConstants.logoOrbSize,
          decoration: BoxDecoration(
            shape:  BoxShape.circle,
            color:  accent,
            boxShadow: [
              BoxShadow(
                color:      AppTheme.accentShadow,
                blurRadius: 40,
                offset:     const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            AppIcons.home,
            color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            size:  AppConstants.logoOrbIconSize,
          ),
        ),

        const SizedBox(height: AppConstants.spacingLg),

        Semantics(
          header: true,
          child: Text(
            'Khidmeti',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight:    FontWeight.w700,
              letterSpacing: -0.5,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone entry card
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneCard extends StatelessWidget {
  final AuthState             authState;
  final bool                  isDark;
  final TextEditingController controller;
  final CountryCode           country;
  final bool                  phoneValid;
  final VoidCallback          onPickCountry;
  final VoidCallback          onSubmit;

  const _PhoneCard({
    super.key,
    required this.authState,
    required this.isDark,
    required this.controller,
    required this.country,
    required this.phoneValid,
    required this.onPickCountry,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return _AuthCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            context.tr('phone_auth.title'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),

          const SizedBox(height: AppConstants.spacingXs),

          Text(
            context.tr('phone_auth.subtitle'),
            style: TextStyle(
              fontSize: AppConstants.fontSizeSm,
              color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
            ),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // Phone input row: [flag+dial] [number]
          _PhoneInputRow(
            isDark:        isDark,
            controller:    controller,
            country:       country,
            onPickCountry: onPickCountry,
            onSubmit:      onSubmit,
          ),

          // Error
          if (authState.hasError && authState.errorKey != null) ...[
            const SizedBox(height: AppConstants.spacingSm),
            _ErrorBanner(
              messageKey: authState.errorKey!,
              isDark:     isDark,
            ),
          ],

          const SizedBox(height: AppConstants.spacingLg),

          // CTA
          AuthSubmitButton(
            isLoading: authState.status == AuthStatus.sendingOtp,
            isDark:    isDark,
            onPressed: phoneValid && authState.status != AuthStatus.sendingOtp
                ? onSubmit
                : null,
            labelKey:  'phone_auth.send_code',
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // SMS cost disclaimer
          Text(
            context.tr('phone_auth.sms_disclaimer'),
            style: TextStyle(
              fontSize: AppConstants.fontSizeSm,
              color: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone input row
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneInputRow extends StatefulWidget {
  final bool                  isDark;
  final TextEditingController controller;
  final CountryCode           country;
  final VoidCallback          onPickCountry;
  final VoidCallback          onSubmit;

  const _PhoneInputRow({
    required this.isDark,
    required this.controller,
    required this.country,
    required this.onPickCountry,
    required this.onSubmit,
  });

  @override
  State<_PhoneInputRow> createState() => _PhoneInputRowState();
}

class _PhoneInputRowState extends State<_PhoneInputRow> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return AnimatedContainer(
      duration: AppConstants.animDurationMicro,
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppTheme.darkSurfaceVariant
            : AppTheme.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.inputRadius),
        border: Border.all(
          color: _isFocused ? accent : (widget.isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          width: _isFocused ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          // Country code button
          Semantics(
            button: true,
            label: 'Country code, current: ${widget.country.name} ${widget.country.dialCode}',
            child: GestureDetector(
              onTap: widget.onPickCountry,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMd,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: widget.isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      widget.country.flag,
                      style: const TextStyle(fontSize: AppConstants.iconSizeSm),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.country.dialCode,
                      style: TextStyle(
                        fontSize:   AppConstants.fontSizeMd,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size:  16,
                      color: widget.isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Phone number input
          Expanded(
            child: TextField(
              controller:       widget.controller,
              focusNode:        _focusNode,
              keyboardType:     TextInputType.phone,
              textInputAction:  TextInputAction.done,
              autofillHints:    const [AutofillHints.telephoneNumberNational],
              maxLength:        9,
              onSubmitted:      (_) => widget.onSubmit(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: TextStyle(
                fontSize:   AppConstants.fontSizeLg,
                fontWeight: FontWeight.w400,
                color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
              decoration: InputDecoration(
                border:         InputBorder.none,
                hintText:       '6XXXXXXXX',
                hintStyle: TextStyle(
                  color:    widget.isDark ? AppTheme.darkHintText : AppTheme.lightHintText,
                  fontSize: AppConstants.fontSizeLg,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMd,
                  vertical:   AppConstants.paddingMd,
                ),
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OTP card
// ─────────────────────────────────────────────────────────────────────────────

class _OtpCard extends StatefulWidget {
  final AuthState                   authState;
  final bool                        isDark;
  final GlobalKey<OtpInputRowState> otpKey;
  final ValueChanged<String>        onCompleted;
  final VoidCallback                onResend;
  final VoidCallback                onBack;

  const _OtpCard({
    super.key,
    required this.authState,
    required this.isDark,
    required this.otpKey,
    required this.onCompleted,
    required this.onResend,
    required this.onBack,
  });

  @override
  State<_OtpCard> createState() => _OtpCardState();
}

class _OtpCardState extends State<_OtpCard> {
  @override
  Widget build(BuildContext context) {
    // Show spinner when verifying OR when success (navigation in progress).
    final isVerifyingOrDone = widget.authState.status == AuthStatus.verifying ||
                              widget.authState.status == AuthStatus.success;
    final cooldown = widget.authState.resendCooldown;
    final phone    = widget.authState.phone;
    final masked   = phone.length >= 4
        ? '${phone.substring(0, phone.length - 4)}****'
        : phone;

    return _AuthCard(
      isDark: widget.isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back link — hidden while verifying/success so user can't go back
          // mid-flight.
          if (!isVerifyingOrDone)
            Semantics(
              button: true,
              label:  'Retour à la saisie du numéro',
              child: GestureDetector(
                onTap: widget.onBack,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size:  AppConstants.iconSizeSm,
                      color: widget.isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('phone_auth.change_number'),
                      style: TextStyle(
                        fontSize:   AppConstants.fontSizeSm,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (!isVerifyingOrDone)
            const SizedBox(height: AppConstants.spacingMd),

          // Title
          Text(
            context.tr('phone_auth.otp_title'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),

          const SizedBox(height: AppConstants.spacingXs),

          Text(
            '${context.tr("phone_auth.otp_sent_to")} $masked',
            style: TextStyle(
              fontSize: AppConstants.fontSizeSm,
              color: widget.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
            ),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // OTP boxes
          OtpInputRow(
            key:         widget.otpKey,
            hasError:    widget.authState.hasError,
            onCompleted: widget.onCompleted,
            onChanged:   () {},
          ),

          // Error
          if (widget.authState.hasError && widget.authState.errorKey != null) ...[
            const SizedBox(height: AppConstants.spacingSm),
            _ErrorBanner(
              messageKey: widget.authState.errorKey!,
              isDark:     widget.isDark,
            ),
          ],

          const SizedBox(height: AppConstants.spacingLg),

          // FIX: Verify button now actually submits the OTP.
          // It reads the current code from OtpInputRowState.currentCode
          // (public getter added in otp_input_row.dart) and calls onCompleted.
          // This acts as a reliable fallback if auto-submit didn't fire.
          AuthSubmitButton(
            isLoading: isVerifyingOrDone,
            isDark:    widget.isDark,
            onPressed: isVerifyingOrDone ? null : () {
              final code = widget.otpKey.currentState?.currentCode ?? '';
              if (code.length == 6) {
                widget.onCompleted(code);
              }
            },
            labelKey:  'phone_auth.verify',
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // Resend timer — hidden while verifying/success
          if (!isVerifyingOrDone)
            _ResendTimer(
              cooldown: cooldown,
              isDark:   widget.isDark,
              onResend: cooldown == 0 ? widget.onResend : null,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Resend timer
// ─────────────────────────────────────────────────────────────────────────────

class _ResendTimer extends StatelessWidget {
  final int           cooldown;
  final bool          isDark;
  final VoidCallback? onResend;

  const _ResendTimer({
    required this.cooldown,
    required this.isDark,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.tr('phone_auth.resend_prefix'),
          style: TextStyle(
            fontSize: AppConstants.fontSizeSm,
            color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
          ),
        ),
        const SizedBox(width: 4),
        if (cooldown > 0)
          Text(
            '${cooldown}s',
            style: TextStyle(
              fontSize:   AppConstants.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
            ),
          )
        else
          Semantics(
            button: true,
            label: context.tr('phone_auth.resend'),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onResend?.call();
              },
              child: Text(
                context.tr('phone_auth.resend'),
                style: TextStyle(
                  fontSize:   AppConstants.fontSizeSm,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error banner
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String messageKey;
  final bool   isDark;

  const _ErrorBanner({required this.messageKey, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkError : AppTheme.lightError).withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(
          color: (isDark ? AppTheme.darkError : AppTheme.lightError).withOpacity(0.30),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size:  AppConstants.iconSizeXs,
            color: isDark ? AppTheme.darkError : AppTheme.lightError,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              context.tr(messageKey),
              style: TextStyle(
                fontSize: AppConstants.fontSizeSm,
                color: isDark ? AppTheme.darkError : AppTheme.lightError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth card container
// ─────────────────────────────────────────────────────────────────────────────

class _AuthCard extends StatelessWidget {
  final bool   isDark;
  final Widget child;

  const _AuthCard({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
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
      child: child,
    );
  }
}
