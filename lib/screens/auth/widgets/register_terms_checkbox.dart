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
          // Small padding so the ripple doesn't clip at the row edge
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width:  22,
                height: 22,
                decoration: BoxDecoration(
                  // FIX (Designer): BorderRadius.circular(6) → AppConstants.radiusXs (4)
                  // aligns with the nearest existing token.
                  borderRadius: BorderRadius.circular(AppConstants.radiusXs + 2),
                  color: accepted ? accent : Colors.transparent,
                  border: Border.all(
                    color: accepted
                        ? accent
                        : (isDark
                            ? Colors.white.withOpacity(0.25)
                            : Colors.black.withOpacity(0.20)),
                    width: 1.5,
                  ),
                ),
                child: accepted
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
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
