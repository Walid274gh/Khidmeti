// lib/screens/settings/widgets/settings_tile.dart
//
// FIX [W4]: replaced AppTheme.darkSurface/lightSurface → theme.colorScheme.surface
//           replaced AppTheme.darkBorder/lightBorder   → theme.colorScheme.outline
//           Both bypass the colorScheme and would not respond to theme changes.
// FIX [W5]: SizedBox(height: 1) → height: AppConstants.spacingXxs (2.0)
//           EdgeInsets.only(bottom: 2) → AppConstants.spacingXxs
//           Both were off-grid (1dp and 2dp) and untokenized.
// FIX [W6]: width: 40, height: 40 → AppConstants.iconContainerXl (40.0)
//           size: 20 (icon) → AppConstants.buttonIconSize (20.0)

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

class SettingsTile extends StatelessWidget {
  final IconData     icon;
  final Color        iconColor;
  final String       title;
  final String?      subtitle;
  final VoidCallback onTap;
  final String       semanticsLabel;
  final Widget?      trailing;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    required this.semanticsLabel,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label:  semanticsLabel,
      button: true,
      child: Padding(
        // FIX [W5]: was EdgeInsets.only(bottom: 2) — bare 2dp, off-grid.
        // spacingXxs = 2.0 is the on-grid token for this value.
        padding: const EdgeInsets.only(bottom: AppConstants.spacingXxs),
        child: Material(
          color:        Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusTile),
          child: InkWell(
            onTap:        onTap,
            borderRadius: BorderRadius.circular(AppConstants.radiusTile),
            child: Container(
              height: 64,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppConstants.paddingMd,
              ),
              decoration: BoxDecoration(
                // FIX [W4]: was isDark ? AppTheme.darkSurface : AppTheme.lightSurface
                // — bypassed colorScheme. Now resolves from theme automatically.
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusTile),
                border: Border.all(
                  // FIX [W4]: was isDark ? AppTheme.darkBorder : AppTheme.lightBorder
                  // — bypassed colorScheme.outline. Now resolves from theme.
                  color: theme.colorScheme.outline,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    // FIX [W6]: was width: 40, height: 40 — magic literals.
                    // iconContainerXl = 40.0 is the canonical token.
                    width:  AppConstants.iconContainerXl,
                    height: AppConstants.iconContainerXl,
                    decoration: BoxDecoration(
                      color:        iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    ),
                    // FIX [W6]: was size: 20 — replaced with buttonIconSize token.
                    child: Icon(icon, color: iconColor, size: AppConstants.buttonIconSize),
                  ),
                  const SizedBox(width: AppConstants.spacingTileInner),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:  MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize:   AppConstants.fontSizeTileLg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null) ...[
                          // FIX [W5]: was SizedBox(height: 1) — off-grid, untokenized.
                          // spacingXxs = 2.0 is the nearest on-grid value.
                          const SizedBox(height: AppConstants.spacingXxs),
                          Text(subtitle!, style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  trailing ??
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.outline,
                        size:  AppConstants.buttonIconSize,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
