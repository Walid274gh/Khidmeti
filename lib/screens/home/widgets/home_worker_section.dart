// lib/screens/home/widgets/home_worker_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/message_enums.dart';
import '../../../models/service_request_enhanced_model.dart';
import '../../../providers/worker_home_controller.dart';
import '../../../providers/worker_jobs_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ── Local constants ────────────────────────────────────────────────────────────
const double _kSectionDividerH = 0.5;
const int    _kMaxNearbyJobs   = 3;

// ============================================================================
// HOME WORKER SECTION
// ============================================================================

class HomeWorkerSection extends ConsumerWidget {
  const HomeWorkerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final workerState  = ref.watch(workerHomeControllerProvider);
    final jobsState    = ref.watch(workerJobsControllerProvider);

    if (workerState.isWorkerLoading) return const SizedBox.shrink();
    if (workerState.isWorkerError)   return const SizedBox.shrink();

    final worker = workerState.worker;
    if (worker == null) return const SizedBox.shrink();

    final isOnline = workerState.isOnline;
    final rating     = worker.averageRating;
    final pending    = jobsState.jobs
        .where((j) => j.status == ServiceStatus.open)
        .take(_kMaxNearbyJobs)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLg),
          child: Container(
            height: _kSectionDividerH,
            color:  isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),

        const SizedBox(height: AppConstants.spacingMd),

        _AvailabilityToggle(
          isDark:   isDark,
          isOnline: isOnline,
          onToggle: () {
            HapticFeedback.mediumImpact();
            ref
                .read(workerHomeControllerProvider.notifier)
                .toggleOnlineStatus();
          },
        ),

        const SizedBox(height: AppConstants.spacingSm),

        _RoiStrip(
          isDark:       isDark,
          rating:       rating,
          monthlyCount: jobsState.jobs.length,
        ),

        const SizedBox(height: AppConstants.spacingSm),

        _DemandBar(
          isDark:       isDark,
          pendingCount: pending.length,
        ),

        if (isOnline && pending.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacingSm),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLg),
            // [W6 FIX]: was TextStyle(fontSize: fontSizeXs, fontWeight: w700, ...)
            // — bypasses textTheme. Replaced with textTheme.labelSmall?.copyWith(...).
            child: Text(
              context.tr('worker_home.nearby_jobs'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight:    FontWeight.w700,
                    color:         isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          ...pending.map(
            (job) => _NearbyJobTile(job: job, isDark: isDark),
          ),
        ],

        const SizedBox(height: AppConstants.spacingMd),
      ],
    );
  }
}

// ── ① Availability toggle ─────────────────────────────────────────────────────

class _AvailabilityToggle extends StatelessWidget {
  final bool       isDark;
  final bool       isOnline;
  final VoidCallback onToggle;

  const _AvailabilityToggle({
    required this.isDark,
    required this.isOnline,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final onColor   = AppTheme.onlineGreen;
    final offColor  = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;
    final dotColor  = isOnline ? onColor : offColor;
    final subtext   = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLg),
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMd,
            vertical:   AppConstants.spacingMd,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              color: isOnline
                  ? onColor.withOpacity(0.30)
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width:  8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [W6 FIX]: was TextStyle(fontSize: fontSizeSm, fontWeight: w700, ...)
                    // Replaced with textTheme.labelLarge?.copyWith(...).
                    Text(
                      isOnline
                          ? context.tr('worker_home.status_online')
                          : context.tr('worker_home.status_offline'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color:      isOnline
                                ? onColor
                                : (isDark
                                    ? AppTheme.darkText
                                    : AppTheme.lightText),
                          ),
                    ),
                    // [W6 FIX]: was TextStyle(fontSize: fontSizeXs, ...)
                    // Replaced with textTheme.labelSmall?.copyWith(...).
                    Text(
                      isOnline
                          ? context.tr('worker_home.status_online_sub')
                          : context.tr('worker_home.status_offline_sub'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: subtext,
                          ),
                    ),
                  ],
                ),
              ),
              _ToggleSwitch(isOn: isOnline, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  final bool isOn;
  final bool isDark;
  const _ToggleSwitch({required this.isOn, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final onColor = AppTheme.onlineGreen;
    final offTrackColor = isDark
        ? AppTheme.darkSurfaceVariant
        : AppTheme.lightSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width:  40,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        color: isOn ? onColor : offTrackColor,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        curve:    Curves.easeInOut,
        alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width:  16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }
}

// ── ② ROI metrics strip ────────────────────────────────────────────────────────

class _RoiStrip extends StatelessWidget {
  final bool   isDark;
  final double rating;
  final int    monthlyCount;

  const _RoiStrip({
    required this.isDark,
    required this.rating,
    required this.monthlyCount,
  });

  @override
  Widget build(BuildContext context) {
    final accent  = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLg),
      child: Row(
        children: [
          _RoiCard(
            isDark:  isDark,
            value:   '$monthlyCount',
            label:   context.tr('worker_home.roi_requests'),
            accent:  accent,
          ),
          const SizedBox(width: AppConstants.spacingXs),
          _RoiCard(
            isDark:  isDark,
            value:   rating.toStringAsFixed(1),
            label:   context.tr('worker_home.roi_rating'),
            accent:  accent,
          ),
          const SizedBox(width: AppConstants.spacingXs),
          _RoiCard(
            isDark:  isDark,
            value:   '#1',
            label:   context.tr('worker_home.roi_rank'),
            accent:  accent,
          ),
        ],
      ),
    );
  }
}

class _RoiCard extends StatelessWidget {
  final bool   isDark;
  final String value;
  final String label;
  final Color  accent;

  const _RoiCard({
    required this.isDark,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingSm,
          vertical:   AppConstants.spacingXs + 4,
        ),
        decoration: BoxDecoration(
          color:        isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            // [W6 FIX]: was TextStyle(fontSize: fontSizeXl, fontWeight: w700, ...)
            // Replaced with textTheme.headlineSmall?.copyWith(...).
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color:      accent,
                  ),
            ),
            SizedBox(height: AppConstants.spacingXxs),
            // [W6 FIX]: was TextStyle(fontSize: fontSizeXs, ...)
            // Replaced with textTheme.labelSmall?.copyWith(...).
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                    height: 1.2,
                  ),
              textAlign: TextAlign.center,
              maxLines:  2,
              overflow:  TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── ③ Demand bar ─────────────────────────────────────────────────────────────

class _DemandBar extends StatelessWidget {
  final bool isDark;
  final int  pendingCount;

  const _DemandBar({required this.isDark, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    final isHigh   = pendingCount >= 4;
    final isMedium = pendingCount >= 1 && pendingCount < 4;
    final barColor = isHigh
        ? AppTheme.recordingRed
        : isMedium
            ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
            : (isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText);
    final fillRatio = (pendingCount / 8.0).clamp(0.0, 1.0);
    final label = isHigh
        ? context.tr('worker_home.demand_high')
        : isMedium
            ? context.tr('worker_home.demand_medium')
            : context.tr('worker_home.demand_low');

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLg),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        decoration: BoxDecoration(
          color:        isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  // [W6 FIX]: was TextStyle(fontSize: fontSizeSm, fontWeight: w700, ...)
                  // Replaced with textTheme.labelLarge?.copyWith(...).
                  child: Text(
                    context.tr('worker_home.demand_title'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color:      isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingSm,
                    vertical:   AppConstants.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color:        barColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  ),
                  // [W6 FIX]: was TextStyle(fontSize: fontSizeXs, fontWeight: w700, ...)
                  // Replaced with textTheme.labelSmall?.copyWith(...).
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color:      barColor,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  Container(
                    height: 4,
                    color:  isDark
                        ? AppTheme.darkBorder
                        : AppTheme.lightBorder,
                  ),
                  FractionallySizedBox(
                    widthFactor: fillRatio,
                    child: Container(height: 4, color: barColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            // [W6 FIX]: was TextStyle(fontSize: fontSizeXs, ...)
            // Replaced with textTheme.labelSmall?.copyWith(...).
            Text(
              '$pendingCount ${context.tr('worker_home.demand_sub')}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ④ Nearby job tile ─────────────────────────────────────────────────────────

class _NearbyJobTile extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool                         isDark;

  const _NearbyJobTile({required this.job, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent  = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final surface = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingLg,
        0,
        AppConstants.paddingLg,
        AppConstants.spacingXs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMd,
          vertical:   AppConstants.spacingMd,
        ),
        decoration: BoxDecoration(
          color:        surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(
            color: accent.withOpacity(0.20),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width:  32,
              height: 32,
              decoration: BoxDecoration(
                color:        accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: Icon(AppIcons.requests, color: accent, size: 16),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [W6 FIX]: was TextStyle(fontSize: fontSizeSm, fontWeight: w700, ...)
                  // Replaced with textTheme.labelLarge?.copyWith(...).
                  Text(
                    job.serviceType.isNotEmpty
                        ? job.serviceType
                        : context.tr('home.filter_all'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color:      isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // [W6 FIX]: was TextStyle(fontSize: fontSizeXs, ...)
                  // Replaced with textTheme.labelSmall?.copyWith(...).
                  Text(
                    job.userAddress.isNotEmpty
                        ? job.userAddress
                        : context.tr('worker_home.location_unknown'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // NEW badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingSm,
                vertical:   AppConstants.spacingXxs,
              ),
              decoration: BoxDecoration(
                color:        AppTheme.recordingRed,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              // [W6 FIX]: was TextStyle(fontSize: 8, ...) — raw sub-threshold value.
              // Replaced with textTheme.labelSmall?.copyWith(...) which maps to
              // 10dp (fontSizeXs token) — smallest legible token in the system.
              child: Text(
                context.tr('worker_home.badge_new'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color:      Colors.white,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
