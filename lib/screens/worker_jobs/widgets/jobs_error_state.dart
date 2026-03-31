// lib/screens/worker_jobs/widgets/jobs_error_state.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class JobsErrorState extends StatelessWidget {
  final bool isDark;
  final Color accentColor;
  final VoidCallback onRetry;

  const JobsErrorState({
    super.key,
    required this.isDark,
    required this.accentColor,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.signOutRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.error,
                  size: 36, color: AppTheme.signOutRed),
            ),
            const SizedBox(height: AppConstants.spacingXl),
            Text(
              context.tr('worker_jobs.error_loading'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              context.tr('worker_jobs.error_loading_subtitle'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXl),
            Semantics(
              button: true,
              label: context.tr('common.retry'),
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(context.tr('common.retry')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

