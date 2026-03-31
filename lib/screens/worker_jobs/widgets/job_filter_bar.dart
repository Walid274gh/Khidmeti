// lib/screens/worker_jobs/widgets/job_filter_bar.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../providers/worker_jobs_controller.dart';
import 'job_filter_chip.dart';

class JobFilterBar extends StatelessWidget {
  final JobFilter activeFilter;
  final Map<JobFilter, int> counts;
  final ValueChanged<JobFilter> onFilterChanged;

  const JobFilterBar({
    super.key,
    required this.activeFilter,
    required this.counts,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppConstants.paddingMd),
        itemCount: JobFilter.values.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppConstants.spacingXs + 2),
        itemBuilder: (context, i) {
          final filter = JobFilter.values[i];
          final isActive = filter == activeFilter;
          final count = counts[filter] ?? 0;

          return JobFilterChip(
            label: _labelFor(context, filter),
            count: count,
            isActive: isActive,
            isDark: isDark,
            accentColor: accentColor,
            onTap: () {
              HapticFeedback.selectionClick();
              onFilterChanged(filter);
            },
          );
        },
      ),
    );
  }

  String _labelFor(BuildContext context, JobFilter filter) {
    switch (filter) {
      case JobFilter.all:
        return context.tr('worker_jobs.filter_all');
      case JobFilter.pending:
        return context.tr('worker_jobs.filter_pending');
      case JobFilter.accepted:
        return context.tr('worker_jobs.filter_accepted');
      case JobFilter.inProgress:
        return context.tr('worker_jobs.filter_in_progress');
      case JobFilter.completed:
        return context.tr('worker_jobs.filter_completed');
    }
  }
}

