// lib/screens/auth/widgets/login_form_card.dart

import 'package:flutter/material.dart';

import '../../../models/login_state.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../utils/validation_form.dart';
import '../../../widgets/text_field.dart';
import 'auth_submit_button.dart';

// ============================================================================
// LOGIN FORM CARD
// ============================================================================

class LoginFormCard extends StatelessWidget {
  final GlobalKey<FormState>    formKey;
  final TextEditingController   emailController;
  final TextEditingController   passwordController;
  final FocusNode               emailFocus;
  final FocusNode               passwordFocus;
  final LoginState              state;
  final VoidCallback?           onSubmit;
  final VoidCallback            onForgotPassword;
  final ValueChanged<String>    onEmailChanged;

  const LoginFormCard({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocus,
    required this.passwordFocus,
    required this.state,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onEmailChanged,
  });

  /// True when Firebase has rate-limited this device/IP.
  bool get _isLockedOut =>
      state.hasError && state.errorMessage == 'errors.too_many_requests';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email
            Semantics(
              label: context.tr('login.email_label'),
              child: GlassTextField(
                controller:       emailController,
                focusNode:        emailFocus,
                labelText:        context.tr('login.email_label'),
                hintText:         context.tr('login.email_hint'),
                prefixIcon:       AppIcons.email,
                keyboardType:     TextInputType.emailAddress,
                textInputAction:  TextInputAction.next,
                enabled:          !state.isLoading && !_isLockedOut,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                maxLength:        254,
                onChanged:        onEmailChanged,
                onEditingComplete: () =>
                    FocusScope.of(context).requestFocus(passwordFocus),
                validator: (v) => FormValidators.validateEmail(v, context),
              ),
            ),

            SizedBox(height: AppConstants.spacingMd),

            // Password
            Semantics(
              label: context.tr('login.password_label'),
              child: GlassPasswordField(
                controller:       passwordController,
                focusNode:        passwordFocus,
                labelText:        context.tr('login.password_label'),
                hintText:         context.tr('login.password_hint'),
                textInputAction:  TextInputAction.done,
                enabled:          !state.isLoading && !_isLockedOut,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                maxLength:        128,
                onSubmitted:      (_) => onSubmit?.call(),
                validator:        (v) => FormValidators.validatePassword(v, context),
              ),
            ),

            // Inline error feedback — shown below fields, not in global banner.
            if (state.hasError && state.errorMessage != null) ...[
              SizedBox(height: AppConstants.spacingSm),
              if (_isLockedOut)
                _LockoutWidget(isDark: isDark)
              else
                Text(
                  context.tr(state.errorMessage!),
                  style: TextStyle(
                    color:    isDark ? AppTheme.darkError : AppTheme.lightError,
                    fontSize: AppConstants.fontSizeSm,
                  ),
                ),
            ],

            SizedBox(height: AppConstants.spacingSm),

            // Forgot password — RTL-safe alignment
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Semantics(
                button: true,
                label:  context.tr('login.forgot_password'),
                child: TextButton(
                  onPressed: (state.isLoading || _isLockedOut)
                      ? null
                      : onForgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingSm,
                      vertical:   AppConstants.paddingXs,
                    ),
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text(
                    context.tr('login.forgot_password'),
                    style: TextStyle(
                      color:      isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                      fontWeight: FontWeight.w600,
                      fontSize:   AppConstants.fontSizeCaption,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: AppConstants.spacingLg),

            // Submit button — null when fields empty OR when locked out
            AuthSubmitButton(
              isLoading: state.isLoading,
              onPressed: _isLockedOut ? null : onSubmit,
              isDark:    isDark,
              labelKey:  'login.submit',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// LOCKOUT WIDGET
// ============================================================================

class _LockoutWidget extends StatelessWidget {
  final bool isDark;

  const _LockoutWidget({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkWarningSubtle
            : AppTheme.lightWarningSubtle,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(
          color: isDark
              ? AppTheme.darkWarningBorder
              : AppTheme.lightWarningBorder,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_clock_outlined,
            size:  AppConstants.iconSizeXs,
            color: isDark ? AppTheme.darkWarning : AppTheme.lightWarning,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              context.tr('errors.too_many_requests'),
              style: TextStyle(
                fontSize: AppConstants.fontSizeSm,
                color: isDark ? AppTheme.darkWarning : AppTheme.lightWarning,
                // FIX [Dim-RAW]: was height: 1.4 (magic literal) — replaced
                // with AppConstants.lineHeightTight (1.4).
                height: AppConstants.lineHeightTight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
