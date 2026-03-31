// lib/screens/service_request/widgets/bid_card.dart

import 'package:flutter/material.dart';

import '../../../models/message_enums.dart';
import '../../../models/worker_bid_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// BID CARD
// Displays a single worker bid: avatar, rating, price, message, CTA.
// Pure presentational — all actions delegated via callbacks.
// ============================================================================

class BidCard extends StatelessWidget {
  final WorkerBidModel bid;
  final bool           isDark;
  final bool           isAccepting;
  final VoidCallback   onAccept;

  const BidCard({
    super.key,
    required this.bid,
    required this.isDark,
    required this.isAccepting,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final accent     = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final isAccepted = bid.status == BidStatus.accepted;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface.withOpacity(0.7)
            : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: isAccepted
              ? AppTheme.acceptGreen.withOpacity(0.4)
              : (isDark
                  ? AppTheme.darkCardBorderOverlay
                  : AppTheme.lightCardBorderOverlay),
          width: isAccepted ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Worker info row ─────────────────────────────────────────
            Row(
              children: [
                Container(
                  width:  44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      bid.workerInitials,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color:      accent,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bid.workerName,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(AppIcons.ratingFilled,
                              size: 12, color: AppTheme.warningAmber),
                          const SizedBox(width: 3),
                          Text(
                            bid.workerAverageRating.toStringAsFixed(1),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:      AppTheme.warningAmber,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· ${bid.workerJobsCompleted} ${context.tr('bids.missions')}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.darkSecondaryText
                                      : AppTheme.lightSecondaryText,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${bid.proposedPrice.toStringAsFixed(0)} ${context.tr('common.currency')}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      bid.estimatedDurationLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText,
                          ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Worker message ──────────────────────────────────────────
            if (bid.message != null && bid.message!.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingMd),
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingSm + 2),
                decoration: BoxDecoration(
                  color: (isDark
                          ? AppTheme.darkSurfaceVariant
                          : AppTheme.lightSurfaceVariant)
                      .withOpacity(0.6),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  '"${bid.message}"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color:
                            isDark ? AppTheme.darkText : AppTheme.lightText,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: AppConstants.spacingMd),

            // ── Accept / Selected CTA ───────────────────────────────────
            if (!isAccepted)
              Semantics(
                button:  true,
                label:   context.tr('bids.choose_provider'),
                enabled: !isAccepting,
                child: SizedBox(
                  width:  double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isAccepting ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMd),
                      ),
                    ),
                    child: isAccepting
                        ? const SizedBox(
                            width:  18,
                            height: 18,
                            child:  CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                            context.tr('bids.choose_provider'),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color:      Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                  ),
                ),
              )
            else
              Container(
                width:  double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.acceptGreen.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.check,
                        size: 16, color: AppTheme.acceptGreen),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('bids.selected'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color:      AppTheme.acceptGreen,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BID CARD SKELETON
// Animated shimmer placeholder matching the exact BidCard layout.
// Used in BidsListScreen loading state instead of CircularProgressIndicator.
// ============================================================================

class BidCardSkeleton extends StatefulWidget {
  final bool isDark;
  const BidCardSkeleton({super.key, required this.isDark});

  @override
  State<BidCardSkeleton> createState() => _BidCardSkeletonState();
}

class _BidCardSkeletonState extends State<BidCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shimmer = widget.isDark
        ? AppTheme.darkSurface.withOpacity(0.5)
        : AppTheme.lightSurfaceVariant;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          padding: const EdgeInsets.all(AppConstants.paddingMd),
          decoration: BoxDecoration(
            color: widget.isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              color: widget.isDark
                  ? AppTheme.darkCardBorderOverlay
                  : AppTheme.lightCardBorderOverlay,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width:  44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: shimmer, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width:  120,
                          height: 11,
                          decoration: BoxDecoration(
                            color:        shimmer,
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusXs),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width:  80,
                          height: 9,
                          decoration: BoxDecoration(
                            color:        shimmer,
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusXs),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width:  56,
                    height: 16,
                    decoration: BoxDecoration(
                      color:        shimmer,
                      borderRadius: BorderRadius.circular(AppConstants.radiusXs),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Container(
                width:  double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  color:        shimmer,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
