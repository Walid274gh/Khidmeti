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

// FIX [MANUAL]: _kRetryButtonMinWidth promoted to AppConstants.splashRetryButtonMinWidth
// for single-source-of-truth alignment with other splash constants.
// FIX [AUTO / W3]: _kRetryButtonMinHeight = 48.0 was a magic duplicate of
// AppConstants.buttonHeightMd (48.0). Removed. All usages now reference the
// canonical token directly so there is one source of truth.

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

    // FIX [C1 / MANUAL]: AnimatedSwitcher moved inside SplashBottomStatus
    // (Option B). Previously the AnimatedSwitcher in SplashScreen wrapped
    // SplashBottomStatus as a whole, but since the widget type never changed
    // the switcher had no way to detect transitions — it only fires when the
    // direct child has a different runtime type OR a different key.
    //
    // Moving it inside gives full control: each logical child is given a
    // stable ValueKey so Flutter can detect the state change and play the
    // fade animation on every phase transition. The outer SizedBox in
    // SplashScreen is left plain (no AnimatedSwitcher), which is correct —
    // the height stays constant and only the inner content cross-fades.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _buildContent(context, accent, errorColor),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Color accent,
    Color errorColor,
  ) {
    // ── Error + retry ─────────────────────────────────────────────────────
    if (controller.canRetry) {
      return Column(
        key:          const ValueKey('retry'),
        mainAxisSize: MainAxisSize.min,
        children: [
          // FIX [AUTO / W2]: was `TextStyle(color: errorColor, fontSize:
          // AppConstants.fontSizeSm, fontWeight: FontWeight.w400)` — inline
          // style that bypassed the theme. Now uses textTheme.bodySmall with
          // a color override only, which is the minimum necessary deviation
          // from the theme. bodySmall = 12sp / w400 / Inter — same values,
          // but now theme-driven and inherits future theme changes for free.
          Text(
            _errorMessage(context, controller.errorType),
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: errorColor),
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
                // FIX [AUTO / W3]: was _kRetryButtonMinHeight — removed.
                // AppConstants.buttonHeightMd = 48.0 is the canonical token.
                // FIX [MANUAL]: AppConstants.splashRetryButtonMinWidth replaces
                // the local _kRetryButtonMinWidth = 120.0 magic literal.
                minimumSize: const Size(AppConstants.splashRetryButtonMinWidth, AppConstants.buttonHeightMd),
                // FIX [AUTO / W1]: was radiusMd (12dp) — inconsistent with
                // outlinedButtonTheme global which uses radiusLg (16dp).
                // Swapped to radiusLg for consistency.
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                ),
              ),
              // FIX [AUTO / C1]: was `Theme.of(context).textTheme.labelLarge`
              // without color: null. labelLarge carries color: darkText/lightText
              // which wins over OutlinedButton's foregroundColor: accent via
              // DefaultTextStyle.merge(), making retry text render near-white
              // (dark) or near-black (light) instead of accent indigo.
              // Fix: .copyWith(color: null) clears the text color so the button's
              // foregroundColor: accent is allowed to propagate correctly.
              child: Text(
                context.tr('common.retry'),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(color: null),
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
