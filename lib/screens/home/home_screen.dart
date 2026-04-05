// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/home_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/system_ui_overlay.dart';          // NEW
import 'widgets/advanced_search_bar.dart';
import 'widgets/fullscreen_map_controls.dart';
import 'widgets/home_map_background.dart';
import 'widgets/home_promo_section.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/home_skeleton_loading.dart';
import 'widgets/home_top_bar.dart';

// ============================================================================
// HOME SCREEN
//
// Changes vs previous version:
//   • HomeWorkerSection is NO LONGER embedded inline in the scroll.
//     Workers access their space via the "Vous" story chip in HomeServiceGrid
//     → WorkerStoryModal (full-screen page, slide-up animation).
//   • HomePromoSection is now shown to ALL users (clients AND workers).
//     Workers used to miss the promo content — fixed.
//   • Removed: import user_role_provider, import home_worker_section,
//     the Consumer block with isWorker check, and the conditional rendering.
//   • SystemUiOverlayStyle blocks replaced with systemOverlayStyle() from
//     utils/system_ui_overlay.dart — eliminates the duplicated 14-line block.
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
      // [W6 FIX]: was 420ms — exceeds the 300ms page-transition standard.
      // Reduced to 300ms for snappier, industry-standard feel on device.
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

    // Cold-start skeleton — wait for location to resolve
    if (homeState.userLocation == null &&
        homeState.locationStatus == HomeLocationStatus.loading) {
      return const HomeSkeletonLoading();
    }

    final isFullscreen = homeState.isMapFullscreen;
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final accent       = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    // FIX (SystemChrome): always stay in SystemUiMode.edgeToEdge so the
    // status bar icons remain visible in both normal and fullscreen modes.
    // systemOverlayStyle() centralises the brightness logic — no duplication.
    //
    // In fullscreen we override icon brightness to Brightness.light because
    // the map background is always dark. On exit we restore the theme-derived
    // style via systemOverlayStyle(isDark).
    ref.listen<bool>(
      homeControllerProvider.select((s) => s.isMapFullscreen),
      (_, next) {
        if (next) {
          _transitionCtrl.forward();
          // Map is always dark → force light (white) status-bar icons.
          SystemChrome.setSystemUIOverlayStyle(
            systemOverlayStyle(true), // true = treat as dark bg
          );
        } else {
          _transitionCtrl.reverse();
          // Restore theme-appropriate icon brightness.
          SystemChrome.setSystemUIOverlayStyle(
            systemOverlayStyle(isDark),
          );
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
            // Map: مُبنية دائماً تحت الغطاء، جاهزة للـ fullscreen فوراً.
            const Positioned.fill(child: HomeMapBackground()),

            // ── LAYER 1 ─────────────────────────────────────────────────────
            // Solid cover: غطاء صلب opacity=1.0 يخفي الخريطة تماماً في
            // الوضع العادي. يحل مشكلة الشاشة الرمادية أثناء بناء الخريطة.
            // يتلاشى فقط عند الدخول للـ fullscreen.
            AnimatedBuilder(
              animation: _mapBlur,
              builder: (_, __) {
                final coverOpacity =
                    (1.0 - _mapBlur.value).clamp(0.0, 1.0);
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
            // RadialGlow: هالة الأكسنت مركّزة في الثلث العلوي من الشاشة.
            AnimatedBuilder(
              animation: _mapBlur,
              builder: (_, __) {
                final glowOpacity =
                    (1.0 - _mapBlur.value).clamp(0.0, 1.0);
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
            // Normal scrollable UI: يتلاشى عند الدخول للـ fullscreen.
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
                    children: const [
                      HomeTopBar(),
                      AdvancedSearchBar(),
                      HomeQuickActions(),
                      HomePromoSection(),
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),

            // ── LAYER 3 ──────────────────────────────────────────────────────
            // Fullscreen map controls: يظهر عند الدخول للـ fullscreen.
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
