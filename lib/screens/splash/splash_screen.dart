// lib/screens/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/splash_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/system_ui_overlay.dart';
import 'widgets/splash_bottom_status.dart';
import 'widgets/splash_branding.dart';
import 'widgets/splash_error_icon.dart';

const double _kLogoSize = 250.0;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {

  // FIX (Architect): the minimum duration timer and its associated flags
  // (_minDurationElapsed, _navigationTriggered, _armMinDurationTimer,
  // _checkNavigationReady) have been moved to SplashController. The screen
  // now tracks ONLY the UI-owned flag — whether the branding animation has
  // finished — and reports it directly to the controller.
  bool _brandingAnimationDone = false;

  // FIX [S6]: retry counter used as a key discriminator for SplashBranding.
  // Each call to retry() increments this counter, which forces Flutter to
  // destroy and re-create the SplashBranding widget — replaying the animation.
  // Without this, retrying after an error leaves _brandingAnimationDone=true
  // on the controller (preserved by [S1]) but the widget tree is the same
  // object, so onAnimationComplete() never fires a second time.
  int _retryCount = 0;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FlutterNativeSplash.remove();
      ref.read(splashControllerProvider.notifier).initialize();
    });
  }

  // ── Gate ──────────────────────────────────────────────────────────────────

  void _onBrandingAnimationComplete() {
    if (!mounted) return;
    _brandingAnimationDone = true;
    // Delegate directly — the controller now owns the full gate logic
    // (animation done AND min duration elapsed AND auth checked).
    ref.read(splashControllerProvider.notifier).onAnimationComplete();
  }

  void _resetGate() {
    // FIX [S6]: increment _retryCount so SplashBranding gets a new UniqueKey
    // and Flutter rebuilds it from scratch, re-triggering the animation.
    // _brandingAnimationDone is intentionally NOT reset here — the controller's
    // [S1] fix will already have preserved _isAnimationComplete=true when the
    // animation completed before the error. The two fixes work together:
    //   • [S1] in controller: if animation was done, keep the gate open.
    //   • [S6] in screen: if animation was NOT done, force a fresh widget so
    //     the animation fires again and the gate can be opened.
    if (!_brandingAnimationDone) {
      setState(() => _retryCount++);
    }
    // Always reset the local tracking flag so the screen stays consistent.
    _brandingAnimationDone = false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // MUST be pixel-identical to flutter_native_splash.yaml color/color_dark.
    final backgroundColor =
        isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    ref.listen<SplashState>(splashControllerProvider, (prev, next) {
      if (prev?.phase == SplashPhase.error &&
          next.phase  == SplashPhase.initializing &&
          mounted) {
        _resetGate();
      }
    });

    final controller = ref.watch(splashControllerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ── Logo / error icon ──────────────────────────────────
                  AnimatedSwitcher(
                    duration:       const Duration(milliseconds: 300),
                    switchInCurve:  Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: controller.phase == SplashPhase.error
                        ? SplashErrorIcon(
                            isDark:    isDark,
                            errorType: controller.errorType,
                          )
                        : ExcludeSemantics(
                            child: SizedBox(
                              key:    const ValueKey('logo'),
                              width:  _kLogoSize,
                              height: _kLogoSize,
                              child: Image.asset(
                                'assets/splash_static.png',
                                fit: BoxFit.contain,
                              )
                              .animate()
                              .scale(
                                begin:    const Offset(0.82, 0.82),
                                end:      const Offset(1.00, 1.00),
                                delay:    0.ms,
                                duration: 400.ms,
                                curve:    Curves.easeOut,
                              )
                              .fadeIn(
                                delay:    0.ms,
                                duration: 400.ms,
                                curve:    Curves.easeOut,
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: AppConstants.spacingXl),

                  // ── Branding ───────────────────────────────────────────
                  // FIX [S6]: ValueKey built from _retryCount forces Flutter
                  // to destroy + re-create SplashBranding on each retry, so
                  // the animation replays and onAnimationComplete() fires again.
                  // On the first render _retryCount=0, so the key is stable and
                  // the widget is never needlessly rebuilt during normal flow.
                  SplashBranding(
                    key:                 ValueKey('branding_$_retryCount'),
                    isDark:              isDark,
                    onAnimationComplete: _onBrandingAnimationComplete,
                  ),

                  const SizedBox(height: AppConstants.spacingXl),

                  // ── Bottom status ──────────────────────────────────────
                  SizedBox(
                    height: 64,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: SplashBottomStatus(
                        controller: controller,
                        isDark:     isDark,
                        onRetry:    () =>
                            ref.read(splashControllerProvider.notifier).retry(),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
