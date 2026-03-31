// lib/screens/splash/widgets/splash_error_icon.dart

import 'package:flutter/material.dart';

import '../../../providers/splash_controller.dart';
import '../../../utils/app_theme.dart';
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
    final errorColor = isDark ? AppTheme.darkError : AppTheme.lightError;

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
        width:  200,
        height: 200,
        decoration: BoxDecoration(
          color:        errorColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Icon(
          _iconForErrorType(errorType),
          size:  80,
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
