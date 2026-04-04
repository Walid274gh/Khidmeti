// lib/screens/service_request/bids_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/worker_bid_model.dart';
import '../../models/message_enums.dart';
import '../../providers/core_providers.dart';
import '../../providers/client_bids_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import 'widgets/bid_card.dart';


class BidsListScreen extends ConsumerWidget {
  final String requestId;

  const BidsListScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final requestAsync = ref.watch(serviceRequestStreamProvider(requestId));
    final bidsAsync    = ref.watch(bidsStreamProvider(requestId));
    final ctrlState    = ref.watch(clientBidsControllerProvider(requestId));

    // FIX (RW): ref.read(notifier) was captured as a local variable in build().
    // It is now called inline inside each callback so Riverpod never holds a
    // stale notifier reference across rebuilds.

    ref.listen(clientBidsControllerProvider(requestId), (prev, next) {
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        ref
            .read(clientBidsControllerProvider(requestId).notifier)
            .clearError();
      }
      if (next.success && !(prev?.success ?? false)) {
        ref
            .read(clientBidsControllerProvider(requestId).notifier)
            .resetSuccess();
        context.pushReplacement(
          AppRoutes.requestTracking.replaceAll(':id', requestId),
        );
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                    AppConstants.paddingMd,
                    AppConstants.paddingMd,
                    AppConstants.paddingMd,
                    0),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label:  context.tr('common.back'),
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width:  48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withOpacity(0.07),
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusMd),
                          ),
                          child: Icon(AppIcons.back,
                              size:  20,
                              color: isDark
                                  ? AppTheme.darkText
                                  : AppTheme.lightText),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('bids.title'),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          requestAsync.when(
                            data: (req) => req != null
                                ? Text(
                                    '${context.tr('services.${req.serviceType}')} · '
                                    '${req.bidCount} ${context.tr('bids.offers')}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isDark
                                              ? AppTheme.darkSecondaryText
                                              : AppTheme.lightSecondaryText,
                                        ),
                                  )
                                : const SizedBox.shrink(),
                            loading: () => const SizedBox.shrink(),
                            error:   (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // ── Bids list ───────────────────────────────────────────────
              Expanded(
                child: bidsAsync.when(
                  loading: () => ListView.builder(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppConstants.paddingMd,
                      0,
                      AppConstants.paddingMd,
                      AppConstants.spacingMd,
                    ),
                    itemCount:   2,
                    itemBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppConstants.spacingMd),
                      child: BidCardSkeleton(isDark: isDark),
                    ),
                  ),
                  error: (_, __) => Center(
                    child: Text(
                      context.tr('bids.error_loading'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  data: (bids) {
                    final visible = bids
                        .where((b) =>
                            b.status == BidStatus.pending ||
                            b.status == BidStatus.accepted)
                        .toList();

                    if (visible.isEmpty) {
                      return Center(
                        child: Text(
                          context.tr('bids.no_bids_yet'),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: isDark
                                    ? AppTheme.darkSecondaryText
                                    : AppTheme.lightSecondaryText,
                              ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        AppConstants.paddingMd,
                        0,
                        AppConstants.paddingMd,
                        AppConstants.spacingXl +
                            MediaQuery.of(context).padding.bottom,
                      ),
                      itemCount:   visible.length,
                      itemBuilder: (context, i) {
                        final bid = visible[i];
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppConstants.spacingMd),
                          child: BidCard(
                            bid:        bid,
                            isDark:     isDark,
                            isAccepting: ctrlState.isAccepting &&
                                ctrlState.acceptingBidId == bid.id,
                            onAccept: () => ref
                                .read(clientBidsControllerProvider(requestId)
                                    .notifier)
                                .acceptBid(
                                  requestId: requestId,
                                  bid:       bid,
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
