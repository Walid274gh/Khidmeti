// lib/screens/home/widgets/home_skeleton_loading.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

// ─── Mirror real layout dimensions ───────────────────────────────────────────
const double _kBarHeight   = 48.0;  // matches AdvancedSearchBar pill height
const double _kAiBtnHeight = 34.0;  // matches "Recherche IA" button height
const double _kCardW       = 72.0;  // matches HomeServiceGrid card width
// FIX [CRITICAL]: was 84.0 — mismatched home_service_grid.dart _kCardH (80).
// Layout jank: skeleton cards were 4dp taller than real cards, causing a
// visible height jump when content loaded.
const double _kCardH       = 80.0;  // matches HomeServiceGrid card height
const double _kCtaH        = 54.0;  // matches AppConstants.buttonHeight

// ============================================================================
// HOME SKELETON LOADING
//
// Mirrors the current Home layout exactly:
//   ① Hero top bar — wordmark + 3-line question bones + subtitle + location
//   ② Pill search bar bone (radius 999)
//   ③ "Recherche IA" pill button bone (small, left-aligned)
//   ④ Services label + horizontal cards row
//   ⑤ Divider
//   ⑥ CTA button bone
// ============================================================================

class HomeSkeletonLoading extends StatelessWidget {
  const HomeSkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: Shimmer.fromColors(
        baseColor: isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.black.withOpacity(0.05),
        highlightColor: isDark
            ? Colors.white.withOpacity(0.15)
            : Colors.black.withOpacity(0.10),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SkeletonTopBar(),
                _SkeletonSearchSection(),
                _SkeletonServicesSection(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── ① Hero top bar ────────────────────────────────────────────────────────────
// Mirrors HomeTopBar: wordmark row → 3-line question → subtitle → location row

class _SkeletonTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top:    AppConstants.heroPaddingTop,
        left:   AppConstants.heroPaddingH,
        right:  AppConstants.heroPaddingH,
        bottom: AppConstants.heroPaddingBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wordmark row: dot + name + spacer + notification circle
          Row(
            children: [
              _Bone(w: 8,  h: 8,  r: 4, circle: true),
              const SizedBox(width: 6),
              _Bone(w: 72, h: 13, r: 4),
              const Spacer(),
              _Bone(w: 38, h: 38, r: 19, circle: true),
            ],
          ),

          const SizedBox(height: 24),

          // 3-line question hero — mirrors RichText 38px lines
          _Bone(w: 260, h: 34, r: 6),
          const SizedBox(height: 6),
          _Bone(w: 180, h: 34, r: 6),
          const SizedBox(height: 6),
          _Bone(w: 220, h: 34, r: 6),

          const SizedBox(height: 10),

          // Subtitle line
          _Bone(w: 200, h: 11, r: 4),

          const SizedBox(height: 16),

          // Location row: pin icon + address shimmer
          Row(
            children: [
              _Bone(w: 13, h: 13, r: 6, circle: true),
              const SizedBox(width: 4),
              _Bone(w: 160, h: 11, r: 4),
            ],
          ),
        ],
      ),
    );
  }
}

// ── ② + ③ Search section ──────────────────────────────────────────────────────
// Mirrors AdvancedSearchBar: pill bar + AI button below

class _SkeletonSearchSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pill search bar
          _Bone(w: double.infinity, h: _kBarHeight, r: AppConstants.radiusCircle),

          const SizedBox(height: AppConstants.spacingSm),

          // "Recherche IA" small pill — left-aligned
          _Bone(w: 130, h: _kAiBtnHeight, r: AppConstants.radiusCircle),
        ],
      ),
    );
  }
}

// ── ④ ⑤ ⑥ Services + CTA section ────────────────────────────────────────────
// Mirrors HomeQuickActions: label row → cards → divider → CTA

class _SkeletonServicesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingLg,
        AppConstants.paddingMd,
        AppConstants.paddingLg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label row: "NOS SERVICES" + "Voir tout"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Bone(w: 90,  h: 10, r: 4),
              _Bone(w: 52,  h: 10, r: 4),
            ],
          ),

          const SizedBox(height: AppConstants.spacingSm + 2),

          // Horizontal cards row
          SizedBox(
            height: _kCardH,
            child: ListView.separated(
              scrollDirection:  Axis.horizontal,
              physics:          const NeverScrollableScrollPhysics(),
              itemCount:        5,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) =>
                  _Bone(w: _kCardW, h: _kCardH, r: AppConstants.radiusLg),
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingMd),
            child: _Bone(w: double.infinity, h: 1, r: 1),
          ),

          // CTA button
          _Bone(w: double.infinity, h: _kCtaH, r: 16),
        ],
      ),
    );
  }
}

// ── Bone ──────────────────────────────────────────────────────────────────────

class _Bone extends StatelessWidget {
  final double w;
  final double h;
  final double r;
  final bool   circle;

  const _Bone({
    required this.w,
    required this.h,
    required this.r,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width:  w == double.infinity ? null : w,
      height: h,
      decoration: BoxDecoration(
        shape:        circle ? BoxShape.circle : BoxShape.rectangle,
        color:        isDark
            ? Colors.white.withOpacity(0.10)
            : Colors.black.withOpacity(0.07),
        borderRadius: circle ? null : BorderRadius.circular(r),
      ),
    );
  }
}
