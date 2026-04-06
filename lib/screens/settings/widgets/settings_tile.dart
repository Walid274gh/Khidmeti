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
// FIX [W6]: height: 64 → AppConstants.tileHeight (64.0) — magic literal promoted.
// FIX [W1]: iconColor.withOpacity(0.15) → iconColor.withValues(alpha: 0.15)
//           iconColor is caller-supplied at runtime so it cannot be const-baked.
//           withValues() is the modern Flutter API (replaces deprecated withOpacity).
//           The alpha value is also promoted to AppConstants.opacityIconBgAlt (0.15)
//           to align with the opacity token system used in SignOutTile.
// FIX [S1-AUTO]: Removed redundant copyWith on titleMedium title style.
//           titleMedium is already defined as 15sp/w600 in both darkTheme and
//           lightTheme. The copyWith(fontSize: fontSizeTileLg, fontWeight: w600)
//           was a no-op that added noise and would silently resist future theme
//           changes. Using theme.textTheme.titleMedium directly is now the
//           single source of truth.
// FIX [W-BORDER-RAW]: Border.all(width: 0.5) → width: AppConstants.cardBorderWidth
//           cardBorderWidth = 0.5 already exists in constants.dart and is the
//           canonical token for this stroke width. Using the raw literal here
//           was an untracked deviation from the token system.

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
        // spacingXxs = 2.0 is the on-grid token for the inter-tile gap.
        padding: const EdgeInsets.only(bottom: AppConstants.spacingXxs),
        child: Material(
          color:        Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusTile),
          child: InkWell(
            onTap:        onTap,
            borderRadius: BorderRadius.circular(AppConstants.radiusTile),
            child: Container(
              // [W6]: tileHeight = 64.0 — canonical settings row height token.
              height: AppConstants.tileHeight,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppConstants.paddingMd,
              ),
              decoration: BoxDecoration(
                // Resolves from theme automatically — responds to brightness changes.
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusTile),
                border: Border.all(
                  // Resolves from colorScheme.outline — responds to theme changes.
                  color: theme.colorScheme.outline,
                  // [W-BORDER-RAW]: cardBorderWidth (0.5) — canonical border-stroke
                  // token that already existed in constants.dart unused here.
                  width: AppConstants.cardBorderWidth,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width:  AppConstants.iconContainerXl,
                    height: AppConstants.iconContainerXl,
                    decoration: BoxDecoration(
                      // [W1]: withValues(alpha:) is the modern API replacing
                      // deprecated withOpacity(). The opacity value is named
                      // via opacityIconBgAlt (0.15) — consistent with the
                      // token used for the sign-out tile icon container.
                      color: iconColor.withValues(
                        alpha: AppConstants.opacityIconBgAlt,
                      ),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size:  AppConstants.buttonIconSize,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingTileInner),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:  MainAxisAlignment.center,
                      children: [
                        // [S1-AUTO]: titleMedium used directly — the theme already
                        // defines 15sp/w600 so copyWith was a no-op and has been
                        // removed. Any future change to titleMedium in the theme
                        // will now propagate here automatically.
                        Text(
                          title,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (subtitle != null) ...[
                          // spacingXxs = 2.0 — nearest on-grid value.
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
