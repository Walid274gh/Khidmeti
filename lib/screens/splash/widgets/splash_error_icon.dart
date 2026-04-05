// lib/screens/splash/widgets/splash_error_icon.dart

import 'package:flutter/material.dart';

import '../../../providers/splash_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';


class SplashErrorIcon extends StatelessWidget {
  final bool            isDark;
  final SplashErrorType errorType;

  const SplashErrorIcon({
    super.key,
    required this.isDark,
    required this.errorType,
  });

  @override
  Widget build(BuildContext context) {
    // FIX [UI1-W]: was `errorColor.withOpacity(0.10)` — inline opacity call.
    // Replaced with pre-baked const tokens AppTheme.darkErrorSubtle /
    // AppTheme.lightErrorSubtle (both encode 10% alpha in the hex value).
    final errorColor      = isDark ? AppTheme.darkError       : AppTheme.lightError;
    final errorColorSubtle = isDark ? AppTheme.darkErrorSubtle : AppTheme.lightErrorSubtle;

    // FIX (QA / a11y P1): was missing a Semantics wrapper entirely.
    // VoiceOver / TalkBack users received no announcement when the error state
    // appeared — the icon was invisible to screen readers. Without this node,
    // a blind user on the splash screen would hear silence, then (if they
    // explored) the retry button, with no indication of what went wrong.
    //
    // The Semantics node now:
    //   • Announces the localised error label immediately via liveRegion: true,
    //     so the announcement fires as soon as AnimatedSwitcher renders it.
    //   • Uses context.tr() for full fr/en/ar support, matching the text widget
    //     below it in SplashBottomStatus.
    return Semantics(
      label:      _semanticsLabel(context),
      liveRegion: true,
      child: Container(
        key:    const ValueKey('error'),
        // FIX [UI4-W]: was raw literals width: 200 / height: 200.
        // AppConstants.splashErrorCircleSize = 200.0 is the canonical token.
        width:  AppConstants.splashErrorCircleSize,
        height: AppConstants.splashErrorCircleSize,
        decoration: BoxDecoration(
          color: errorColorSubtle,
          // FIX [UI4-W]: was BorderRadius.circular(100) — magic number derived
          // from half of 200. Now computed from the token so it stays in sync
          // if splashErrorCircleSize ever changes.
          borderRadius: BorderRadius.circular(AppConstants.splashErrorCircleSize / 2),
        ),
        child: Icon(
          _iconForErrorType(errorType),
          // FIX [UI4-W]: was bare size: 80 — no AppConstants token.
          // AppConstants.iconSizeHero = 80.0 is the declared token for
          // display-scale decorative icons beyond the standard icon scale.
          size:  AppConstants.iconSizeHero,
          color: errorColor,
        ),
      ),
    );
  }

  /// Maps each SplashErrorType to a contextual icon.
  IconData _iconForErrorType(SplashErrorType type) {
    switch (type) {
      case SplashErrorType.noInternet:
        return Icons.wifi_off_rounded;
      case SplashErrorType.serverError:
        return Icons.dns_rounded;
      case SplashErrorType.timeout:
        return Icons.timer_off_rounded;
      case SplashErrorType.unknown:
      case SplashErrorType.none:
        return Icons.error_outline_rounded;
    }
  }

  /// Localised accessibility label — mirrors the text shown in SplashBottomStatus
  /// so screen reader users hear the same description as sighted users read.
  String _semanticsLabel(BuildContext context) {
    switch (errorType) {
      case SplashErrorType.noInternet:
        return context.tr('splash.error_no_internet');
      case SplashErrorType.serverError:
        return context.tr('splash.error_server');
      case SplashErrorType.timeout:
        return context.tr('splash.error_timeout');
      case SplashErrorType.unknown:
      case SplashErrorType.none:
        return context.tr('splash.error_message');
    }
  }
}
