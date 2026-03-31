// lib/screens/worker_jobs/widgets/jobs_skeleton_rounded_bar.dart

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

class JobsSkeletonRoundedBar extends StatelessWidget {
  final double width;
  final double height;
  final bool   isDark;
  final double shimmerValue;

  const JobsSkeletonRoundedBar({
    super.key,
    required this.width,
    required this.height,
    required this.isDark,
    this.shimmerValue = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(shimmerValue * 0.08)
            : Colors.black.withOpacity(shimmerValue * 0.07),
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}