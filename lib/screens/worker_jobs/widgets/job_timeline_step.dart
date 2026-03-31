// lib/screens/worker_jobs/widgets/job_timeline_step.dart
//
// FIX (path comment): was incorrectly declared as
//   lib/screens/worker/ widgets/job_timeline_step.dart
// Corrected to:
//   lib/screens/worker_jobs/widgets/job_timeline_step.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

class JobTimelineStep extends StatelessWidget {
  final String label;
  final String date;
  final bool   isCompleted;
  final Color  color;
  final bool   isDark;
  final bool   isLast;

  const JobTimelineStep({
    super.key,
    required this.label,
    required this.date,
    required this.isCompleted,
    required this.color,
    required this.isDark,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width:  20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? color
                        : color.withOpacity(0.2),
                    shape:  BoxShape.circle,
                    border: Border.all(
                        color: color.withOpacity(0.5), width: 1.5),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check_rounded,
                          color: Colors.black, size: 12)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width:  1.5,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color:  (isDark ? Colors.white : Colors.black)
                          .withOpacity(0.1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppConstants.spacingMd,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: isCompleted
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isCompleted
                              ? (isDark
                                  ? AppTheme.darkText
                                  : AppTheme.lightText)
                              : (isDark
                                  ? AppTheme.darkSecondaryText
                                  : AppTheme.lightSecondaryText),
                        ),
                  ),
                  Text(
                    date,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
