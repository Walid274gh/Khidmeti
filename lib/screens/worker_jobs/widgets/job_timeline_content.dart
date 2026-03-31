// lib/screens/worker_jobs/widgets/job_timeline_content.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'job_timeline_step.dart';

class JobTimelineContent extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool isDark;
  final BuildContext context;

  const JobTimelineContent({
    super.key,
    required this.job,
    required this.isDark,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final dateFormatter = DateFormat('MMM d, HH:mm');
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingMd),
      child: Column(
        children: [
          JobTimelineStep(
            label: ctx.tr('worker_jobs.status_pending'),
            date: dateFormatter.format(job.createdAt),
            isCompleted: true,
            color: AppTheme.cyanBlue,
            isDark: isDark,
          ),
          JobTimelineStep(
            label: ctx.tr('worker_jobs.status_accepted'),
            date: job.acceptedAt != null
                ? dateFormatter.format(job.acceptedAt!)
                : '—',
            isCompleted: job.acceptedAt != null,
            color: AppTheme.onlineGreen,
            isDark: isDark,
          ),
          JobTimelineStep(
            label: ctx.tr('worker_jobs.status_completed'),
            date: job.completedAt != null
                ? dateFormatter.format(job.completedAt!)
                : '—',
            isCompleted: job.completedAt != null,
            color: AppTheme.darkAccent,
            isDark: isDark,
            isLast: true,
          ),
        ],
      ),
    );
  }
}