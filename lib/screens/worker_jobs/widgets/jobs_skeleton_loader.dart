// lib/screens/worker_jobs/widgets/jobs_skeleton_loader.dart

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import 'jobs_skeleton_card.dart';

class JobsSkeletonLoader extends StatefulWidget {
  const JobsSkeletonLoader({super.key});

  @override
  State<JobsSkeletonLoader> createState() => _JobsSkeletonLoaderState();
}

class _JobsSkeletonLoaderState extends State<JobsSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double>   _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _shimmerAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // FIX (Performance — P1): was Opacity(opacity: _shimmerAnim.value, child: ...)
    // Opacity widget < 1.0 forces a composited layer and alpha-blends the
    // entire subtree on every frame — equivalent to BackdropFilter cost.
    // Fix: pass the animation value directly to JobsSkeletonCard so each
    // leaf Container uses color.withOpacity(value) — no compositing layer.
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMd),
          child: Column(
            children: List.generate(
              4,
              (i) => Padding(
                padding: EdgeInsets.only(
                  bottom: i < 3 ? AppConstants.spacingMd : 0,
                ),
                child: JobsSkeletonCard(
                  isDark:        isDark,
                  shimmerValue:  _shimmerAnim.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}