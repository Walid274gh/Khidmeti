// lib/screens/worker_jobs/widgets/job_card_header.dart

import 'package:flutter/material.dart';

import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import 'job_status_badge.dart';

class JobCardHeader extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final Color        serviceColor;
  final Color        statusColor;
  final Color        accentColor;
  final bool         isDark;
  final BuildContext context;

  const JobCardHeader({
    super.key,
    required this.job,
    required this.serviceColor,
    required this.statusColor,
    required this.accentColor,
    required this.isDark,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Service icon
        Container(
          width:  46,
          height: 46,
          decoration: BoxDecoration(
            color:  serviceColor.withOpacity(0.15),
            shape:  BoxShape.circle,
            border: Border.all(color: serviceColor.withOpacity(0.25)),
          ),
          child: Icon(
            AppTheme.getProfessionIcon(job.serviceType),
            color: serviceColor,
            size:  22,
          ),
        ),

        const SizedBox(width: AppConstants.spacingMd),

        // Title + client
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                      fontWeight:    FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size:  13,
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    job.userName,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                          fontWeight: FontWeight.w400,  // was w500 — forbidden
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Status badge
        JobStatusBadge(
          status:  job.status,
          color:   statusColor,
          isDark:  isDark,
          context: ctx,
        ),
      ],
    );
  }
}
