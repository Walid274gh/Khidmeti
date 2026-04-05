// lib/screens/worker_jobs/widgets/job_timeline_content.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'job_timeline_step.dart';

// FIX (P1 — Engineer): BuildContext context removed from constructor.
// Storing BuildContext as a field is unsafe — it can go stale between
// builds. The context from build(BuildContext context) is always safe.
class JobTimelineContent extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool isDark;

  const JobTimelineContent({
    super.key,
    required this.job,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM d, HH:mm');

    // FIX [CRITICAL]: was `color: AppTheme.darkAccent` — hardcoded dark token
    // breaks the completed step colour in light theme. Now theme-aware.
    final completedAccent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingMd),
      child: Column(
        children: [
          JobTimelineStep(
            label:       context.tr('worker_jobs.status_pending'),
            date:        dateFormatter.format(job.createdAt),
            isCompleted: true,
            color:       AppTheme.cyanBlue,
            isDark:      isDark,
          ),
          JobTimelineStep(
            label:       context.tr('worker_jobs.status_accepted'),
            date:        job.acceptedAt != null
                ? dateFormatter.format(job.acceptedAt!)
                : '—',
            isCompleted: job.acceptedAt != null,
            color:       AppTheme.onlineGreen,
            isDark:      isDark,
          ),
          JobTimelineStep(
            label:       context.tr('worker_jobs.status_completed'),
            date:        job.completedAt != null
                ? dateFormatter.format(job.completedAt!)
                : '—',
            isCompleted: job.completedAt != null,
            color:       completedAccent,
            isDark:      isDark,
            isLast:      true,
          ),
        ],
      ),
    );
  }
}
