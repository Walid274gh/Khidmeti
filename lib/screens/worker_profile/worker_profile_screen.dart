// lib/screens/worker_profile/worker_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/worker_model.dart';
import '../../providers/core_providers.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../utils/whatsapp_launcher.dart';
import '../../widgets/app_user_avatar.dart';

// ============================================================================
// WORKER PROFILE SCREEN — flat Rose hero card, no BackdropFilter, no gradient
// ============================================================================

class WorkerProfileScreen extends ConsumerWidget {
  final String workerId;

  const WorkerProfileScreen({super.key, required this.workerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerAsync = ref.watch(workerProfileProvider(workerId));
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor:        Theme.of(context).colorScheme.surface,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor:        Colors.transparent,
          elevation:              0,
          scrolledUnderElevation: 0,
          leading: Semantics(
            label: context.tr('common.back'),
            child: IconButton(
              icon:      const Icon(AppIcons.back),
              onPressed: () => context.pop(),
              tooltip:   context.tr('common.back'),
            ),
          ),
        ),
        body: workerAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ErrorView(
            onRetry: () => ref.invalidate(workerProfileProvider(workerId)),
          ),
          data: (worker) => worker == null
              ? const _NotFoundView()
              : _ProfileBody(worker: worker, isDark: isDark),
        ),
      ),
    );
  }
}

// ============================================================================
// PRIVATE — PROFILE BODY
// ============================================================================

class _ProfileBody extends ConsumerStatefulWidget {
  final WorkerModel worker;
  final bool        isDark;

  const _ProfileBody({required this.worker, required this.isDark});

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  bool _isContacting = false;

  Future<void> _openWhatsApp() async {
    if (_isContacting) return;
    setState(() => _isContacting = true);
    try {
      final msg = context.tr('whatsapp.contact_message');
      final ok  = await launchWhatsApp(
        phone:   widget.worker.phoneNumber,
        message: msg,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Text(context.tr('whatsapp.open_failed')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isContacting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final worker  = widget.worker;
    final isDark  = widget.isDark;
    final theme   = Theme.of(context);
    final accent  = theme.colorScheme.primary;
    final bgColor =
        isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return CustomScrollView(
      slivers: [
        // ── Hero card ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top:   MediaQuery.of(context).padding.top + kToolbarHeight,
              left:  AppConstants.paddingMd,
              right: AppConstants.paddingMd,
            ),
            child: Container(
              decoration: BoxDecoration(
                color:        accent,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusCircle),
                border: Border.all(
                  color: Colors.white.withOpacity(0.20),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color:      accent.withOpacity(0.35),
                    blurRadius: 24,
                    offset:     const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppConstants.spacingMdLg),
              child: Semantics(
                label:     worker.name,
                container: true,
                child: Row(
                  children: [
                    AppUserAvatar(
                      imageUrl:    worker.profileImageUrl,
                      name:        worker.name,
                      radius:      36,
                      borderColor: Colors.white.withOpacity(0.4),
                      borderWidth: 2,
                    ),
                    const SizedBox(width: AppConstants.paddingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worker.name,
                            style: TextStyle(
                              color:      bgColor,
                              fontSize:   AppConstants.fontSizeXl,
                              fontWeight: FontWeight.w700,
                              shadows: AppTheme.profileCardTextShadow,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('services.${worker.profession}'),
                            style: TextStyle(
                              color:   bgColor.withOpacity(0.75),
                              fontSize: AppConstants.fontSizeSm,
                              shadows: AppTheme.profileCardTextShadow,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingXs),
                          _OnlineBadge(
                              isOnline: worker.isOnline,
                              bgColor:  bgColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Stats + CTA ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppConstants.paddingMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppConstants.spacingLg),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        isDark: isDark,
                        label:  context.tr('worker_preview.rating'),
                        child:  _StarRating(
                          rating: worker.averageRating,
                          count:  worker.ratingCount,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: _StatCard(
                        isDark: isDark,
                        label:  context.tr('worker_preview.reviews'),
                        child: Text(
                          '${worker.ratingCount}',
                          style: TextStyle(
                            fontSize:   AppConstants.fontSizeXxl,
                            fontWeight: FontWeight.w700,
                            color:      accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.spacingXl),

                // ── WhatsApp CTA ──────────────────────────────────────
                Semantics(
                  label:  context.tr('worker_preview.contact_worker'),
                  button: true,
                  child: SizedBox(
                    width:  double.infinity,
                    height: AppConstants.buttonHeight,
                    child: ElevatedButton(
                      onPressed:
                          _isContacting ? null : _openWhatsApp,
                      style: ElevatedButton.styleFrom(
                        // Use AppTheme token for dark surface
                        backgroundColor: isDark
                            ? AppTheme.whatsAppDarkSurface
                            : Colors.white,
                        foregroundColor: kWhatsAppGreen,
                        disabledBackgroundColor: isDark
                            ? AppTheme.whatsAppDarkSurface.withOpacity(0.4)
                            : Colors.white.withOpacity(0.4),
                        elevation: 0,
                        side: BorderSide(
                          color: kWhatsAppGreen.withOpacity(0.55),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppConstants.radiusMd),
                        ),
                      ),
                      child: _isContacting
                          ? const SizedBox(
                              width:  22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color:       kWhatsAppGreen,
                              ),
                            )
                          : Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                // Natural icon — NO color tint
                                WhatsAppIcon(size: 24),
                                const SizedBox(width: 10),
                                Text(
                                  context.tr(
                                      'worker_preview.contact_worker'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color:      kWhatsAppGreen,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.spacingXl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PRIVATE WIDGETS
// ============================================================================

class _OnlineBadge extends StatelessWidget {
  final bool  isOnline;
  final Color bgColor;
  const _OnlineBadge({required this.isOnline, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width:  8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline
                ? AppTheme.onlineGreen
                : bgColor.withOpacity(0.4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          context.tr(
              isOnline ? 'worker_home.online' : 'worker_home.offline'),
          style: TextStyle(
            color:      bgColor.withOpacity(0.85),
            fontSize:   AppConstants.fontSizeXxs,
            fontWeight: FontWeight.w600,
            shadows: AppTheme.profileCardTextShadow,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final bool   isDark;
  final String label;
  final Widget child;

  const _StatCard(
      {required this.isDark, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: AppConstants.spacingXs),
          child,
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  final int    count;

  const _StarRating({required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            final filled = i < rating.floor();
            final half   = !filled && i < rating;
            return Icon(
              half
                  ? Icons.star_half_rounded
                  : filled
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
              size:  18,
              color: accent,
            );
          }),
        ),
        const SizedBox(height: 2),
        Text(
          '${rating.toStringAsFixed(1)} ($count)',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.error,
                size:  64,
                color: theme.colorScheme.error.withOpacity(0.6)),
            const SizedBox(height: AppConstants.paddingMd),
            Text(context.tr('common.error'),
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: AppConstants.spacingLg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh_rounded),
              label: Text(context.tr('common.retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.person,
                size:  64,
                color: theme.colorScheme.outline.withOpacity(0.4)),
            const SizedBox(height: AppConstants.paddingMd),
            Text(context.tr('worker_preview.not_found'),
                style:     theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
