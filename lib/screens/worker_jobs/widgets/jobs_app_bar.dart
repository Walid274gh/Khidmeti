// lib/screens/worker_jobs/widgets/jobs_app_bar.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class JobsAppBar extends StatelessWidget {
  final bool  isDark;
  final Color accentColor;
  final int   pendingCount;

  const JobsAppBar({
    super.key,
    required this.isDark,
    required this.accentColor,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMd,
        AppConstants.paddingMd,
        AppConstants.paddingMd,
        AppConstants.spacingMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('worker_jobs.screen_title'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight:    FontWeight.w700,   // was w800 — forbidden
                        letterSpacing: -0.5,
                      ),
                ),
                if (pendingCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: AppConstants.spacingXs),
                    child: Row(
                      children: [
                        Container(
                          width:  7,
                          height: 7,
                          decoration: BoxDecoration(
                            color:  accentColor,
                            shape:  BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${context.tr('worker_jobs.pending_awaiting')} ($pendingCount)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color:      accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Jobs badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkSurface
                  : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.work_history_rounded, size: 16, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  context.tr('worker_jobs.my_jobs'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:      accentColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
