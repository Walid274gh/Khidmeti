// lib/screens/worker_jobs/widgets/job_service_details_content.dart

import 'package:flutter/material.dart';

import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'job_info_row.dart';

class JobServiceDetailsContent extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool isDark;
  final BuildContext context;

  const JobServiceDetailsContent({
    super.key,
    required this.job,
    required this.isDark,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingMd),
      child: Column(
        children: [
          JobInfoRow(
            icon: AppTheme.getProfessionIcon(job.serviceType),
            label: ctx.tr('worker_jobs.service_type'),
            value: ctx.tr('services.${job.serviceType}'),
            isDark: isDark,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          JobInfoRow(
            icon: Icons.tag_rounded,
            label: ctx.tr('worker_jobs.request_id'),
            value: '#${job.id.substring(0, 8).toUpperCase()}',
            isDark: isDark,
            mono: true,
          ),
        ],
      ),
    );
  }
}

