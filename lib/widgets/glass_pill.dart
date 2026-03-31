// lib/widgets/glass_pill.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

// ============================================================================
// GLASS PILL  (map overlay — horizontal pill container)
// Used by FullscreenMapControls for the title pill.
// Exempt from flat-surface rule — map overlays require blur for legibility.
//
// FIX (Structure): Extracted from glass_container.dart.
// ============================================================================

class GlassPill extends StatelessWidget {
  final Widget child;
  final bool   isDark;

  const GlassPill({
    super.key,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMd,
            vertical:   AppConstants.paddingXs + 2,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.50)
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.07),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
