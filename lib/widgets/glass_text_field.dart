// lib/widgets/glass_text_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';

// ============================================================================
// GLASS TEXT FIELD
// Themed input field with focus-reactive border and icon colours.
//
// FIX (Structure): Extracted from text_field.dart which contained both
// GlassTextField and GlassPasswordField — violating one-class-per-file rule.
// ============================================================================

class GlassTextField extends StatefulWidget {
  final TextEditingController?     controller;
  final FocusNode?                 focusNode;
  final String?                    labelText;
  final String?                    hintText;
  final IconData?                  prefixIcon;
  final Widget?                    suffixIcon;
  final bool                       obscureText;
  final bool                       enabled;
  final bool                       autofocus;
  final TextInputType?             keyboardType;
  final TextInputAction?           textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>?      onChanged;
  final VoidCallback?              onEditingComplete;
  final ValueChanged<String>?      onSubmitted;
  final int?                       maxLines;
  final int?                       maxLength;
  final List<TextInputFormatter>?  inputFormatters;
  final AutovalidateMode?          autovalidateMode;
  final TextCapitalization         textCapitalization;
  final Iterable<String>?          autofillHints;

  const GlassTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText          = false,
    this.enabled              = true,
    this.autofocus            = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.maxLines             = 1,
    this.maxLength,
    this.inputFormatters,
    this.autovalidateMode,
    this.textCapitalization   = TextCapitalization.none,
    this.autofillHints,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  late final FocusNode _internalFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _internalFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _internalFocusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _internalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final accent      = isDark ? AppTheme.darkAccent      : AppTheme.lightAccent;
    final textColor   = isDark ? AppTheme.darkText         : AppTheme.lightText;
    final hintColor   = isDark ? AppTheme.darkTertiaryText : AppTheme.lightSecondaryText;
    final borderColor = _isFocused
        ? accent.withOpacity(0.6)
        : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder);
    final fillColor = isDark
        ? AppTheme.darkSurfaceVariant
        : AppTheme.lightSurfaceVariant;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color:        fillColor,
        borderRadius: BorderRadius.circular(AppConstants.inputRadius),
        border: Border.all(
          color: borderColor,
          width: _isFocused ? 1.5 : 0.5,
        ),
      ),
      child: TextFormField(
        controller:         widget.controller,
        focusNode:          _internalFocusNode,
        enabled:            widget.enabled,
        autofocus:          widget.autofocus,
        obscureText:        widget.obscureText,
        keyboardType:       widget.keyboardType,
        textInputAction:    widget.textInputAction,
        validator:          widget.validator,
        onChanged:          widget.onChanged,
        onEditingComplete:  widget.onEditingComplete,
        onFieldSubmitted:   widget.onSubmitted,
        maxLines:           widget.maxLines,
        maxLength:          widget.maxLength,
        inputFormatters:    widget.inputFormatters,
        autovalidateMode:   widget.autovalidateMode,
        textCapitalization: widget.textCapitalization,
        autofillHints:      widget.autofillHints,
        style: TextStyle(
          color:      textColor,
          fontSize:   AppConstants.fontSizeLg,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText:  widget.labelText,
          hintText:   widget.hintText,
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon,
                  color: _isFocused ? accent : hintColor)
              : null,
          suffixIcon: widget.suffixIcon,
          labelStyle: TextStyle(
            color:      _isFocused ? accent : hintColor,
            fontSize:   14,
            fontWeight: FontWeight.w400,
          ),
          hintStyle: TextStyle(color: hintColor, fontSize: 14),
          errorStyle: TextStyle(
            color:      Theme.of(context).colorScheme.error,
            fontSize:   12,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.inputPaddingH,
            vertical:   AppConstants.inputPaddingV,
          ),
          border:             InputBorder.none,
          enabledBorder:      InputBorder.none,
          focusedBorder:      InputBorder.none,
          errorBorder:        InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder:     InputBorder.none,
          counterText:        '',
        ),
      ),
    );
  }
}
