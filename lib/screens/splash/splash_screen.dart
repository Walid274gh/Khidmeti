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
    // FIX [S1]: moved _brandingAnimationDone = false inside setState so that
    // build() never reads a stale value of the flag between the assignment and
    // the next frame. Previously the reset was outside setState, which meant
    // a lint warning and a theoretical race if build() ran mid-reset.
    setState(() {
      _brandingAnimationDone = false;
    });
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
                  // FIX [MANUAL / W1]: SplashErrorIcon now receives
                  // key: ValueKey(controller.errorType) at the call site.
                  //
                  // Why this matters: AnimatedSwitcher detects child changes
                  // by comparing runtime type AND key. Both branches here are
                  // different types (SplashErrorIcon vs ExcludeSemantics), so
                  // the cross-fade already fires on the error ↔ logo transition.
                  // The ValueKey on SplashErrorIcon additionally forces a
                  // rebuild when errorType changes while already in error state
                  // (e.g. noInternet → serverError after a reconnect attempt),
                  // ensuring the icon and accessibility label always reflect
                  // the latest error without a stale widget surviving the diff.
                  AnimatedSwitcher(
                    duration:       const Duration(milliseconds: 300),
                    switchInCurve:  Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: controller.phase == SplashPhase.error
                        ? SplashErrorIcon(
                            key:       ValueKey(controller.errorType),
                            isDark:    isDark,
                            errorType: controller.errorType,
                          )
                        : ExcludeSemantics(
                            child: SizedBox(
                              key:    const ValueKey('logo'),
                              // FIX [UI4-W]: was 250.0 (off 8dp grid).
                              // AppConstants.splashLogoSize = 248.0 (nearest on-grid).
                              width:  AppConstants.splashLogoSize,
                              height: AppConstants.splashLogoSize,
                              // FIX [AUTO / W3]: was raw string literal
                              // 'assets/splash_static.png' — bypassed the AppAssets
                              // pattern used by every other asset in the codebase.
                              // Now references AppAssets.splashStatic, the single
                              // source of truth declared in constants.dart.
                              child: Image.asset(
                                AppAssets.splashStatic,
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
                  // FIX [UI1-W]: was SizedBox(height: 64) — raw literal.
                  // AppConstants.splashStatusAreaHeight = 64.0 is the
                  // single source of truth shared with SplashBottomStatus.
                  //
                  // FIX [MANUAL / C1]: AnimatedSwitcher removed from here.
                  // It has been moved inside SplashBottomStatus (Option B),
                  // where it can observe keyed children directly and fire
                  // the cross-fade on every phase transition. Keeping it here
                  // was ineffective because SplashBottomStatus never changed
                  // type, so the switcher never triggered.
                  SizedBox(
                    height: AppConstants.splashStatusAreaHeight,
                    child: SplashBottomStatus(
                      controller: controller,
                      isDark:     isDark,
                      onRetry:    () =>
                          ref.read(splashControllerProvider.notifier).retry(),
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
