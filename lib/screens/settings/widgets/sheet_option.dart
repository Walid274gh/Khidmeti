// lib/screens/settings/widgets/sheet_option.dart
//
// FIX [W7]: replaced `AppConstants.spacingMdLg - 6` with `AppConstants.spacingTileInner`
//           spacingMdLg (20) - 6 = 14dp = spacingTileInner (14.0) exactly.
//           The arithmetic was a code smell; the named token already exists.

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
          color: isSelected
              ? accent.withOpacity(isDark ? 0.2 : 0.1)
              : Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(
            color: isSelected
                ? accent.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.2),
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
                // FIX [W7]: was `spacingMdLg - 6` (20 - 6 = 14dp) — arithmetic
                // in layout code. spacingTileInner (14.0) is the exact named token.
                vertical: AppConstants.spacingTileInner,
              ),
              child: Row(
                children: [
                  if (flag != null)
                    Text(flag!, style: const TextStyle(fontSize: 22))
                  else if (icon != null)
                    Icon(
                      icon,
                      size:  22,
                      color: isSelected
                          ? accent
                          : theme.colorScheme.onSurface.withOpacity(0.6),
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
                    Icon(Icons.check_rounded, color: accent, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
