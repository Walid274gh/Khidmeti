// lib/screens/worker_jobs/widgets/jobs_skeleton_card.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import 'jobs_skeleton_bar.dart';
import 'jobs_skeleton_rounded_bar.dart';

class JobsSkeletonCard extends StatelessWidget {
  final bool   isDark;
  // FIX (Performance): shimmerValue replaces Opacity wrapper in the parent.
  // Each Container uses the value directly via withOpacity() — no GPU layer.
  final double shimmerValue;

  const JobsSkeletonCard({
    super.key,
    required this.isDark,
    this.shimmerValue = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    // Base color varies with shimmerValue — replaces the Opacity compositing.
    final shimmer = isDark
        ? Colors.white.withOpacity(shimmerValue * 0.10)
        : Colors.black.withOpacity(shimmerValue * 0.07);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface.withOpacity(0.55)
            : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width:  48,
                height: 48,
                decoration: BoxDecoration(
                  color:  shimmer,
                  shape:  BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JobsSkeletonBar(
                        width: double.infinity, height: 16,
                        isDark: isDark, shimmerValue: shimmerValue),
                    const SizedBox(height: 6),
                    JobsSkeletonBar(
                        width: 110, height: 12,
                        isDark: isDark, shimmerValue: shimmerValue),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              JobsSkeletonRoundedBar(
                  width: 68, height: 24,
                  isDark: isDark, shimmerValue: shimmerValue),
            ],
          ),

          const SizedBox(height: AppConstants.spacingMd),

          JobsSkeletonBar(
              width: double.infinity, height: 12,
              isDark: isDark, shimmerValue: shimmerValue),
          const SizedBox(height: 6),
          JobsSkeletonBar(
              width: 200, height: 12,
              isDark: isDark, shimmerValue: shimmerValue),

          const SizedBox(height: AppConstants.spacingMd),

          Row(
            children: [
              JobsSkeletonRoundedBar(
                  width: 90, height: 24,
                  isDark: isDark, shimmerValue: shimmerValue),
              const SizedBox(width: 6),
              JobsSkeletonRoundedBar(
                  width: 66, height: 24,
                  isDark: isDark, shimmerValue: shimmerValue),
              const SizedBox(width: 6),
              JobsSkeletonRoundedBar(
                  width: 46, height: 24,
                  isDark: isDark, shimmerValue: shimmerValue),
            ],
          ),

          const SizedBox(height: AppConstants.spacingMd),

          Row(
            children: [
              Container(
                width:  36, height: 36,
                decoration: BoxDecoration(color: shimmer, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Container(
                width:  36, height: 36,
                decoration: BoxDecoration(color: shimmer, shape: BoxShape.circle),
              ),
              const Spacer(),
              JobsSkeletonRoundedBar(
                  width: 100, height: 36,
                  isDark: isDark, shimmerValue: shimmerValue),
            ],
          ),
        ],
      ),
    );
  }
}