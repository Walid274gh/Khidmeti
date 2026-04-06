// lib/screens/settings/widgets/sign_out_tile.dart
//
// FIX [W6]: width: 40, height: 40 → AppConstants.iconContainerXl (40.0)
//           size: 20 (icon) → AppConstants.buttonIconSize (20.0)
// FIX [W6]: height: 64 → AppConstants.tileHeight (64.0).
// FIX [W2]: all inline .withOpacity() calls replaced with named opacity tokens
//           from AppConstants. The base color (signOutRed / redColor) is
//           runtime-resolved so these cannot be const-baked, but the discrete
//           alpha levels are now named constants rather than magic literals.
//           withValues(alpha:) is used throughout — the modern Flutter API
//           that supersedes the deprecated withOpacity().

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class SignOutTile extends StatelessWidget {
  final VoidCallback onSignOut;
  final bool         isEnabled;

  const SignOutTile({
    super.key,
    required this.onSignOut,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final isDark   = theme.brightness == Brightness.dark;

    // [W2]: opacityDisabledColor (0.40) replaces magic 0.4 literal.
    final redColor = isEnabled
        ? AppTheme.signOutRed
        : AppTheme.signOutRed.withValues(alpha: AppConstants.opacityDisabledColor);

    return Semantics(
      label:   context.tr('auth.logout'),
      button:  true,
      enabled: isEnabled,
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusTile),
        child: InkWell(
          onTap:        isEnabled ? onSignOut : null,
          borderRadius: BorderRadius.circular(AppConstants.radiusTile),
          child: Container(
            // [W6]: tileHeight = 64.0 — canonical settings row height token.
            height: AppConstants.tileHeight,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppConstants.paddingMd,
            ),
            decoration: BoxDecoration(
              // [W2]: named opacity tokens replace magic literals.
              // disabled → opacityTileFillDisabled (0.04)
              // enabled dark → opacityTileFillDarkEn (0.12)
              // enabled light → opacityTileFillLightEn (0.08)
              color: AppTheme.signOutRed.withValues(
                alpha: isEnabled
                    ? (isDark
                        ? AppConstants.opacityTileFillDarkEn
                        : AppConstants.opacityTileFillLightEn)
                    : AppConstants.opacityTileFillDisabled,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusTile),
              border: Border.all(
                // [W2]: opacityBorderEnabled (0.20) / opacityBorderDisabled (0.08).
                color: AppTheme.signOutRed.withValues(
                  alpha: isEnabled
                      ? AppConstants.opacityBorderEnabled
                      : AppConstants.opacityBorderDisabled,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width:  AppConstants.iconContainerXl,
                  height: AppConstants.iconContainerXl,
                  decoration: BoxDecoration(
                    // [W2]: opacityIconBgAlt (0.15) replaces magic 0.15 literal.
                    color: redColor.withValues(alpha: AppConstants.opacityIconBgAlt),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Icon(
                    AppIcons.logout,
                    color: redColor,
                    size:  AppConstants.buttonIconSize,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingTileInner),
                Expanded(
                  child: Text(
                    context.tr('auth.logout'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize:   AppConstants.fontSizeTileLg,
                      fontWeight: FontWeight.w600,
                      color:      redColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  // [W2]: opacityChevron (0.50) replaces magic 0.5 literal.
                  color: redColor.withValues(alpha: AppConstants.opacityChevron),
                  size:  AppConstants.buttonIconSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
