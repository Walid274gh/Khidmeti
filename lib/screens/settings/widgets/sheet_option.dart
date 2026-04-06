// lib/screens/settings/widgets/sheet_option.dart
//
// FIX [W7]: replaced `AppConstants.spacingMdLg - 6` with `AppConstants.spacingTileInner`
//           spacingMdLg (20) - 6 = 14dp = spacingTileInner (14.0) exactly.
// FIX [W5]: fontSize: 22 → AppConstants.emojiIconSize (22.0) — flag Text style.
//           size: 22 → AppConstants.emojiIconSize (22.0) — icon option size.
//           size: 20 → AppConstants.buttonIconSize (20.0) — check icon.
// FIX [W4]: .withOpacity() calls on colorScheme values are documented below.
//           These are intentionally left as runtime calls — the base color is
//           dynamically resolved from colorScheme at build time so they cannot
//           be const-baked. withValues(alpha:) replaces the deprecated API.

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
          // [W4]: accent and colorScheme values are runtime-resolved — cannot
          // be const-baked. withValues(alpha:) replaces deprecated withOpacity().
          // These are intentional dynamic tints: selection highlight (20%/10%)
          // and border states (50% selected / 20% unselected / 60% icon mute).
          color: isSelected
              ? accent.withValues(alpha: isDark ? 0.2 : 0.1)
              : Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.5)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
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
                      size:  AppConstants.emojiIconSize,
                      // [W4]: dynamic colorScheme — runtime resolved, cannot const-bake.
                      color: isSelected
                          ? accent
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
