// lib/screens/auth/widgets/otp_input_row.dart
//
// 6-box OTP input with:
//   • Auto-advance on digit entry
//   • Backspace → previous field
//   • Paste handling (Android + iOS)
//   • Auto-submit callback when all 6 filled
//   • autofillHints.oneTimeCode on first box
//
// Design: matches Midnight Indigo — accent border on focus, error state.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────

class OtpInputRow extends StatefulWidget {
  /// Called when all 6 digits are entered.
  final ValueChanged<String> onCompleted;

  /// Called on every digit change.
  final VoidCallback? onChanged;

  /// Whether to show error styling.
  final bool hasError;

  const OtpInputRow({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.hasError = false,
  });

  @override
  State<OtpInputRow> createState() => OtpInputRowState();
}

class OtpInputRowState extends State<OtpInputRow> {
  static const int _length = 6;

  final List<TextEditingController> _controllers =
      List.generate(_length, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_length, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes)  f.dispose();
    super.dispose();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Clears all boxes and focuses the first one.
  void clear() {
    for (final c in _controllers) c.clear();
    _focusNodes.first.requestFocus();
    setState(() {});
  }

  String get _currentCode =>
      _controllers.map((c) => c.text).join();

  // ── Handlers ───────────────────────────────────────────────────────────────

  void _onChanged(int index, String value) {
    // Handle paste — value may contain multiple digits
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length == _length) {
        _autofillAll(digits);
        return;
      }
      // Partial paste — fill from current position
      final chars = digits.split('');
      for (int i = 0; i < chars.length && (index + i) < _length; i++) {
        _controllers[index + i].text = chars[i];
      }
      final nextIndex = (index + chars.length).clamp(0, _length - 1);
      _focusNodes[nextIndex].requestFocus();
      _notifyChange();
      return;
    }

    if (value.isEmpty) return;

    // Single digit — advance to next
    if (index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }

    _notifyChange();
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey != LogicalKeyboardKey.backspace) return;
    if (_controllers[index].text.isNotEmpty) return;
    // Move focus back
    if (index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      _notifyChange();
    }
  }

  void _autofillAll(String digits) {
    for (int i = 0; i < _length; i++) {
      _controllers[i].text = digits[i];
    }
    _focusNodes.last.unfocus();
    _notifyChange();
    widget.onCompleted(digits);
  }

  void _notifyChange() {
    setState(() {});
    widget.onChanged?.call();
    final code = _currentCode;
    if (code.length == _length) {
      widget.onCompleted(code);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'OTP input, 6 digits',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_length, (index) {
          return _OtpBox(
            controller:  _controllers[index],
            focusNode:   _focusNodes[index],
            isDark:      isDark,
            hasError:    widget.hasError,
            isFirst:     index == 0,
            onChanged:   (v) => _onChanged(index, v),
            onKeyEvent:  (e) => _onKeyEvent(index, e),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual box
// ─────────────────────────────────────────────────────────────────────────────

class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final bool                  isDark;
  final bool                  hasError;
  final bool                  isFirst;
  final ValueChanged<String>  onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.hasError,
    required this.isFirst,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = widget.focusNode.hasFocus);
    });
  }

  Color get _borderColor {
    if (widget.hasError) {
      return widget.isDark ? AppTheme.darkError : AppTheme.lightError;
    }
    if (_isFocused) {
      return widget.isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    }
    if (widget.controller.text.isNotEmpty) {
      return (widget.isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
          .withOpacity(0.5);
    }
    return widget.isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.controller.text.isNotEmpty;

    return AnimatedContainer(
      duration:  AppConstants.animDurationMicro,
      width:     48,
      height:    56,
      decoration: BoxDecoration(
        color:        widget.isDark
            ? AppTheme.darkSurfaceVariant
            : AppTheme.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: _borderColor,
          width: _isFocused || hasValue ? 1.5 : 0.5,
        ),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: widget.onKeyEvent,
        child: TextField(
          controller:  widget.controller,
          focusNode:   widget.focusNode,
          autofillHints: widget.isFirst
              ? const [AutofillHints.oneTimeCode]
              : null,
          keyboardType:   TextInputType.number,
          textAlign:      TextAlign.center,
          maxLength:      2, // Allow paste detection via >1 length
          showCursor:     true,
          style: TextStyle(
            fontSize:   AppConstants.fontSizeXxl,
            fontWeight: FontWeight.w700,
            color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            border:         InputBorder.none,
            enabledBorder:  InputBorder.none,
            focusedBorder:  InputBorder.none,
            counterText:    '',
            isDense:        true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
