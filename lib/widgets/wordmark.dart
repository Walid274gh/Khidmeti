// lib/widgets/wordmark.dart

import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';

class AppWordmark extends StatelessWidget {
  final bool isDark;
  const AppWordmark({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent    = isDark ? AppTheme.darkAccent    : AppTheme.lightAccent;
    final textColor = isDark ? AppTheme.darkText      : AppTheme.lightText;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glowing dot
        Container(
          width:  AppConstants.wordmarkDotSize,  // 8.0
          height: AppConstants.wordmarkDotSize,  // 8.0
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent,
            boxShadow: [
              BoxShadow(
                color:      accent.withOpacity(0.55),
                blurRadius: AppConstants.wordmarkDotBlur, // 10.0
                spreadRadius: 0,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // App name
        Text(
          context.tr('common.app_name'),
          style: TextStyle(
            fontSize:      AppConstants.wordmarkFontSize, // 13.0
            fontWeight:    FontWeight.w700,
            letterSpacing: 0.08,
            color:         textColor.withOpacity(0.70),
          ),
        ),
      ],
    );
  }
}
