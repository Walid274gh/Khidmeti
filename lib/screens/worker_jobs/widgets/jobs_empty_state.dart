// lib/screens/worker_jobs/widgets/jobs_empty_state.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../providers/worker_jobs_controller.dart';

class JobsEmptyState extends StatelessWidget {
  final JobFilter filter;

  const JobsEmptyState({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    final icon = switch (filter) {
      JobFilter.pending => Icons.pending_actions_rounded,
      JobFilter.accepted => Icons.handshake_outlined,
      JobFilter.inProgress => Icons.engineering_outlined,
      JobFilter.completed => Icons.task_alt_rounded,
      JobFilter.all => Icons.work_off_outlined,
    };

    final titleKey = switch (filter) {
      JobFilter.all => 'worker_jobs.empty_all_title',
      JobFilter.pending => 'worker_jobs.empty_pending_title',
      JobFilter.accepted => 'worker_jobs.empty_accepted_title',
      JobFilter.inProgress => 'worker_jobs.empty_in_progress_title',
      JobFilter.completed => 'worker_jobs.empty_completed_title',
    };

    final subtitleKey = switch (filter) {
      JobFilter.all => 'worker_jobs.empty_all_subtitle',
      JobFilter.pending => 'worker_jobs.empty_pending_subtitle',
      JobFilter.accepted => 'worker_jobs.empty_accepted_subtitle',
      JobFilter.inProgress => 'worker_jobs.empty_in_progress_subtitle',
      JobFilter.completed => 'worker_jobs.empty_completed_subtitle',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: accentColor.withOpacity(0.15)),
              ),
              child: Icon(icon, size: 40, color: accentColor),
            ),
            const SizedBox(height: AppConstants.spacingXl),
            Text(
              context.tr(titleKey),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              context.tr(subtitleKey),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

