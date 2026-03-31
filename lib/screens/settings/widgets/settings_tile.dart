// lib/screens/settings/widgets/settings_tile.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

// FIX (Engineer): replaced hardcoded SizedBox(width: 14) with
// AppConstants.spacingTileInner so all tile gaps (SettingsTile, SignOutTile,
// SheetOption) share a single source of truth.

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
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label:  semanticsLabel,
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
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
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(AppConstants.radiusTile),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width:  40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:        iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  // FIX: was SizedBox(width: 14) — replaced with token.
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
                          const SizedBox(height: 1),
                          Text(subtitle!, style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  trailing ??
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.outline,
                        size:  20,
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
