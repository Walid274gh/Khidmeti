// lib/screens/settings/widgets/sheet_option.dart
//
// FIX [W7]: replaced `AppConstants.spacingMdLg - 6` with `AppConstants.spacingTileInner`
//           spacingMdLg (20) - 6 = 14dp = spacingTileInner (14.0) exactly.
// FIX [W5]: fontSize: 22 → AppConstants.emojiIconSize (22.0) — flag Text style.
//           size: 22 → AppConstants.emojiIconSize (22.0) — icon option size.
//           size: 20 → AppConstants.buttonIconSize (20.0) — check icon.
// FIX [W4/W1-AUTO]: All 5 raw alpha float literals replaced with named
//           AppConstants opacity tokens. withValues(alpha:) is retained —
//           the modern Flutter API replacing deprecated withOpacity().
//           Base colors are runtime-resolved from colorScheme so these cannot
//           be const-baked; the alpha values are now named constants.
//
//   Raw literal → AppConstants token
//   isDark ? 0.2 : 0.1  → opacitySheetFillDark / opacitySheetFillLight
//   0.5 (border sel)    → opacitySheetBorderSel
//   0.2 (border unsel)  → opacitySheetBorderUnsel
//   0.6 (icon muted)    → opacitySheetIconMuted

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

class SheetOption extends StatelessWidget {
  final String     label;
  final String?    flag;
  final IconData?  icon;
  final bool       isSelected;
  final VoidCallback onTap;

  const SheetOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.flag,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    final borderRadius = BorderRadius.circular(AppConstants.radiusLg);

    return Semantics(
      label:    label,
      selected: isSelected,
      button:   true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin:   const EdgeInsets.only(bottom: AppConstants.spacingSm),
        decoration: BoxDecoration(
          // [W1-AUTO]: opacitySheetFillDark (0.20) / opacitySheetFillLight (0.10)
          // replace the inline isDark ? 0.2 : 0.1 literals.
          color: isSelected
              ? accent.withValues(
                  alpha: isDark
                      ? AppConstants.opacitySheetFillDark
                      : AppConstants.opacitySheetFillLight,
                )
              : Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(
            // [W1-AUTO]: opacitySheetBorderSel (0.50) / opacitySheetBorderUnsel (0.20)
            // replace the inline 0.5 and 0.2 literals.
            color: isSelected
                ? accent.withValues(alpha: AppConstants.opacitySheetBorderSel)
                : theme.colorScheme.outline.withValues(
                    alpha: AppConstants.opacitySheetBorderUnsel,
                  ),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color:        Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            onTap:        onTap,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMd,
                // spacingTileInner (14.0) replaces `spacingMdLg - 6` arithmetic.
                vertical: AppConstants.spacingTileInner,
              ),
              child: Row(
                children: [
                  if (flag != null)
                    // [W5]: emojiIconSize = 22.0 replaces raw fontSize: 22 literal.
                    Text(flag!, style: TextStyle(fontSize: AppConstants.emojiIconSize))
                  else if (icon != null)
                    Icon(
                      icon,
                      // [W5]: emojiIconSize = 22.0 replaces raw size: 22 literal.
                      size: AppConstants.emojiIconSize,
                      // [W1-AUTO]: opacitySheetIconMuted (0.60) replaces the
                      // inline 0.6 literal on the unselected icon colour.
                      color: isSelected
                          ? accent
                          : theme.colorScheme.onSurface.withValues(
                              alpha: AppConstants.opacitySheetIconMuted,
                            ),
                    ),
                  const SizedBox(width: AppConstants.spacingTileInner),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected
                            ? accent
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isSelected)
                    // [W5]: buttonIconSize = 20.0 replaces raw size: 20 literal.
                    Icon(Icons.check_rounded, color: accent, size: AppConstants.buttonIconSize),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
