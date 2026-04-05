// lib/screens/settings/widgets/sign_out_tile.dart
//
// FIX [W6]: width: 40, height: 40 → AppConstants.iconContainerXl (40.0)
//           size: 20 (icon) → AppConstants.buttonIconSize (20.0)
//           Matches the token fix applied to settings_tile.dart and
//           _DeleteAccountTile — all three now share the same token source.

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
    final redColor = isEnabled
        ? AppTheme.signOutRed
        : AppTheme.signOutRed.withOpacity(0.4);

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
            height: 64,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppConstants.paddingMd,
            ),
            decoration: BoxDecoration(
              color: AppTheme.signOutRed
                  .withOpacity(isEnabled ? (isDark ? 0.12 : 0.08) : 0.04),
              borderRadius: BorderRadius.circular(AppConstants.radiusTile),
              border: Border.all(
                color: AppTheme.signOutRed
                    .withOpacity(isEnabled ? 0.2 : 0.08),
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
                    color:        redColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Icon(
                    AppIcons.logout,
                    color: redColor,
                    // FIX [W6]: was size: 20 — replaced with buttonIconSize token.
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
                  color: redColor.withOpacity(0.5),
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
