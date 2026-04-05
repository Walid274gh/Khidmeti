// lib/screens/splash/widgets/splash_bottom_status.dart

import 'package:flutter/material.dart';

import '../../../providers/splash_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'splash_loading_pulse.dart';

// FIX [UI1-W]: _kStatusAreaHeight = 64.0 removed — dead constant.
// The height is now owned by AppConstants.splashStatusAreaHeight and read
// directly in SplashScreen, which is the only place that sets the SizedBox.
// SplashBottomStatus itself is sized by its parent, not self-declared.

const double _kRetryButtonMinWidth  = 120.0;
const double _kRetryButtonMinHeight = 48.0;

class SplashBottomStatus extends StatelessWidget {
  final SplashState  controller;
  final bool         isDark;
  final VoidCallback onRetry;

  const SplashBottomStatus({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final accent     = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final errorColor = isDark ? AppTheme.darkError  : AppTheme.lightError;

    // ── Error + retry ─────────────────────────────────────────────────────
    if (controller.canRetry) {
      return Column(
        key:          const ValueKey('retry'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _errorMessage(context, controller.errorType),
            style: TextStyle(
              color:      errorColor,
              fontSize:   AppConstants.fontSizeSm,
              fontWeight: FontWeight.w400,  // was w500 — forbidden
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Semantics(
            button: true,
            label:  context.tr('common.retry'),
            child: OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side:            BorderSide(color: accent),
                minimumSize: const Size(_kRetryButtonMinWidth, _kRetryButtonMinHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
              ),
              // FIX [UI6-W]: was `const TextStyle(fontWeight: FontWeight.w600)` —
              // inline style bypasses theme. labelLarge is already w600/13sp/Inter
              // per TextTheme — no visual change, but now theme-driven.
              child: Text(
                context.tr('common.retry'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ],
      );
    }

    // ── Loading pulse ─────────────────────────────────────────────────────
    if (controller.phase == SplashPhase.initializing ||
        controller.phase == SplashPhase.animating) {
      return SplashLoadingPulse(
        key:   const ValueKey('loading'),
        color: accent,
        label: context.tr('common.loading'),
      );
    }

    return const SizedBox.shrink(key: ValueKey('empty'));
  }

  String _errorMessage(BuildContext context, SplashErrorType type) {
    switch (type) {
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
