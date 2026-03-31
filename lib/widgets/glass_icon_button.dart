// lib/widgets/glass_icon_button.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

// ============================================================================
// GLASS ICON BUTTON  (map overlay — 48×48 icon button)
// Used by HomeTopBar for the notification button.
// Exempt from flat-surface rule — map overlays require blur for legibility.
//
// FIX (Structure): Extracted from glass_container.dart.
// ============================================================================

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final bool     isDark;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width:  48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withOpacity(0.09)
                : Colors.white.withOpacity(0.72),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.16)
                  : Colors.white.withOpacity(0.90),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size:  22,
          ),
        ),
      ),
    );
  }
}
