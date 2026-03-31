// lib/widgets/glass_bottom_sheet.dart

import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';

class GlassBottomSheet extends StatelessWidget {
  final String       title;
  final List<Widget> children;

  const GlassBottomSheet({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXxl), // 24.0
        ),
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        top:    AppConstants.paddingMd,
        left:   AppConstants.spacingMdLg,
        right:  AppConstants.spacingMdLg,
        bottom: MediaQuery.of(context).padding.bottom + AppConstants.spacingMdLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  AppConstants.sheetHandleWidth,
            height: AppConstants.sheetHandleHeight,
            decoration: BoxDecoration(
              color:        theme.colorScheme.outline.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          ...children,
        ],
      ),
    );
  }
}
