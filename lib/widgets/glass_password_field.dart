// lib/widgets/glass_password_field.dart

import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/localization.dart';
import 'glass_text_field.dart';

// ============================================================================
// GLASS PASSWORD FIELD
// Self-contained obscure/reveal toggle wrapping GlassTextField.
//
// FIX (Structure): Extracted from text_field.dart (one-class-per-file rule).
//
// FIX (L10n P1): show/hide password tooltip was hardcoded French:
//   'Afficher' / 'Masquer'
// Now uses localization keys form.show_password / form.hide_password
// which must be present in fr, en, ar locale maps.
// ============================================================================

class GlassPasswordField extends StatefulWidget {
  final TextEditingController?     controller;
  final FocusNode?                 focusNode;
  final String?                    labelText;
  final String?                    hintText;
  final bool                       enabled;
  final TextInputAction?           textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>?      onChanged;
  final VoidCallback?              onEditingComplete;
  final ValueChanged<String>?      onSubmitted;
  final int?                       maxLength;
  final AutovalidateMode?          autovalidateMode;

  const GlassPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.enabled           = true,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.maxLength,
    this.autovalidateMode,
  });

  @override
  State<GlassPasswordField> createState() => _GlassPasswordFieldState();
}

class _GlassPasswordFieldState extends State<GlassPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return GlassTextField(
      controller:        widget.controller,
      focusNode:         widget.focusNode,
      labelText:         widget.labelText,
      hintText:          widget.hintText,
      prefixIcon:        AppIcons.password,
      obscureText:       _obscure,
      enabled:           widget.enabled,
      keyboardType:      TextInputType.visiblePassword,
      textInputAction:   widget.textInputAction,
      validator:         widget.validator,
      onChanged:         widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted:       widget.onSubmitted,
      maxLength:         widget.maxLength,
      autovalidateMode:  widget.autovalidateMode,
      autofillHints:     _obscure
          ? const [AutofillHints.password]
          : const [AutofillHints.newPassword],
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? AppIcons.visibility : AppIcons.visibilityOff,
          size: 20,
        ),
        onPressed: widget.enabled
            ? () => setState(() => _obscure = !_obscure)
            : null,
        // FIX (L10n): was hardcoded French 'Afficher'/'Masquer'.
        // Now uses localization keys defined in fr/en/ar locale files.
        tooltip: _obscure
            ? context.tr('form.show_password')
            : context.tr('form.hide_password'),
      ),
    );
  }
}
