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
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                // FIX [Anim-DUR]: was Duration(milliseconds: 200) — unified to
                // AppConstants.animDurationMicro.
                duration: AppConstants.animDurationMicro,
                // FIX [Dim-OFF]: was 22×22 (off 4dp grid) — kept as logoOrbIconSize
                // is 30dp (also off-grid). Both pending designer sign-off; these
                // are intentional micro-UI sizes that sit between grid steps.
                // Tokenised as socialSpinnerSize is not the right semantic —
                // using raw 22 literal retained pending its own token addition.
                // TODO: add checkboxSize token once designer confirms 20dp or 24dp.
                width:  22,
                height: 22,
                decoration: BoxDecoration(
                  // FIX (Designer): BorderRadius.circular(6) → AppConstants.radiusXs + 2
                  // aligns with the nearest existing token.
                  borderRadius: BorderRadius.circular(AppConstants.radiusXs + 2),
                  color: accepted ? accent : Colors.transparent,
                  border: Border.all(
                    // FIX [Col-TOKEN-MISS]: was Colors.white.withOpacity(0.25) /
                    // Colors.black.withOpacity(0.20) — wired to the pre-baked tokens
                    // darkCheckboxBorder / lightCheckboxBorder that already existed
                    // in AppTheme but were never used here.
                    color: accepted
                        ? accent
                        : (isDark
                            ? AppTheme.darkCheckboxBorder
                            : AppTheme.lightCheckboxBorder),
                    width: 1.5,
                  ),
                ),
                // FIX [Col-HARD]: was color: Colors.white (hardcoded) — replaced
                // with colorScheme.onPrimary so the icon adapts with the theme.
                child: accepted
                    ? Icon(
                        Icons.check_rounded,
                        size:  14,
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : null,
              ),
              // FIX [Dim-OFF]: was SizedBox(width: 10) — replaced with
              // AppConstants.spacingSm (8dp, nearest on-grid value).
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
