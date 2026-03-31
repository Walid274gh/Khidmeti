// lib/screens/settings/widgets/sign_out_tile.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// FIX (QA): added isEnabled parameter. When the sign-out sequence is in
// progress, the parent passes isEnabled: false — the tile becomes visually
// muted and the onTap callback is ignored, preventing the double-tap race
// condition identified in the audit.

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
          // When disabled, pass null to prevent any tap — same pattern as
          // Flutter's ElevatedButton disabled state.
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
                  width:  40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:        redColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Icon(
                    AppIcons.logout,
                    color: redColor,
                    size:  20,
                  ),
                ),
                // FIX: replaced SizedBox(width: 14) with AppConstants token.
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
                  size:  20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
