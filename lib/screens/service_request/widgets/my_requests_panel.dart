// lib/screens/service_request/widgets/my_requests_panel.dart
//
// [C2] FIX: height: 50 (_EmptyState new-request button) →
//      height: AppConstants.buttonHeightMd (48dp).
// [W5] FIX: EdgeInsets.symmetric(horizontal: 14, vertical: 7) on filter chips:
//      vertical: 7dp (off-grid) → AppConstants.chipPaddingV (4dp).
//      horizontal: 14dp kept via AppConstants.spacingTileInner (existing token).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/message_enums.dart';
import '../../../models/service_request_enhanced_model.dart';
import '../../../providers/core_providers.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'request_card.dart';

// ============================================================================
// FILTER ENUM
// ============================================================================

enum _RequestsFilter { all, active, done }



class MyRequestsPanel extends ConsumerStatefulWidget {
  final bool         isDark;
  final Color        accentColor;
  final VoidCallback onNewRequest;

  const MyRequestsPanel({
    super.key,
    required this.isDark,
    required this.accentColor,
    required this.onNewRequest,
  });

  @override
  ConsumerState<MyRequestsPanel> createState() => _MyRequestsPanelState();
}

class _MyRequestsPanelState extends ConsumerState<MyRequestsPanel> {
  _RequestsFilter _filter = _RequestsFilter.all;

  List<ServiceRequestEnhancedModel> _active = [];
  List<ServiceRequestEnhancedModel> _done   = [];
  bool _hasData = false;

  void _updateLists(List<ServiceRequestEnhancedModel> requests) {
    final active = requests
        .where((r) => r.status.isActive)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final done = requests
        .where((r) => r.status.isTerminal)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _active  = active;
      _done    = done;
      _hasData = true;
    });
  }

  List<ServiceRequestEnhancedModel> get _visible {
    return switch (_filter) {
      _RequestsFilter.all    => [..._active, ..._done],
      _RequestsFilter.active => _active,
      _RequestsFilter.done   => _done,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return _EmptyState(
        isDark:       widget.isDark,
        accentColor:  widget.accentColor,
        onNewRequest: widget.onNewRequest,
      );
    }

    final requestsAsync =
        ref.watch(userServiceRequestsStreamProvider(user.uid));

    ref.listen<AsyncValue<List<ServiceRequestEnhancedModel>>>(
      userServiceRequestsStreamProvider(user.uid),
      (_, next) {
        next.whenData(_updateLists);
      },
    );

    return requestsAsync.when(
      loading: () => _LoadingSkeleton(isDark: widget.isDark),
      error: (_, __) => _EmptyState(
        isDark:       widget.isDark,
        accentColor:  widget.accentColor,
        onNewRequest: widget.onNewRequest,
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return _EmptyState(
            isDark:       widget.isDark,
            accentColor:  widget.accentColor,
            onNewRequest: widget.onNewRequest,
          );
        }

        final visible = _visible;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FilterBar(
              isDark:       widget.isDark,
              accentColor:  widget.accentColor,
              current:      _filter,
              onChanged:    (f) => setState(() => _filter = f),
            ),

            Expanded(
              child: visible.isEmpty
                  ? _EmptyFiltered(
                      isDark:      widget.isDark,
                      accentColor: widget.accentColor,
                    )
                  : ListView.builder(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        AppConstants.paddingMd,
                        AppConstants.spacingSm,
                        AppConstants.paddingMd,
                        AppConstants.spacingXl +
                            MediaQuery.of(context).padding.bottom,
                      ),
                      itemCount:   visible.length,
                      itemBuilder: (context, i) {
                        final r = visible[i];
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppConstants.spacingSm),
                          child: RequestCard(
                            request:    r,
                            isDark:     widget.isDark,
                            accentColor: widget.accentColor,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// FILTER BAR
// ============================================================================

class _FilterBar extends StatelessWidget {
  final bool         isDark;
  final Color        accentColor;
  final _RequestsFilter current;
  final ValueChanged<_RequestsFilter> onChanged;

  const _FilterBar({
    required this.isDark,
    required this.accentColor,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final chips = [
      (_RequestsFilter.all,    context.tr('bids.filter_all')),
      (_RequestsFilter.active, context.tr('tracking.filter_active')),
      (_RequestsFilter.done,   context.tr('tracking.filter_done')),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppConstants.paddingMd,
        AppConstants.spacingMd,
        AppConstants.paddingMd,
        AppConstants.spacingXs,
      ),
      child: Row(
        children: chips.map((entry) {
          final (filter, label) = entry;
          final selected = current == filter;
          return Padding(
            padding: const EdgeInsetsDirectional.only(
                end: AppConstants.spacingSm),
            child: Semantics(
              button:   true,
              label:    label,
              selected: selected,
              child: GestureDetector(
                onTap: () => onChanged(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  // [W5] FIX: horizontal: 14 → spacingTileInner (existing 14dp token)
                  //           vertical:   7  → chipPaddingV (4dp, on-grid)
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingTileInner,
                    vertical:   AppConstants.chipPaddingV,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? accentColor.withOpacity(0.12)
                        : (isDark
                            ? AppTheme.darkSurface
                            : AppTheme.lightSurface),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(
                      color: selected
                          ? accentColor.withOpacity(0.5)
                          : (isDark
                              ? AppTheme.darkCardBorderOverlay
                              : AppTheme.lightCardBorderOverlay),
                    ),
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected
                              ? accentColor
                              : (isDark
                                  ? AppTheme.darkSecondaryText
                                  : AppTheme.lightSecondaryText),
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// EMPTY STATES
// ============================================================================

class _EmptyState extends StatelessWidget {
  final bool         isDark;
  final Color        accentColor;
  final VoidCallback onNewRequest;

  const _EmptyState({
    required this.isDark,
    required this.accentColor,
    required this.onNewRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width:  72,
            height: 72,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(AppIcons.requests,
                size: 32, color: accentColor.withOpacity(0.7)),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text(
            context.tr('requests.no_requests'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            context.tr('request_form.subtitle'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingXl),
          Semantics(
            button: true,
            label:  context.tr('requests.new_request'),
            child: GestureDetector(
              onTap: onNewRequest,
              child: Container(
                // [C2] FIX: height: 50 → buttonHeightMd (48dp)
                height: AppConstants.buttonHeightMd,
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppConstants.paddingLg),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color:      accentColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset:     const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.add, size: 18, color: AppTheme.lightText),
                    const SizedBox(width: AppConstants.spacingXs),
                    Text(
                      context.tr('requests.new_request'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color:      AppTheme.lightText,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFiltered extends StatelessWidget {
  final bool  isDark;
  final Color accentColor;

  const _EmptyFiltered(
      {required this.isDark, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        context.tr('requests.no_requests'),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
      ),
    );
  }
}

// ============================================================================
// LOADING SKELETON
// ============================================================================

class _LoadingSkeleton extends StatelessWidget {
  final bool isDark;
  const _LoadingSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final shimmer = isDark
        ? AppTheme.darkSurface.withOpacity(0.5)
        : AppTheme.lightSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width:  56,
            height: 9,
            decoration: BoxDecoration(
              color:        shimmer,
              borderRadius: BorderRadius.circular(AppConstants.radiusXs),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          ...List.generate(
            3,
            (_) => Padding(
              padding:
                  const EdgeInsets.only(bottom: AppConstants.spacingMd),
              child: Container(
                height: 86,
                decoration: BoxDecoration(
                  color:        shimmer,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusLg),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
