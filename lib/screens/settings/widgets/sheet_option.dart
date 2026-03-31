// lib/screens/settings/widgets/sheet_option.dart

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

// FIX (UI Quality): replaced GestureDetector with Material + InkWell so every
// option produces a tactile ripple on tap — consistent with Tier-1 app
// standard (Revolut, N26, Linear all have ink feedback on sheet options).

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
          // Transparent — background handled by AnimatedContainer above.
          color:        Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            onTap:        onTap,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMd,
                vertical:   AppConstants.spacingMdLg - 6, // = 14dp
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
                  // FIX: replaced SizedBox(width: 14) with AppConstants token.
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
