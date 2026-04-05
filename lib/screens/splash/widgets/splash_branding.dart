// lib/screens/splash/widgets/splash_branding.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class SplashBranding extends StatelessWidget {
  final bool isDark;

  /// Called once when ALL branding animations have completed — specifically
  /// when the tagline fade-in finishes at delay(750ms) + duration(500ms) = 1250ms.
  ///
  /// FIX [MANUAL / W5]: was wired to the app-name animation onComplete, which
  /// fires at 950ms — 300ms before the tagline finishes rendering. This meant
  /// SplashController could start its navigation check while the user was still
  /// watching live animation, creating a race where the splash could dismiss
  /// with the tagline mid-fade on slow devices.
  ///
  /// Moved to the tagline's onComplete so the callback fires only after every
  /// visible element has settled. The controller's min-duration gate (≥ 3s)
  /// already provides a hard floor well above this 1250ms, so there is zero
  /// regression risk — the only change is that _isAnimationComplete becomes
  /// true 300ms later, which is the correct behaviour.
  final VoidCallback onAnimationComplete;

  const SplashBranding({
    super.key,
    required this.isDark,
    required this.onAnimationComplete,
  });

  @override
  Widget build(BuildContext context) {
    // ── Colours from AppTheme — no raw hex values allowed here ──────────────
    // Design-system stance: AppTheme.darkX/lightX statics are used intentionally
    // throughout the splash widgets. Runtime theme-switching is not required for
    // the splash screen (it renders once before the user can change themes), so
    // the static tokens are the correct choice here. If theme-switching is ever
    // added, migrate these to Theme.of(context).colorScheme equivalents.
    final nameColor    = isDark ? AppTheme.darkText          : AppTheme.lightText;
    final taglineColor = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

    // ── Text styles — preserved exactly from the original widget ────────────
    // FIX [UI6-W]: was `Theme.of(context).textTheme.headlineLarge?.copyWith(...)`
    // — nullable access. If headlineLarge were null the entire nameStyle would
    // silently fall back to the default TextStyle, losing all font settings.
    // The fallback is explicit now: an empty const TextStyle() is used, which
    // is a safe no-op that copyWith() can build upon.
    //
    // FIX [MANUAL / W2]: letterSpacing: -0.5 was silently overriding the theme
    // token headlineLarge.letterSpacing = -1.2. The canonical value for the
    // splash app-name headline is -0.5 (tighter than body, looser than display).
    // The theme token has been updated to -0.5 in app_theme.dart accordingly,
    // and the local override is removed here to prevent future divergence.
    final nameStyle = (Theme.of(context).textTheme.headlineLarge ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w700,
      color:      nameColor,
      // letterSpacing intentionally omitted — inherits from updated theme token
      // (headlineLarge.letterSpacing = -0.5). See app_theme.dart [W2] comment.
    );

    // FIX [MANUAL]: removed redundant .copyWith(fontWeight: FontWeight.w400)
    // from taglineStyle — bodyMedium is already w400 per the textTheme definition.
    // Keeping it was misleading (implied an intentional override) and wasteful.
    final taglineStyle = (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: taglineColor,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        // ── App name ─────────────────────────────────────────────────────────
        // Arrives confidently: fades in while drifting upward ~10 % of height.
        // This is the spatial cue used by Apple, Google Maps, and Airbnb —
        // the element "rises into place" rather than appearing out of nowhere.
        //
        // FIX [W5]: onComplete removed from here (was 950ms — too early).
        // See tagline animation below for the corrected placement (1250ms).
        Text(
          context.tr('common.app_name'),
          style: nameStyle,
        )
        .animate()
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
        //
        // FIX [W5]: onComplete moved here from the name animation.
        // Tagline completes at delay(750ms) + duration(500ms) = 1250ms — the
        // last visible motion on screen. Firing onAnimationComplete here
        // ensures the gate opens only after all animation has fully settled,
        // preventing any race where the splash dismisses mid-animation.
        Text(
          context.tr('splash.tagline'),
          style: taglineStyle,
        )
        .animate(
          onComplete: (_) => onAnimationComplete(),
        )
        .fadeIn(
          delay:    750.ms,
          duration: 500.ms,
          curve:    Curves.easeOut,
        ),

      ],
    );
  }
}
