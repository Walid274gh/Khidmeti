// lib/screens/home/widgets/home_skeleton_loading.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

// ─── Mirror real layout dimensions ───────────────────────────────────────────
const double _kBarHeight   = 48.0;
// [W1 FIX]: _kAiBtnHeight 34.0 → 32.0 (8dp-grid snap — mirrors corrected
// real value in advanced_search_bar.dart).
const double _kAiBtnHeight = 32.0;
const double _kCardW       = 72.0;
const double _kCardH       = 80.0;
const double _kCtaH        = 54.0;
// [MANUAL FIX — skeleton bone radius]: was `AppConstants.spacingXs + 2`
// arithmetic (evaluates to 6.0dp) repeated 4× throughout the top bar skeleton.
// Extracted to a named file-local constant for clarity.
// Using 6.0dp rather than 8.0dp (radiusSm) because these are small pill/line
// bones that look visually incorrect at 8dp — design intent preserved.
const double _kBoneRadius  = 6.0;

// ============================================================================
// HOME SKELETON LOADING
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
            ? AppTheme.shimmerBaseDark
            : AppTheme.shimmerBaseLight,
        highlightColor: isDark
            ? AppTheme.shimmerHighlightDark
            : AppTheme.shimmerHighlightLight,
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
          // Wordmark row
          Row(
            children: [
              _Bone(w: 8,  h: 8,  r: 4, circle: true),
              const SizedBox(width: AppConstants.spacingXs + 2),
              _Bone(w: 72, h: 12, r: 4),
              const Spacer(),
              _Bone(w: 38, h: 38, r: 19, circle: true),
            ],
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // Hero question lines — [MANUAL FIX]: was `AppConstants.spacingXs + 2`
          // arithmetic. Replaced with named constant _kBoneRadius (6.0dp).
          _Bone(w: 260, h: 32, r: _kBoneRadius),
          const SizedBox(height: AppConstants.spacingXs),
          _Bone(w: 180, h: 32, r: _kBoneRadius),
          const SizedBox(height: AppConstants.spacingXs),
          _Bone(w: 220, h: 32, r: _kBoneRadius),

          const SizedBox(height: AppConstants.spacingSm),

          // Subtitle line
          _Bone(w: 200, h: 12, r: 4),

          const SizedBox(height: AppConstants.spacingMd),

          // Location row
          Row(
            children: [
              // [MANUAL FIX]: was `AppConstants.spacingXs + 2` → _kBoneRadius
              _Bone(w: 13, h: 13, r: _kBoneRadius, circle: true),
              const SizedBox(width: AppConstants.spacingXs),
              _Bone(w: 160, h: 12, r: 4),
            ],
          ),
        ],
      ),
    );
  }
}

// ── ② + ③ Search section ──────────────────────────────────────────────────────

class _SkeletonSearchSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bone(w: double.infinity, h: _kBarHeight, r: AppConstants.radiusCircle),
          const SizedBox(height: AppConstants.spacingSm),
          _Bone(w: 130, h: _kAiBtnHeight, r: AppConstants.radiusCircle),
        ],
      ),
    );
  }
}

// ── ④ ⑤ ⑥ Services + CTA section ────────────────────────────────────────────

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Bone(w: 90, h: AppConstants.spacingSm, r: 4),
              _Bone(w: 52, h: AppConstants.spacingSm, r: 4),
            ],
          ),

          const SizedBox(height: AppConstants.spacingMd),

          SizedBox(
            height: _kCardH,
            child: ListView.separated(
              scrollDirection:  Axis.horizontal,
              physics:          const NeverScrollableScrollPhysics(),
              itemCount:        5,
              separatorBuilder: (_, __) => const SizedBox(width: AppConstants.spacingChipGap),
              itemBuilder: (_, __) =>
                  _Bone(w: _kCardW, h: _kCardH, r: AppConstants.radiusLg),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingMd),
            child: _Bone(w: double.infinity, h: 1, r: 1),
          ),

          _Bone(w: double.infinity, h: _kCtaH, r: AppConstants.radiusLg),
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
            ? AppTheme.darkText.withOpacity(0.10)
            : AppTheme.lightText.withOpacity(0.07),
        borderRadius: circle ? null : BorderRadius.circular(r),
      ),
    );
  }
}
