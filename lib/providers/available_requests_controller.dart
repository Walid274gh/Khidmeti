// lib/providers/available_requests_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_request_enhanced_model.dart';
import '../models/worker_bid_model.dart';
import '../models/message_enums.dart';
import '../models/worker_model.dart';
import 'core_providers.dart';

// ============================================================================
// FILTER ENUM
// ============================================================================

enum AvailableRequestsFilter {
  all,
  urgent,
  highBudget,
  noBids,
}

extension AvailableRequestsFilterLabel on AvailableRequestsFilter {
  String label(String Function(String) tr) {
    switch (this) {
      case AvailableRequestsFilter.all:
        return tr('worker_browse.filter_all');
      case AvailableRequestsFilter.urgent:
        return tr('worker_browse.filter_urgent');
      case AvailableRequestsFilter.highBudget:
        return tr('worker_browse.filter_high_budget');
      case AvailableRequestsFilter.noBids:
        return tr('worker_browse.filter_no_bids');
    }
  }
}

// ============================================================================
// STATE
// ============================================================================

class AvailableRequestsState {
  final List<ServiceRequestEnhancedModel> allRequests;
  final AvailableRequestsFilter activeFilter;
  final bool isLoading;
  final String? errorMessage;

  // Maintained by AvailableRequestsController._bidsSub — the set of request
  // IDs where the current worker has a PENDING bid.
  // Widgets call hasMyBid(requestId) instead of opening a second stream.
  final Set<String> pendingBidRequestIds;

  // FIX (Performance): memoized filtered list — recomputed only when
  // allRequests or activeFilter changes, not on pendingBidRequestIds updates.
  final List<ServiceRequestEnhancedModel> _cachedFilteredRequests;
  final AvailableRequestsFilter _cachedFilterKey;

  const AvailableRequestsState({
    this.allRequests = const [],
    this.activeFilter = AvailableRequestsFilter.all,
    this.isLoading = false,
    this.errorMessage,
    this.pendingBidRequestIds = const {},
    List<ServiceRequestEnhancedModel>? cachedFiltered,
    AvailableRequestsFilter? cachedFilterKey,
  })  : _cachedFilteredRequests = cachedFiltered ?? const [],
        _cachedFilterKey = cachedFilterKey ?? AvailableRequestsFilter.all;

  /// Returns true if the current worker already has a pending bid on [requestId].
  bool hasMyBid(String requestId) =>
      pendingBidRequestIds.contains(requestId);

  /// Filtered and sorted list — memoized: re-runs only when allRequests or
  /// activeFilter change, not on every pendingBidRequestIds update.
  List<ServiceRequestEnhancedModel> get filteredRequests {
    // FIX (🔴 Critical — S2-cache-bug):
    // Previous guard: `_cachedFilterKey == activeFilter && _cachedFilteredRequests.isNotEmpty`
    // The isNotEmpty condition caused memoization to fail silently whenever the
    // active filter produced zero results — every subsequent widget rebuild
    // re-ran the full O(n) _computeFiltered() scan even though nothing changed.
    // An empty list is a perfectly valid cached result; the key equality check
    // alone is sufficient to determine cache validity.
    if (_cachedFilterKey == activeFilter) {
      return _cachedFilteredRequests;
    }
    return _computeFiltered();
  }

  List<ServiceRequestEnhancedModel> _computeFiltered() {
    switch (activeFilter) {
      case AvailableRequestsFilter.all:
        return allRequests;
      case AvailableRequestsFilter.urgent:
        return allRequests
            .where((r) => r.priority == ServicePriority.urgent)
            .toList();
      case AvailableRequestsFilter.highBudget:
        return allRequests
            .where((r) => r.budgetMax != null && r.budgetMax! >= 5000)
            .toList()
          ..sort((a, b) =>
              (b.budgetMax ?? 0).compareTo(a.budgetMax ?? 0));
      case AvailableRequestsFilter.noBids:
        return allRequests.where((r) => r.bidCount == 0).toList();
    }
  }

  AvailableRequestsState copyWith({
    List<ServiceRequestEnhancedModel>? allRequests,
    AvailableRequestsFilter? activeFilter,
    bool? isLoading,
    String? errorMessage,
    Set<String>? pendingBidRequestIds,
    bool clearError = false,
    // Internal — set automatically when allRequests or activeFilter changes.
    bool invalidateFilterCache = false,
  }) {
    final newAllRequests   = allRequests ?? this.allRequests;
    final newActiveFilter  = activeFilter ?? this.activeFilter;
    final cacheInvalidated = invalidateFilterCache ||
        allRequests != null ||
        activeFilter != null;

    return AvailableRequestsState(
      allRequests:          newAllRequests,
      activeFilter:         newActiveFilter,
      isLoading:            isLoading ?? this.isLoading,
      errorMessage:         clearError ? null : (errorMessage ?? this.errorMessage),
      pendingBidRequestIds: pendingBidRequestIds ?? this.pendingBidRequestIds,
      cachedFiltered: cacheInvalidated
          ? null // force recompute on next filteredRequests access
          : _cachedFilteredRequests,
      cachedFilterKey: cacheInvalidated ? newActiveFilter : _cachedFilterKey,
    );
  }
}

// ============================================================================
// CONTROLLER
// ============================================================================

class AvailableRequestsController
    extends StateNotifier<AvailableRequestsState> {
  final Ref _ref;
  StreamSubscription<List<ServiceRequestEnhancedModel>>? _requestsSub;
  StreamSubscription<List<WorkerBidModel>>?              _bidsSub;

  WorkerModel? _worker;
  String?      _workerId;

  AvailableRequestsController(this._ref)
      : super(const AvailableRequestsState()) {
    _init();
  }

  Future<void> _init() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    _workerId = userId;

    // FIX (QA P1): was an unguarded async call — a Firestore timeout or
    // network error would crash _init() silently, leaving isLoading: true
    // indefinitely. Now fully wrapped with a user-visible error state.
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      _worker = await firestoreService.getWorker(userId);

      if (_worker == null) {
        if (!mounted) return;
        state = state.copyWith(
          isLoading:    false,
          errorMessage: 'worker_not_found',
        );
        return;
      }

      _subscribeToRequests();
      _subscribeToBids(userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AvailableRequestsController] ERROR in _init: $e');
      }
      if (!mounted) return;
      state = state.copyWith(
        isLoading:    false,
        errorMessage: e.toString(),
      );
    }
  }

  void _subscribeToRequests() {
    if (_worker == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    _requestsSub?.cancel();
    _requestsSub = _ref
        .read(firestoreServiceProvider)
        .streamAvailableRequests(
          wilayaCode:  _worker!.wilayaCode ?? 31,
          serviceType: _worker!.profession,
        )
        .listen(
      (requests) {
        if (!mounted) return;
        state = state.copyWith(
          allRequests: requests,
          isLoading:   false,
          clearError:  true,
          // invalidateFilterCache: true is implicit when allRequests != null
        );
      },
      onError: (e) {
        if (!mounted) return;
        state = state.copyWith(
          isLoading:    false,
          errorMessage: e.toString(),
        );
      },
    );
  }

  void _subscribeToBids(String workerId) {
    _bidsSub?.cancel();
    _bidsSub = _ref
        .read(firestoreServiceProvider)
        .streamWorkerBids(workerId)
        .listen(
      (bids) {
        if (!mounted) return;
        final pendingIds = bids
            .where((b) => b.status == BidStatus.pending)
            .map((b) => b.serviceRequestId)
            .toSet();
        // Only pendingBidRequestIds changes — filteredRequests cache is NOT
        // invalidated, avoiding an unnecessary re-sort of the full list.
        state = state.copyWith(pendingBidRequestIds: pendingIds);
      },
      onError: (e) {
        // Non-fatal: bids stream failure does not block the requests list.
        if (kDebugMode) {
          debugPrint(
              '[AvailableRequestsController] WARNING: bids stream error: $e');
        }
      },
    );
  }

  void setFilter(AvailableRequestsFilter filter) {
    if (!mounted) return;
    state = state.copyWith(activeFilter: filter);
    // invalidateFilterCache is implicit when activeFilter != null
  }

  void refresh() {
    if (_worker == null || _workerId == null) {
      _init();
      return;
    }
    _subscribeToRequests();
    _subscribeToBids(_workerId!);
  }

  @override
  void dispose() {
    _requestsSub?.cancel();
    _bidsSub?.cancel();
    super.dispose();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

final availableRequestsControllerProvider = StateNotifierProvider.autoDispose<
    AvailableRequestsController, AvailableRequestsState>(
  (ref) => AvailableRequestsController(ref),
);
