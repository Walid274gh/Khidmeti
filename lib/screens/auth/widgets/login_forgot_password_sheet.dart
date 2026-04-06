// lib/screens/auth/widgets/login_forgot_password_sheet.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../utils/validation_form.dart';
import '../../../widgets/sheet_handle.dart';
import '../../../widgets/text_field.dart';

// ============================================================================
// FORGOT PASSWORD BOTTOM SHEET
// ============================================================================

class LoginForgotPasswordSheet extends StatefulWidget {
  final TextEditingController     emailController;
  final GlobalKey<FormState>      formKey;
  final Future<void> Function(String email) onSend;

  const LoginForgotPasswordSheet({
    super.key,
    required this.emailController,
    required this.formKey,
    required this.onSend,
  });

  @override
  State<LoginForgotPasswordSheet> createState() =>
      _LoginForgotPasswordSheetState();
}

class _LoginForgotPasswordSheetState
    extends State<LoginForgotPasswordSheet> {
  bool _sending = false;

  Future<void> _send() async {
    if (!(widget.formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    await widget.onSend(widget.emailController.text.trim());
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingLg,
        AppConstants.paddingLg,
        AppConstants.paddingLg,
        AppConstants.paddingLg + bottomPad,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXxl), // 24.0
        ),
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FIX [H3/W1]: was raw width:40/height:4 with
            // Colors.white.withOpacity(0.15)/Colors.black.withOpacity(0.12).
            // Replaced with SheetHandle widget (uses pre-baked tokens).
            const SheetHandle(),

            const SizedBox(height: AppConstants.spacingLg),

            Text(
              context.tr('login.forgot_password_title'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: AppConstants.spacingSm),

            Text(
              context.tr('login.forgot_password_desc'),
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
            ),

            const SizedBox(height: AppConstants.spacingLg),

            GlassTextField(
              controller:       widget.emailController,
              labelText:        context.tr('login.email_label'),
              hintText:         context.tr('login.email_hint'),
              prefixIcon:       AppIcons.email,
              keyboardType:     TextInputType.emailAddress,
              textInputAction:  TextInputAction.done,
              enabled:          !_sending,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onSubmitted:      (_) => _send(),
              validator:        (v) => FormValidators.validateEmail(v, context),
            ),

            const SizedBox(height: AppConstants.spacingLg),

            // FIX [H3/W1]: was height:52 (off-grid) — replaced with
            // AppConstants.buttonHeight (54dp, the canonical button height).
            SizedBox(
              height: AppConstants.buttonHeight,
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? SizedBox(
                        width:  AppConstants.spinnerSizeLg,
                        height: AppConstants.spinnerSizeLg,
                        // FIX [C1]: was Colors.white (hardcoded) — replaced
                        // with Theme.of(context).colorScheme.onPrimary so the
                        // spinner colour adapts correctly if the accent colour
                        // ever changes.
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Text(context.tr('login.reset_send')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
