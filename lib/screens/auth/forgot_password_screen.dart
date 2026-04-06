// lib/screens/auth/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/core_providers.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/snack_utils.dart';
import '../../utils/system_ui_overlay.dart';
import '../../utils/validation_form.dart';
import 'widgets/auth_submit_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool    _isLoading    = false;
  bool    _emailSent    = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);
    final error = await authService.resetPassword(
      FormValidators.sanitizeEmail(_emailController.text),
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isLoading    = false;
        _errorMessage = context.tr(error);
      });
    } else {
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final textColor    = isDark ? AppTheme.darkText         : AppTheme.lightText;
    final subtextColor = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;
    final accent       = isDark ? AppTheme.darkAccent       : AppTheme.lightAccent;

    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation:       0,
          leading: IconButton(
            icon: Icon(isRTL
                ? Icons.arrow_forward_rounded
                : Icons.arrow_back_rounded),
            tooltip:  context.tr('common.back'),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.login),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLg,
              vertical:   AppConstants.spacingMd,
            ),
            child: _emailSent
                ? _SuccessState(
                    email:        _emailController.text.trim(),
                    isDark:       isDark,
                    accent:       accent,
                    subtextColor: subtextColor,
                    onBack: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.login),
                  )
                : _FormState(
                    formKey:         _formKey,
                    emailController: _emailController,
                    isLoading:       _isLoading,
                    errorMessage:    _errorMessage,
                    isDark:          isDark,
                    textColor:       textColor,
                    subtextColor:    subtextColor,
                    accent:          accent,
                    onSubmit:        _submit,
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Form state ─────────────────────────────────────────────────────────────

class _FormState extends StatelessWidget {
  final GlobalKey<FormState>  formKey;
  final TextEditingController emailController;
  final bool                  isLoading;
  final String?               errorMessage;
  final bool                  isDark;
  final Color                 textColor;
  final Color                 subtextColor;
  final Color                 accent;
  final VoidCallback          onSubmit;

  const _FormState({
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.errorMessage,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
    required this.accent,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppConstants.spacingXl),
          Text(
            context.tr('login.forgot_password_title'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color:      textColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            context.tr('login.forgot_password_desc'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: subtextColor,
                ),
          ),
          const SizedBox(height: AppConstants.spacingXl),
          TextFormField(
            controller:      emailController,
            keyboardType:    TextInputType.emailAddress,
            autofillHints:   const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText:  context.tr('login.email_label'),
              hintText:   context.tr('login.email_hint'),
              prefixIcon: const Icon(AppIcons.email),
            ),
            validator: (value) => FormValidators.validateEmail(value, context),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              errorMessage!,
              style: TextStyle(
                color:    isDark ? AppTheme.darkError : AppTheme.lightError,
                fontSize: AppConstants.fontSizeSm,
              ),
            ),
          ],
          const SizedBox(height: AppConstants.spacingXl),
          // FIX [BTN-SPLIT]: ElevatedButton primary CTA → AuthSubmitButton
          AuthSubmitButton(
            isLoading: isLoading,
            isDark:    isDark,
            onPressed: isLoading ? null : onSubmit,
            labelKey:  'login.reset_send',
          ),
        ],
      ),
    );
  }
}

// ── Success state ───────────────────────────────────────────────────────────

class _SuccessState extends StatelessWidget {
  final String       email;
  final bool         isDark;
  final Color        accent;
  final Color        subtextColor;
  final VoidCallback onBack;

  const _SuccessState({
    required this.email,
    required this.isDark,
    required this.accent,
    required this.subtextColor,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: AppConstants.spacingXl),
        Icon(Icons.mark_email_read_rounded, size: AppConstants.iconSizeLg2, color: accent),
        const SizedBox(height: AppConstants.spacingLg),
        Text(
          context.tr('login.reset_email_sent'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Text(
          email,
          style: TextStyle(
            color:    subtextColor,
            fontSize: AppConstants.fontSizeMd,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingXl),
        TextButton(
          onPressed: onBack,
          child: Text(context.tr('common.back')),
        ),
      ],
    );
  }
}
