// lib/screens/worker_jobs/job_detail_screen.dart

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
  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    // FIX (Designer): was AppTheme.darkAccent without isDark guard further
    // down. Now derived here and used consistently throughout.
    final accentColor  = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final jobsState    = ref.watch(workerJobsControllerProvider);
    final ctrl         = ref.read(workerJobsControllerProvider.notifier);
    final availableState = ref.watch(availableRequestsControllerProvider);

    final job =
        jobsState.allJobs.where((j) => j.id == widget.jobId).firstOrNull ??
        availableState.allRequests
            .where((j) => j.id == widget.jobId)
            .firstOrNull;

    if (job == null) {
      return Scaffold(
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        appBar: AppBar(
          leading: IconButton(
            // FIX (Engineer): was Icons.arrow_back_rounded → AppIcons.back.
            icon: const Icon(AppIcons.back),
            // FIX (Cross-Screen Flow): was Navigator.pop → context.pop.
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(context.tr('worker_jobs.job_not_found')),
        ),
      );
    }

    final actionStatus = jobsState.actionStatusFor(job.id);
    final isLoading    = actionStatus == JobActionStatus.loading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor:                      Colors.transparent,
        statusBarIconBrightness:             isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:                 isDark ? Brightness.dark  : Brightness.light,
        systemNavigationBarColor:            Colors.transparent,
        systemNavigationBarDividerColor:     Colors.transparent,
        systemNavigationBarIconBrightness:   isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: CustomScrollView(
          slivers: [
            // ── Sliver App Bar ────────────────────────────────────────
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
                    // FIX (Cross-Screen Flow): was Navigator.pop → context.pop.
                    onTap: () => context.pop(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.4)
                            : Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        // FIX (Engineer): was Icons.arrow_back_rounded → AppIcons.back.
                        AppIcons.back,
                        color: isDark ? Colors.white : Colors.black,
                        size:  20,
                      ),
                    ),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
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

            // ── Content ───────────────────────────────────────────────
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
                    // Status + Priority row
                    JobStatusPriorityRow(job: job, isDark: isDark),
                    const SizedBox(height: AppConstants.spacingLg),

                    // Client Info
                    JobSectionCard(
                      title:     context.tr('worker_jobs.client_info'),
                      icon:      Icons.person_rounded,
                      iconColor: AppTheme.cyanBlue,
                      isDark:    isDark,
                      child: JobClientInfoContent(
                          job: job, isDark: isDark),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    // Service Details
                    JobSectionCard(
                      title:     context.tr('worker_jobs.service_details'),
                      icon:      AppTheme.getProfessionIcon(job.serviceType),
                      iconColor: AppTheme.getProfessionColor(
                          job.serviceType, isDark),
                      isDark: isDark,
                      child: JobServiceDetailsContent(
                          job: job, isDark: isDark, context: context),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    // Description
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

                    // Media Gallery
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

                    // Schedule
                    // FIX (Designer): was AppTheme.darkAccent without isDark
                    // guard — in light mode renders dark indigo on white card.
                    JobSectionCard(
                      title:     context.tr('worker_jobs.schedule'),
                      icon:      Icons.calendar_today_rounded,
                      iconColor: accentColor,
                      isDark:    isDark,
                      child: JobScheduleContent(
                          job: job, isDark: isDark, context: context),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    // Location Map Preview
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

                    // Pricing Info (if available)
                    if (job.estimatedPrice != null ||
                        job.finalPrice != null) ...[
                      const SizedBox(height: AppConstants.spacingMd),
                      JobSectionCard(
                        title:     context.tr('worker_jobs.pricing'),
                        icon:      Icons.payments_rounded,
                        iconColor: accentColor,
                        isDark:    isDark,
                        child: JobPricingContent(
                            job: job, isDark: isDark),
                      ),
                    ],

                    // Timeline
                    const SizedBox(height: AppConstants.spacingMd),
                    JobSectionCard(
                      title:     context.tr('worker_jobs.timeline'),
                      icon:      Icons.timeline_rounded,
                      iconColor: AppTheme.cyanBlue,
                      isDark:    isDark,
                      // FIX: JobTimelineContent takes `context:` not `accentColor:`.
                      child: JobTimelineContent(
                          job: job, isDark: isDark, context: context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Floating action row ───────────────────────────────────────
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
        // FIX: JobDetailFabRow takes userPhone/onAccept/onDecline/onComplete —
        // not `ctrl` or `onLocation`. The two helpers below own the dialogs.
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

  // ── Private helpers ─────────────────────────────────────────────────────

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
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.radiusXl),
        ),
        title:   Text(context.tr('worker_jobs.decline_confirm_title')),
        content: Text(context.tr('worker_jobs.decline_confirm_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('common.cancel')),
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
