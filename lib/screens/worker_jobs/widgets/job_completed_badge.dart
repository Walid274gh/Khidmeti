// lib/screens/worker_jobs/widgets/job_completed_badge.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class JobCompletedBadge extends StatelessWidget {
  final bool isDark;

  const JobCompletedBadge({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // [TOKEN FIX]: was 46 — no token; aligned to AppConstants.buttonHeightMd (48).
      height: AppConstants.buttonHeightMd,
      decoration: BoxDecoration(
        color:        AppTheme.onlineGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border:       Border.all(color: AppTheme.onlineGreen.withOpacity(0.3)),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt_rounded, color: AppTheme.onlineGreen, size: 18),
            const SizedBox(width: 8),
            Text(
              context.tr('worker_jobs.job_closed'),
              style: TextStyle(
                color:      AppTheme.onlineGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
