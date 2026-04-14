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

// Toggle and status-dot dimensions are promoted to AppConstants.
// See constants.dart: toggleTrackW / toggleTrackH / toggleThumbSize / statusDotSize.

// ============================================================================
// HOME WORKER SECTION
// ============================================================================

class HomeWorkerSection extends ConsumerWidget {
  const HomeWorkerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final workerState = ref.watch(workerHomeControllerProvider);
    final jobsState   = ref.watch(workerJobsControllerProvider);

    // FIX (Bug 1b visible): remplacer les SizedBox.shrink() silencieux par des
    // états explicites. L'utilisateur voit désormais un skeleton pendant le
    // chargement et un message d'erreur avec retry en cas d'échec.
    if (workerState.isWorkerLoading) {
      return const _WorkerSectionSkeleton();
    }

    if (workerState.isWorkerError) {
      return _WorkerSectionError(
        isDark:  isDark,
        onRetry: () =>
            ref.read(workerHomeControllerProvider.notifier).refresh(),
      );
    }

    final worker = workerState.worker;
    // Guard défensif : ne devrait pas arriver si AsyncValue est bien géré,
    // mais conservé pour la sécurité du typage.
    if (worker == null) return const SizedBox.shrink();

    final isOnline = workerState.isOnline;
    final rating   = worker.averageRating;
    final pending  = jobsState.jobs
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
  final bool         isDark;
  final bool         isOnline;
  final VoidCallback onToggle;

  const _AvailabilityToggle({
    required this.isDark,
    required this.isOnline,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final onColor  = AppTheme.onlineGreen;
    final offColor = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;
    final dotColor = isOnline ? onColor : offColor;
    final subtext  = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

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
                width:  AppConstants.statusDotSize,
                height: AppConstants.statusDotSize,
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
    final onColor       = AppTheme.onlineGreen;
    final offTrackColor = isDark
        ? AppTheme.darkSurfaceVariant
        : AppTheme.lightSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width:  AppConstants.toggleTrackW,
      height: AppConstants.toggleTrackH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        color: isOn ? onColor : offTrackColor,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        curve:    Curves.easeInOut,
        alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width:  AppConstants.toggleThumbSize,
          height: AppConstants.toggleThumbSize,
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
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

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
          vertical:   AppConstants.spacingSm,
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
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color:      accent,
                  ),
            ),
            SizedBox(height: AppConstants.spacingXxs),
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
              borderRadius: BorderRadius.circular(AppConstants.strengthBarRadius),
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
              width:  AppConstants.iconContainerMd,
              height: AppConstants.iconContainerMd,
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
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingSm,
                vertical:   AppConstants.spacingXxs,
              ),
              decoration: BoxDecoration(
                color:        AppTheme.recordingRed,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: Text(
                context.tr('worker_home.badge_new'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color:      Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ⑤ Loading skeleton ────────────────────────────────────────────────────────

class _WorkerSectionSkeleton extends StatelessWidget {
  const _WorkerSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base   = (isDark ? AppTheme.darkText : AppTheme.lightText)
        .withOpacity(0.08);

    Widget bone({double? width, required double height}) => Container(
          width:  width ?? double.infinity,
          height: height,
          margin: const EdgeInsets.symmetric(vertical: AppConstants.spacingXs),
          decoration: BoxDecoration(
            color:        base,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingLg,
        AppConstants.spacingMd,
        AppConstants.paddingLg,
        AppConstants.spacingMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Divider
          Container(height: _kSectionDividerH, color: base),
          const SizedBox(height: AppConstants.spacingMd),
          // Toggle card
          bone(height: AppConstants.buttonHeight),
          const SizedBox(height: AppConstants.spacingSm),
          // ROI strip — 3 cartes côte à côte
          Row(
            children: [
              Expanded(child: bone(height: 64)),
              const SizedBox(width: AppConstants.spacingXs),
              Expanded(child: bone(height: 64)),
              const SizedBox(width: AppConstants.spacingXs),
              Expanded(child: bone(height: 64)),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          // Demand bar
          bone(height: 80),
          const SizedBox(height: AppConstants.spacingMd),
        ],
      ),
    );
  }
}

// ── ⑥ Error state ─────────────────────────────────────────────────────────────

class _WorkerSectionError extends StatelessWidget {
  final bool         isDark;
  final VoidCallback onRetry;

  const _WorkerSectionError({
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final subtext = isDark
        ? AppTheme.darkSecondaryText
        : AppTheme.lightSecondaryText;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppConstants.spacingLg),
          Icon(
            AppIcons.warning,
            size:  AppConstants.iconSizeLg,
            color: subtext,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            context.tr('worker_home.load_error'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: subtext,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.tr('common.retry')),
          ),
          const SizedBox(height: AppConstants.spacingLg),
        ],
      ),
    );
  }
}
