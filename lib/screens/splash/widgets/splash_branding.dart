// lib/screens/splash/widgets/splash_branding.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class SplashBranding extends StatelessWidget {
  final bool isDark;

  /// Called once when the name animation finishes (~950 ms after first frame).
  /// SplashScreen uses this to satisfy one half of its navigation gate:
  ///   navigation = brandingDone ∧ minDurationElapsed (3 s)
  final VoidCallback onAnimationComplete;

  const SplashBranding({
    super.key,
    required this.isDark,
    required this.onAnimationComplete,
  });

  @override
  Widget build(BuildContext context) {
    // ── Colours from AppTheme — no raw hex values allowed here ──────────────
    final nameColor    = isDark ? AppTheme.darkText          : AppTheme.lightText;
    final taglineColor = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

    // ── Text styles — preserved exactly from the original widget ────────────
    final nameStyle = Theme.of(context).textTheme.headlineLarge?.copyWith(
      fontWeight:    FontWeight.w700,
      letterSpacing: -0.5,
      color:         nameColor,
    );

    final taglineStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w400,
      color:      taglineColor,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        // ── App name ─────────────────────────────────────────────────────────
        // Arrives confidently: fades in while drifting upward ~10 % of height.
        // This is the spatial cue used by Apple, Google Maps, and Airbnb —
        // the element "rises into place" rather than appearing out of nowhere.
        //
        // onComplete fires at delay(300ms) + duration(650ms) = 950 ms.
        // Both effects share the same timing so they complete simultaneously.
        Text(
          context.tr('common.app_name'),
          style: nameStyle,
        )
        .animate(
          onComplete: (_) => onAnimationComplete(),
        )
        .fadeIn(
          delay:    300.ms,
          duration: 650.ms,
          curve:    Curves.easeOut,
        )
        .slideY(
          begin:    0.10,   // starts 10 % below final position
          end:      0.0,
          delay:    300.ms,
          duration: 650.ms,
          curve:    Curves.easeOut,
        ),

        const SizedBox(height: AppConstants.spacingXs),

        // ── Tagline ──────────────────────────────────────────────────────────
        // Whisper-soft fade only — no motion.
        // It appears after the name has begun settling, so the user's eye
        // has already found the brand before reading the descriptor.
        Text(
          context.tr('splash.tagline'),
          style: taglineStyle,
        )
        .animate()
        .fadeIn(
          delay:    750.ms,
          duration: 500.ms,
          curve:    Curves.easeOut,
        ),

      ],
    );
  }
}
