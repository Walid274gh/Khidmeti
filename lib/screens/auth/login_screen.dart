// lib/screens/auth/login_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/login_state.dart';
import '../../providers/login_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/logger.dart';
import '../../utils/snack_utils.dart';
import '../../utils/system_ui_overlay.dart';
import 'widgets/auth_background.dart';
import 'widgets/login_forgot_password_sheet.dart';
import 'widgets/login_form_card.dart';
import 'widgets/login_header.dart';
import 'widgets/auth_switch_cta.dart';
import 'widgets/social_button_widgets.dart';

// ============================================================================
// LOGIN SCREEN
// ============================================================================

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey              = GlobalKey<FormState>();
  final _emailController      = TextEditingController();
  final _passwordController   = TextEditingController();
  final _resetEmailController = TextEditingController();
  final _resetFormKey         = GlobalKey<FormState>();
  final _emailFocus           = FocusNode();
  final _passwordFocus        = FocusNode();

  String? _loadingProvider;
  bool    _isForgotSheetOpen = false;

  late final AnimationController _cardController;
  late final Animation<double>   _cardFade;
  late final Animation<Offset>   _cardSlide;

  ProviderSubscription<LoginState>? _loginStateSubscription;

  @override
  void initState() {
    super.initState();

    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);

    _cardController = AnimationController(
      vsync: this,
      // FIX [Anim-DUR]: was Duration(milliseconds: 900) raw literal —
      // replaced with AppConstants.authCardEntranceDuration token.
      duration: AppConstants.authCardEntranceDuration,
    );
    _cardFade = CurvedAnimation(
        parent: _cardController, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _cardController.forward();

    _loginStateSubscription = ref.listenManual<LoginState>(
      loginControllerProvider,
      (previous, next) {
        if (!mounted) return;

        if (next.isSuccess) {
          AppLogger.info('LoginScreen: sign-in success, router will redirect');
          return;
        }

        if (next.hasError) {
          if (_loadingProvider != null) {
            setState(() => _loadingProvider = null);
          }
        }
      },
      fireImmediately: false,
    );
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _loginStateSubscription?.close();
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _cardController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Email/Password actions
  // --------------------------------------------------------------------------

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(loginControllerProvider.notifier).signIn(
          email:    _emailController.text,
          password: _passwordController.text,
        );
  }

  void _onForgotPassword() {
    if (_isForgotSheetOpen) return;
    _isForgotSheetOpen = true;

    _resetEmailController.text = _emailController.text.trim();
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (ctx) => LoginForgotPasswordSheet(
        emailController: _resetEmailController,
        formKey:         _resetFormKey,
        onSend: (email) async {
          await ref
              .read(loginControllerProvider.notifier)
              .resetPassword(email);
          if (mounted && ctx.mounted) {
            Navigator.of(ctx).pop();
            showAuthSnackBar(context, context.tr('login.reset_email_sent'));
          }
        },
      ),
    ).whenComplete(() {
      _isForgotSheetOpen = false;
    });
  }

  // --------------------------------------------------------------------------
  // Social sign-in
  // --------------------------------------------------------------------------

  Future<void> _onSocialSignIn(
    String          provider,
    Future<void> Function() action,
  ) async {
    if (_loadingProvider != null) return;
    setState(() => _loadingProvider = provider);
    await action();
    if (mounted) setState(() => _loadingProvider = null);
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(loginControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBusy = state.isLoading || _loadingProvider != null;

    final bool canSubmit = !isBusy &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            AuthBackground(isDark: isDark),

            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left:   AppConstants.paddingLg,
                  right:  AppConstants.paddingLg,
                  top:    AppConstants.paddingXl,
                  bottom: MediaQuery.of(context).viewInsets.bottom +
                      AppConstants.paddingXl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LoginHeader(isDark: isDark),

                    SizedBox(height: AppConstants.spacingXl),

                    FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: LoginFormCard(
                          formKey:            _formKey,
                          emailController:    _emailController,
                          passwordController: _passwordController,
                          emailFocus:         _emailFocus,
                          passwordFocus:      _passwordFocus,
                          state:              state,
                          onSubmit:           canSubmit ? _onSubmit : null,
                          onForgotPassword:   _onForgotPassword,
                          onEmailChanged: (v) => ref
                              .read(loginControllerProvider.notifier)
                              .onEmailChanged(v),
                        ),
                      ),
                    ),

                    SizedBox(height: AppConstants.spacingLg),

                    SocialDivider(isDark: isDark),

                    SizedBox(height: AppConstants.spacingLg),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularSocialButton(
                          isDark:        isDark,
                          semanticLabel: context.tr('social.google'),
                          isLoading:     _loadingProvider == 'google',
                          isDisabled:    isBusy,
                          logo:          const GoogleLogo(),
                          onPressed: isBusy
                              ? null
                              : () => _onSocialSignIn(
                                    'google',
                                    () => ref
                                        .read(loginControllerProvider.notifier)
                                        .signInWithGoogle(),
                                  ),
                        ),

                        SizedBox(width: AppConstants.spacingLg),

                        CircularSocialButton(
                          isDark:        isDark,
                          semanticLabel: context.tr('social.facebook'),
                          isLoading:     _loadingProvider == 'facebook',
                          isDisabled:    isBusy,
                          logo:          const FacebookLogo(),
                          onPressed: isBusy
                              ? null
                              : () => _onSocialSignIn(
                                    'facebook',
                                    () => ref
                                        .read(loginControllerProvider.notifier)
                                        .signInWithFacebook(),
                                  ),
                        ),

                        if (Platform.isIOS) ...[
                          SizedBox(width: AppConstants.spacingLg),
                          CircularSocialButton(
                            isDark:        isDark,
                            semanticLabel: context.tr('social.apple'),
                            isLoading:     _loadingProvider == 'apple',
                            isDisabled:    isBusy,
                            logo:          AppleLogo(isDark: isDark),
                            onPressed: isBusy
                                ? null
                                : () => _onSocialSignIn(
                                      'apple',
                                      () => ref
                                          .read(loginControllerProvider.notifier)
                                          .signInWithApple(),
                                    ),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: AppConstants.spacingXl),

                    AuthSwitchCta(
                      promptKey: 'login.no_account',
                      linkKey:   'login.register_link',
                      route:     AppRoutes.register,
                      isDark:    isDark,
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
