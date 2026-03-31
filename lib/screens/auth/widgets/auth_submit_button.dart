// lib/screens/auth/widgets/auth_submit_button.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';


class AuthSubmitButton extends StatelessWidget {
  final bool         isLoading;
  final bool         isDark;
  final VoidCallback? onPressed;
  final String       labelKey;

  const AuthSubmitButton({
    super.key,
    required this.isLoading,
    required this.isDark,
    required this.onPressed,
    required this.labelKey,
  });

  bool get _isEnabled => !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final accent  = isDark ? AppTheme.darkAccent    : AppTheme.lightAccent;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Semantics(
      button:  true,
      enabled: _isEnabled,
      label:   context.tr(labelKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: AppConstants.buttonHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          boxShadow: _isEnabled
              ? [
                  BoxShadow(
                    color:        accent.withOpacity(0.35),
                    blurRadius:   40,
                    spreadRadius: 0,
                    offset:       const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color:        _isEnabled ? accent : accent.withOpacity(0.45),
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: InkWell(
            onTap:        _isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width:  22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color:       bgColor,
                      ),
                    )
                  : Text(
                      context.tr(labelKey),
                      style: TextStyle(
                        color: bgColor.withOpacity(_isEnabled ? 1.0 : 0.55),
                        fontSize:      15,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
