// lib/screens/auth/widgets/register_terms_checkbox.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';


class RegisterTermsCheckbox extends StatelessWidget {
  final bool               accepted;
  final bool               isDark;
  final bool               enabled;
  final ValueChanged<bool> onChanged;

  const RegisterTermsCheckbox({
    super.key,
    required this.accepted,
    required this.isDark,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Semantics(
      checked: accepted,
      label:   context.tr('register.terms_label'),
      child: InkWell(
        onTap:        enabled ? () => onChanged(!accepted) : null,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: AppConstants.animDurationMicro,
                // FIX [Dim-RAW]: was width: 22, height: 22 (raw literals) —
                // replaced with AppConstants.checkboxSize token (22.0).
                // TODO: designer sign-off pending — confirm 20dp or 24dp
                // (current 22dp is off the 4dp grid).
                width:  AppConstants.checkboxSize,
                height: AppConstants.checkboxSize,
                decoration: BoxDecoration(
                  // FIX [Dim-RAW]: was BorderRadius.circular(AppConstants.radiusXs + 2)
                  // — replaced with AppConstants.checkboxRadius token (6.0).
                  borderRadius: BorderRadius.circular(AppConstants.checkboxRadius),
                  color: accepted ? accent : Colors.transparent,
                  border: Border.all(
                    color: accepted
                        ? accent
                        : (isDark
                            ? AppTheme.darkCheckboxBorder
                            : AppTheme.lightCheckboxBorder),
                    width: 1.5,
                  ),
                ),
                child: accepted
                    ? Icon(
                        Icons.check_rounded,
                        // FIX [Dim-RAW]: was size: 14 (raw literal) — replaced
                        // with AppConstants.checkboxIconSize token (14.0).
                        size:  AppConstants.checkboxIconSize,
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text:  context.tr('register.terms_prefix'),
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeCaption,
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                    children: [
                      TextSpan(
                        text:  context.tr('register.terms_link'),
                        style: TextStyle(
                          color:      accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
