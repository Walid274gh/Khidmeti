// lib/screens/worker_jobs/job_detail_screen.dart
//
// CHANGES:
//   • JobServiceDetailsContent, JobScheduleContent, JobTimelineContent:
//     context: parameter removed (field deleted from their constructors)
//   • JobCompletedBadge, JobAcceptDeclineRow, JobCompleteBtn:
//     context: parameter removed
//
// [AUTO FIX] job-not-found branch: when job is null (cancelled or deleted),
//   show a user-visible cancellation message and automatically redirect to the
//   worker jobs list after 3 seconds. Previously the branch silently showed a
//   plain text label with no navigation, leaving the worker stuck on a dead
//   screen.

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../models/message_enums.dart';
import '../../models/service_request_enhanced_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../providers/worker_jobs_controller.dart';
import '../../providers/available_requests_controller.dart';
import '../../providers/core_providers.dart';
import 'widgets/job_location_map_sheet.dart';
import 'widgets/job_media_viewer.dart';
import 'widgets/complete_job_dialog.dart';
import 'widgets/job_detail_hero_background.dart';
import 'widgets/job_status_priority_row.dart';
import 'widgets/job_section_card.dart';
import 'widgets/job_client_info_content.dart';
import 'widgets/job_service_details_content.dart';
import 'widgets/job_schedule_content.dart';
import 'widgets/job_pricing_content.dart';
import 'widgets/job_timeline_content.dart';
import 'widgets/job_media_gallery.dart';
import 'widgets/job_location_preview.dart';
import 'widgets/job_detail_fab_row.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  /// [AUTO FIX] Tracks whether a redirect has already been scheduled so we
  /// don't re-schedule on every rebuild while waiting for the timer.
  bool _redirectScheduled = false;

  @override
  void dispose() {
    super.dispose();
  }

  /// [AUTO FIX] Schedule a 3-second redirect to the worker jobs list.
  void _scheduleRedirect() {
    if (_redirectScheduled) return;
    _redirectScheduled = true;

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      context.go(AppRoutes.workerJobs);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final accentColor  = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final jobsState    = ref.watch(workerJobsControllerProvider);
    final ctrl         = ref.read(workerJobsControllerProvider.notifier);
    final availableState = ref.watch(availableRequestsControllerProvider);

    final job =
        jobsState.allJobs.where((j) => j.id == widget.jobId).firstOrNull ??
        availableState.allRequests
            .where((j) => j.id == widget.jobId)
            .firstOrNull;

    // ── [AUTO FIX] Job not found — cancellation message + auto-redirect ──────
    if (job == null) {
      _scheduleRedirect();

      return Scaffold(
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        appBar: AppBar(
          backgroundColor:
              isDark ? AppTheme.darkSurface : Colors.white,
          leading: IconButton(
            icon: const Icon(AppIcons.back),
            onPressed: () => context.go(AppRoutes.workerJobs),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cancel_outlined,
                  size: 64,
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('worker_jobs.job_cancelled_title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('worker_jobs.job_cancelled_message'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('worker_jobs.job_cancelled_redirect_hint'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.workerJobs),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(context.tr('worker_jobs.back_to_jobs')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final actionStatus = ref.watch(jobActionControllerProvider(job.id));
    final isLoading    = actionStatus.isLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned:         true,
              stretch:        true,
              backgroundColor:
                  isDark ? AppTheme.darkSurface : Colors.white,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: Semantics(
                  button: true,
                  label:  context.tr('common.back'),
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.4)
                            : Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcons.back,
                        color: isDark ? Colors.white : Colors.black,
                        size:  20,
                      ),
                    ),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                // FIX [WARN]: was `EdgeInsets.fromLTRB(56, 0, 16, 14)` —
                // magic numbers inline. 56 = paddingXl + paddingLg (leading
                // button clearance); 16 = paddingMd; 14 ≈ spacingSm + spacingXs.
                titlePadding: const EdgeInsets.fromLTRB(
                  AppConstants.paddingXl + AppConstants.paddingLg, // 56dp — leading clearance
                  0,
                  AppConstants.paddingMd,                          // 16dp
                  AppConstants.spacingSm + AppConstants.spacingXs, // 12dp
                ),
                title: Text(
                  job.title,
                  style: const TextStyle(
                    fontSize:   16,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                background: JobDetailHeroBackground(
                  job:         job,
                  isDark:      isDark,
                  accentColor: accentColor,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppConstants.paddingMd,
                  AppConstants.paddingMd,
                  AppConstants.paddingMd,
                  AppConstants.paddingXl +
                      MediaQuery.of(context).padding.bottom +
                      AppConstants.fabClearance,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JobStatusPriorityRow(job: job, isDark: isDark),
                    const SizedBox(height: AppConstants.spacingLg),

                    JobSectionCard(
                      title:     context.tr('worker_jobs.client_info'),
                      icon:      Icons.person_rounded,
                      iconColor: AppTheme.cyanBlue,
                      isDark:    isDark,
                      child:     JobClientInfoContent(job: job, isDark: isDark),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    JobSectionCard(
                      title:     context.tr('worker_jobs.service_details'),
                      icon:      AppTheme.getProfessionIcon(job.serviceType),
                      iconColor: AppTheme.getProfessionColor(job.serviceType, isDark),
                      isDark:    isDark,
                      child: JobServiceDetailsContent(job: job, isDark: isDark),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    JobSectionCard(
                      title:     context.tr('worker_jobs.description'),
                      icon:      Icons.description_outlined,
                      iconColor: accentColor,
                      isDark:    isDark,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppConstants.spacingMd),
                        child: Text(
                          job.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                height: 1.6,
                                color: isDark
                                    ? AppTheme.darkSecondaryText
                                    : AppTheme.lightSecondaryText,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    if (job.mediaUrls.isNotEmpty) ...[
                      JobSectionCard(
                        title:     context.tr('worker_jobs.media_gallery'),
                        icon:      Icons.perm_media_rounded,
                        iconColor: AppTheme.iconViolet,
                        isDark:    isDark,
                        child: JobMediaGallery(
                          urls:        job.mediaUrls,
                          isDark:      isDark,
                          accentColor: accentColor,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                    ],

                    JobSectionCard(
                      title:     context.tr('worker_jobs.schedule'),
                      icon:      Icons.calendar_today_rounded,
                      iconColor: accentColor,
                      isDark:    isDark,
                      child: JobScheduleContent(job: job, isDark: isDark),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    JobSectionCard(
                      title:     context.tr('worker_jobs.location'),
                      icon:      AppIcons.location,
                      iconColor: AppTheme.onlineGreen,
                      isDark:    isDark,
                      child: JobLocationPreview(
                        job:         job,
                        isDark:      isDark,
                        accentColor: accentColor,
                        onOpen: () => JobLocationMapSheet.show(
                          context,
                          latitude:   job.userLatitude,
                          longitude:  job.userLongitude,
                          address:    job.userAddress,
                          clientName: job.userName,
                        ),
                      ),
                    ),

                    if (job.estimatedPrice != null || job.finalPrice != null) ...[
                      const SizedBox(height: AppConstants.spacingMd),
                      JobSectionCard(
                        title:     context.tr('worker_jobs.pricing'),
                        icon:      Icons.payments_rounded,
                        iconColor: accentColor,
                        isDark:    isDark,
                        child:     JobPricingContent(job: job, isDark: isDark),
                      ),
                    ],

                    const SizedBox(height: AppConstants.spacingMd),
                    JobSectionCard(
                      title:     context.tr('worker_jobs.timeline'),
                      icon:      Icons.timeline_rounded,
                      iconColor: AppTheme.cyanBlue,
                      isDark:    isDark,
                      child: JobTimelineContent(job: job, isDark: isDark),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
        floatingActionButton: JobDetailFabRow(
          job:         job,
          isLoading:   isLoading,
          isDark:      isDark,
          accentColor: accentColor,
          userPhone:   job.userPhone,
          onAccept:    () => ctrl.acceptJob(job.id),
          onDecline:   () => _confirmDecline(context, ctrl, job.id),
          onComplete:  () => _showCompleteDialog(context, ctrl, job.id),
        ),
      ),
    );
  }

  Future<void> _showCompleteDialog(
    BuildContext context,
    WorkerJobsController ctrl,
    String jobId,
  ) async {
    final result = await CompleteJobDialog.show(context);
    if (result != null && mounted) {
      await ctrl.completeJob(jobId,
          notes: result.notes, finalPrice: result.price);
    }
  }

  Future<void> _confirmDecline(
    BuildContext context,
    WorkerJobsController ctrl,
    String jobId,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        ),
        title:   Text(context.tr('worker_jobs.decline_confirm_title')),
        content: Text(context.tr('worker_jobs.decline_confirm_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:     Text(context.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.signOutRed),
            child: Text(context.tr('worker_jobs.decline_job')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) ctrl.declineJob(jobId);
  }
}
