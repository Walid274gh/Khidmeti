// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/home_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/system_ui_overlay.dart';
import 'widgets/advanced_search_bar.dart';
import 'widgets/fullscreen_map_controls.dart';
import 'widgets/home_map_background.dart';
// import 'widgets/home_promo_section.dart'; // disabled — re-enable when ready
import 'widgets/home_quick_actions.dart';
import 'widgets/home_skeleton_loading.dart';
import 'widgets/home_top_bar.dart';

// ============================================================================
// HOME SCREEN
//
// ── Bottom clearance model ────────────────────────────────────────────────────
//
// This screen uses SafeArea(bottom: false) so the background gradient and map
// extend edge-to-edge behind the floating nav bar. Bottom padding is added
// manually at the end of the scroll column.
//
// Formula:
//   bottomClearance = AppConstants.navBarScrollClearance (96dp)
//                   + MediaQuery.viewPaddingOf(context).bottom
//
// navBarScrollClearance breakdown:
//   navBarHeight   (80dp) = navPillHeight(58) + navBarMarginB(10) + navBarBottomGap(12)
//   + spacingMd    (16dp) = breathing room so the last card is not flush
//                           against the pill bottom edge
//   ─────────────────────────────────────────────────────────────────────────
//                 = 96dp
//
// viewPadding.bottom = physical device inset (home indicator / gesture bar).
//   Independent of keyboard and Scaffold nav bar. Typically 0dp on hardware-
//   button Android, 20–34dp on gesture-nav devices and iPhones ≥ X.
//
// ── Why the nav bar overlap was fixed in constants.dart, not here ─────────────
//
// The root cause of the CTA card overlapping the GlassNavigationBar was NOT
// insufficient bottom clearance — it was excessive top padding in the hero
// section pushing all content downward. The fix:
//
//   heroPaddingTop:    38dp → 8dp  (saves 30dp)
//   heroPaddingBottom: 30dp → 8dp  (saves 22dp)
//   total lift = 52dp
//
// This approach is correct because:
//   1. The content block shifts up as a whole — all spacings unchanged.
//   2. The CTA card is visible WITHOUT requiring any scrolling.
//   3. home_screen.dart needs no modification — the fix is purely in the
//      design token layer where it belongs.
//
// [NAV-OVERLAP ROOT CAUSE — now fixed]:
//   The previous code used fabClearance(80dp) which equalled navBarHeight
//   exactly → zero breathing room. On top of that, navBarHeight in constants
//   was stale at 68dp (old fixed-bar era), so fabClearance was already 12dp
//   short of the true nav bar. Combined: last card was 12dp obscured + 0dp gap.
//   Fix: navBarHeight corrected to 80dp in constants.dart; scroll clearance
//   now uses navBarScrollClearance(96dp) which adds the 16dp breathing room.
// ============================================================================

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _transitionCtrl;
  late Animation<double>   _uiFade;
  late Animation<double>   _mapBlur;

  @override
  void initState() {
    super.initState();
    _transitionCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 300),
    );
    _uiFade = CurvedAnimation(
      parent:       _transitionCtrl,
      curve:        Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _mapBlur = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _transitionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeControllerProvider);

    if (homeState.userLocation == null &&
        homeState.locationStatus == HomeLocationStatus.loading) {
      return const HomeSkeletonLoading();
    }

    final isFullscreen = homeState.isMapFullscreen;
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final accent       = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    // navBarScrollClearance(96) + device bottom inset.
    // All tokens live in constants.dart — zero magic numbers in this file.
    final double bottomClearance =
        AppConstants.navBarScrollClearance +
        MediaQuery.viewPaddingOf(context).bottom;

    ref.listen<bool>(
      homeControllerProvider.select((s) => s.isMapFullscreen),
      (_, next) {
        if (next) {
          _transitionCtrl.forward();
          SystemChrome.setSystemUIOverlayStyle(systemOverlayStyle(true));
        } else {
          _transitionCtrl.reverse();
          SystemChrome.setSystemUIOverlayStyle(systemOverlayStyle(isDark));
        }
      },
    );

    return PopScope(
      canPop: !isFullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isFullscreen) {
          ref.read(homeControllerProvider.notifier).exitMapFullscreen();
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: Stack(
          children: [
            // ── LAYER 0 ─────────────────────────────────────────────────────
            // Map always built under the cover, ready for fullscreen instantly.
            const Positioned.fill(child: HomeMapBackground()),

            // ── LAYER 1 ─────────────────────────────────────────────────────
            // Solid cover: hides the map in normal mode, fades on fullscreen.
            AnimatedBuilder(
              animation: _mapBlur,
              builder: (_, __) {
                final coverOpacity = (1.0 - _mapBlur.value).clamp(0.0, 1.0);
                return Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: (isDark
                              ? AppTheme.darkBackground
                              : AppTheme.lightBackground)
                          .withOpacity(coverOpacity),
                    ),
                  ),
                );
              },
            ),

            // ── LAYER 1.5 ────────────────────────────────────────────────────
            // RadialGlow: accent halo centred in the upper third.
            AnimatedBuilder(
              animation: _mapBlur,
              builder: (_, __) {
                final glowOpacity = (1.0 - _mapBlur.value).clamp(0.0, 1.0);
                return Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.0, -0.85),
                          radius: 0.9,
                          colors: [
                            accent.withOpacity(
                              (isDark ? 0.35 : 0.22) * glowOpacity,
                            ),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── LAYER 2 ──────────────────────────────────────────────────────
            // Normal scrollable UI: fades out on fullscreen entry.
            AnimatedBuilder(
              animation: _uiFade,
              builder: (_, child) => IgnorePointer(
                ignoring: isFullscreen,
                child: Opacity(
                  opacity: (1.0 - _uiFade.value).clamp(0.0, 1.0),
                  child: child,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const HomeTopBar(),
                      const AdvancedSearchBar(),
                      const HomeQuickActions(),
                      // const HomePromoSection(), // re-enable when ready

                      // Scroll clearance — keeps last card fully above nav bar.
                      // = navBarScrollClearance(96dp) + device bottom inset.
                      // The actual nav-overlap fix lives in constants.dart:
                      // heroPaddingTop/Bottom were reduced to lift ALL content
                      // upward by 52dp so the CTA card clears the nav bar at rest.
                      SizedBox(height: bottomClearance),
                    ],
                  ),
                ),
              ),
            ),

            // ── LAYER 3 ──────────────────────────────────────────────────────
            // Fullscreen map controls: visible only in fullscreen mode.
            AnimatedBuilder(
              animation: _uiFade,
              builder: (_, child) => IgnorePointer(
                ignoring: !isFullscreen,
                child: Opacity(
                  opacity: _uiFade.value.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
              child: const Align(
                alignment: Alignment.topLeft,
                child: FullscreenMapControls(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
