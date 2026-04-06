// lib/screens/auth/widgets/register_form_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/register_state.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../utils/validation_form.dart';
import '../../../widgets/text_field.dart';
import 'register_service_picker.dart';
import 'auth_submit_button.dart';
import 'register_terms_checkbox.dart';

// ============================================================================
// REGISTER FORM CARD — flat surface, no BackdropFilter
// ============================================================================

class RegisterFormCard extends StatelessWidget {
  final GlobalKey<FormState>  formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final FocusNode             nameFocus;
  final FocusNode             emailFocus;
  final FocusNode             phoneFocus;
  final FocusNode             passwordFocus;
  final FocusNode             confirmFocus;
  final RegisterState         state;
  final Animation<double>     roleScale;
  final VoidCallback          onSubmit;
  final VoidCallback          onFieldChanged;
  final ValueChanged<String>  onServiceSelected;
  final ValueChanged<bool>    onTermsChanged;

  const RegisterFormCard({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmController,
    required this.nameFocus,
    required this.emailFocus,
    required this.phoneFocus,
    required this.passwordFocus,
    required this.confirmFocus,
    required this.state,
    required this.roleScale,
    required this.onSubmit,
    required this.onFieldChanged,
    required this.onServiceSelected,
    required this.onTermsChanged,
  });

  // --------------------------------------------------------------------------
  // Password strength — 0 (empty) · 1 (weak) · 2 (fair) · 3 (good) · 4 (strong)
  // --------------------------------------------------------------------------

  static int _strengthOf(String pw) {
    if (pw.isEmpty) return 0;
    if (pw.length < AppConstants.minPasswordLength) return 1;
    int score = 1;
    // FIX [Magic]: was pw.length >= 10 (magic literal) — replaced with
    // AppConstants.goodPasswordLength (10) which documents the design intent.
    if (pw.length >= AppConstants.goodPasswordLength) score++;
    if (pw.contains(RegExp(r'[0-9]'))) score++;
    if (pw.contains(RegExp(r'[!@#$%^&*()\-_=+{};:,<.>?/\\|`~]'))) score++;
    return score.clamp(1, 4);
  }

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
            // Full name
            Semantics(
              label: context.tr('register.name_label'),
              child: GlassTextField(
                controller:         nameController,
                focusNode:          nameFocus,
                labelText:          context.tr('register.name_label'),
                hintText:           context.tr('register.name_hint'),
                prefixIcon:         AppIcons.profile,
                textInputAction:    TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                enabled:            !state.isLoading,
                autovalidateMode:   AutovalidateMode.onUserInteraction,
                onChanged:          (_) => onFieldChanged(),
                onEditingComplete:  () =>
                    FocusScope.of(context).requestFocus(emailFocus),
                validator: (v) => FormValidators.validateUsername(v, context),
              ),
            ),

            SizedBox(height: AppConstants.spacingMd),

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
                enabled:          !state.isLoading,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                maxLength:        254,
                onChanged:        (_) => onFieldChanged(),
                onEditingComplete: () =>
                    FocusScope.of(context).requestFocus(phoneFocus),
                validator: (v) => FormValidators.validateEmail(v, context),
              ),
            ),

            SizedBox(height: AppConstants.spacingMd),

            // Phone
            Semantics(
              label: context.tr('register.phone_label'),
              child: GlassTextField(
                controller:       phoneController,
                focusNode:        phoneFocus,
                labelText:        context.tr('register.phone_label'),
                hintText:         context.tr('register.phone_hint'),
                prefixIcon:       AppIcons.phone,
                keyboardType:     TextInputType.phone,
                textInputAction:  TextInputAction.next,
                enabled:          !state.isLoading,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged:        (_) => onFieldChanged(),
                onEditingComplete: () =>
                    FocusScope.of(context).requestFocus(passwordFocus),
                validator: (v) => FormValidators.validatePhone(v, context),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-]')),
                  LengthLimitingTextInputFormatter(15),
                ],
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
                hintText:         context.tr('register.password_hint'),
                textInputAction:  TextInputAction.next,
                enabled:          !state.isLoading,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged:        (_) => onFieldChanged(),
                onEditingComplete: () =>
                    FocusScope.of(context).requestFocus(confirmFocus),
                validator: (v) => FormValidators.validatePassword(v, context),
              ),
            ),

            ValueListenableBuilder<TextEditingValue>(
              valueListenable: passwordController,
              builder: (_, value, __) {
                final strength = _strengthOf(value.text);
                if (strength == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(
                    top:    AppConstants.spacingXs,
                    bottom: AppConstants.spacingXs,
                  ),
                  child: _PasswordStrengthBar(isDark: isDark, strength: strength),
                );
              },
            ),

            SizedBox(height: AppConstants.spacingMd),

            // Confirm password
            Semantics(
              label: context.tr('register.confirm_password_label'),
              child: GlassPasswordField(
                controller:       confirmController,
                focusNode:        confirmFocus,
                labelText:        context.tr('register.confirm_password_label'),
                hintText:         context.tr('register.confirm_password_hint'),
                textInputAction:  TextInputAction.done,
                enabled:          !state.isLoading,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged:        (_) => onFieldChanged(),
                onSubmitted:      (_) => onSubmit(),
                validator: (v) => FormValidators.validateConfirmPassword(
                    v, passwordController.text, context),
              ),
            ),

            // Worker: service selector
            if (state.isWorker) ...[
              SizedBox(height: AppConstants.spacingMd),
              ScaleTransition(
                scale: roleScale,
                child: RegisterServicePicker(
                  selected:   state.selectedService,
                  isDark:     isDark,
                  enabled:    !state.isLoading,
                  onSelected: onServiceSelected,
                ),
              ),
            ],

            SizedBox(height: AppConstants.spacingLg),

            // Terms checkbox
            RegisterTermsCheckbox(
              accepted:  state.termsAccepted,
              isDark:    isDark,
              enabled:   !state.isLoading,
              onChanged: onTermsChanged,
            ),

            SizedBox(height: AppConstants.spacingLg),

            // Submit button
            AuthSubmitButton(
              isLoading: state.isLoading,
              isDark:    isDark,
              onPressed: onSubmit,
              labelKey:  'register.submit',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PASSWORD STRENGTH BAR
// ============================================================================

class _PasswordStrengthBar extends StatelessWidget {
  final bool isDark;
  final int  strength; // 1–4

  const _PasswordStrengthBar({required this.isDark, required this.strength});

  Color _barColor() {
    if (strength <= 1) return isDark ? AppTheme.darkError  : AppTheme.lightError;
    if (strength == 2) return isDark ? AppTheme.darkWarning : AppTheme.lightWarning;
    return isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess;
  }

  String _label(BuildContext context) {
    switch (strength) {
      case 1: return context.tr('register.password_strength_weak');
      case 2: return context.tr('register.password_strength_fair');
      case 3: return context.tr('register.password_strength_good');
      case 4: return context.tr('register.password_strength_strong');
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _barColor();
    final empty = isDark
        ? AppTheme.darkBorder
        : AppTheme.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4-segment bar
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                // FIX [Dim-OFF]: was height: 3 (magic literal) — replaced
                // with AppConstants.strengthBarHeight (3.0).
                height: AppConstants.strengthBarHeight,
                // FIX [Dim-OFF]: was EdgeInsets.only(right: i < 3 ? 3 : 0)
                // — replaced with AppConstants.strengthBarGap (3.0).
                margin: EdgeInsets.only(
                  right: i < 3 ? AppConstants.strengthBarGap : 0,
                ),
                decoration: BoxDecoration(
                  color: i < strength ? color : empty,
                  // FIX [Dim-OFF]: was BorderRadius.circular(2) — replaced
                  // with AppConstants.strengthBarRadius (2.0).
                  borderRadius: BorderRadius.circular(AppConstants.strengthBarRadius),
                ),
              ),
            );
          }),
        ),
        // FIX [Dim-RAW]: was const SizedBox(height: 4) — replaced with
        // AppConstants.spacingXs (4dp, same value, now tokenised).
        const SizedBox(height: AppConstants.spacingXs),
        // Label
        Text(
          _label(context),
          style: TextStyle(
            fontSize: AppConstants.fontSizeXs,
            color:    color,
          ),
        ),
      ],
    );
  }
}
