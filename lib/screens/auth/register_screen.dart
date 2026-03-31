// lib/screens/auth/register_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/register_state.dart';
import '../../providers/register_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/logger.dart';
import '../../utils/snack_utils.dart';
import 'widgets/auth_background.dart';
import 'widgets/register_form_card.dart';
import 'widgets/register_header.dart';
import 'widgets/auth_switch_cta.dart';
import 'widgets/register_role_selector.dart';
import 'widgets/register_service_picker.dart';
import 'widgets/social_button_widgets.dart';
// FIX (Structure): _ProfessionPickerSheet extracted from this file to its own
// widget file. Import replaces the former private class definition below.
import 'widgets/profession_picker_sheet.dart';

// ============================================================================
// REGISTER SCREEN
// ============================================================================

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey                   = GlobalKey<FormState>();
  final _nameController            = TextEditingController();
  final _emailController           = TextEditingController();
  final _phoneController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus     = FocusNode();
  final _emailFocus    = FocusNode();
  final _phoneFocus    = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus  = FocusNode();

  String? _socialLoading;

  late final AnimationController _cardController;
  late final AnimationController _roleController;
  late final Animation<double>   _cardFade;
  late final Animation<Offset>   _cardSlide;
  late final Animation<double>   _roleScale;

  // FIX (Engineer P1): ref.listen moved to initState() via ref.listenManual.
  // See login_screen.dart for the full rationale.
  ProviderSubscription<RegisterState>? _registerStateSubscription;

  @override
  void initState() {
    super.initState();

    _cardController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    );
    _roleController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 400),
    );

    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
    _roleScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _roleController, curve: Curves.easeOut),
    );

    _cardController.forward();

    // Stable listener — registered once, torn down in dispose().
    _registerStateSubscription = ref.listenManual<RegisterState>(
      registerControllerProvider,
      (previous, next) {
        if (!mounted) return;
        if (next.isSuccess) {
          AppLogger.info('RegisterScreen: success, router will redirect');
        }
        if (next.hasError && next.errorMessage != null) {
          final msg = next.errorMessage!.contains('.')
              ? context.tr(next.errorMessage!)
              : next.errorMessage!;
          showAuthSnackBar(context, msg, isError: true);
        }
      },
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _registerStateSubscription?.close();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _cardController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------------

  void _onRoleChanged(bool isWorker) {
    ref.read(registerControllerProvider.notifier).setIsWorker(isWorker);
    _roleController.forward(from: 0);
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref.read(registerControllerProvider.notifier).signUp(
          fullName:        _nameController.text,
          email:           _emailController.text,
          password:        _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          phoneNumber:     _phoneController.text,
        );
  }

  Future<void> _onSocialTap(String provider) async {
    if (_socialLoading != null) return;
    final isWorker = ref.read(registerControllerProvider).isWorker;

    if (isWorker) {
      // FIX (Structure): _showProfessionPicker now uses ProfessionPickerSheet
      // (extracted widget) instead of the formerly-private _ProfessionPickerSheet.
      final selectedProfession = await _showProfessionPicker();
      if (selectedProfession == null || !mounted) return;

      setState(() => _socialLoading = provider);
      final errorKey = await ref
          .read(registerControllerProvider.notifier)
          .signInWithSocialAsWorker(
            provider:   provider,
            profession: selectedProfession,
          );
      if (!mounted) return;
      setState(() => _socialLoading = null);
      if (errorKey != null) {
        showAuthSnackBar(context, context.tr(errorKey), isError: true);
      }
    } else {
      setState(() => _socialLoading = provider);
      final errorKey = await ref
          .read(registerControllerProvider.notifier)
          .signInWithSocialAsClient(provider: provider);
      if (!mounted) return;
      setState(() => _socialLoading = null);
      if (errorKey != null) {
        showAuthSnackBar(context, context.tr(errorKey), isError: true);
      }
    }
  }

  Future<String?> _showProfessionPicker() => showModalBottomSheet<String>(
        context:            context,
        isScrollControlled: true,
        backgroundColor:    Colors.transparent,
        builder: (_) => ProfessionPickerSheet(
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      );

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(registerControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBusy = state.isLoading || _socialLoading != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor:                      Colors.transparent,
        statusBarIconBrightness:             isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:                 isDark ? Brightness.dark  : Brightness.light,
        systemNavigationBarColor:            Colors.transparent,
        systemNavigationBarDividerColor:     Colors.transparent,
        systemNavigationBarIconBrightness:   isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            AuthBackground(isDark: isDark),

            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.only(
                      left:   AppConstants.paddingLg,
                      right:  AppConstants.paddingLg,
                      top:    AppConstants.paddingMd,
                      bottom: MediaQuery.of(context).viewInsets.bottom +
                          AppConstants.paddingXl,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        RegisterHeader(isDark: isDark),

                        SizedBox(height: AppConstants.spacingLg),

                        RegisterRoleSelector(
                          isWorker:  state.isWorker,
                          isDark:    isDark,
                          onChanged: _onRoleChanged,
                        ),

                        SizedBox(height: AppConstants.spacingLg),

                        FadeTransition(
                          opacity: _cardFade,
                          child: SlideTransition(
                            position: _cardSlide,
                            child: RegisterFormCard(
                              formKey:           _formKey,
                              nameController:    _nameController,
                              emailController:   _emailController,
                              phoneController:   _phoneController,
                              passwordController: _passwordController,
                              confirmController: _confirmPasswordController,
                              nameFocus:         _nameFocus,
                              emailFocus:        _emailFocus,
                              phoneFocus:        _phoneFocus,
                              passwordFocus:     _passwordFocus,
                              confirmFocus:      _confirmFocus,
                              state:             state,
                              roleScale:         _roleScale,
                              onSubmit:          _onSubmit,
                              onFieldChanged: () => ref
                                  .read(registerControllerProvider.notifier)
                                  .onFieldChanged(),
                              onServiceSelected: (s) => ref
                                  .read(registerControllerProvider.notifier)
                                  .selectService(s),
                              onTermsChanged: (v) => ref
                                  .read(registerControllerProvider.notifier)
                                  .setTermsAccepted(v),
                            ),
                          ),
                        ),

                        SizedBox(height: AppConstants.spacingXl),

                        SocialDivider(isDark: isDark),

                        SizedBox(height: AppConstants.spacingLg),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularSocialButton(
                              isDark:        isDark,
                              semanticLabel: context.tr('social.google'),
                              isLoading:     _socialLoading == 'google',
                              isDisabled:    isBusy,
                              logo:          const GoogleLogo(),
                              onPressed: isBusy
                                  ? null
                                  : () => _onSocialTap('google'),
                            ),
                            SizedBox(width: AppConstants.spacingLg),
                            CircularSocialButton(
                              isDark:        isDark,
                              semanticLabel: context.tr('social.facebook'),
                              isLoading:     _socialLoading == 'facebook',
                              isDisabled:    isBusy,
                              logo:          const FacebookLogo(),
                              onPressed: isBusy
                                  ? null
                                  : () => _onSocialTap('facebook'),
                            ),
                            if (Platform.isIOS) ...[
                              SizedBox(width: AppConstants.spacingLg),
                              CircularSocialButton(
                                isDark:        isDark,
                                semanticLabel: context.tr('social.apple'),
                                isLoading:     _socialLoading == 'apple',
                                isDisabled:    isBusy,
                                logo:          AppleLogo(isDark: isDark),
                                onPressed: isBusy
                                    ? null
                                    : () => _onSocialTap('apple'),
                              ),
                            ],
                          ],
                        ),

                        SizedBox(height: AppConstants.spacingXl),

                        AuthSwitchCta(
                          promptKey: 'register.have_account',
                          linkKey:   'register.login_link',
                          route:     AppRoutes.login,
                          isDark:    isDark,
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
