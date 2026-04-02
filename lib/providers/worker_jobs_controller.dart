// lib/providers/worker_jobs_controller.dart
//
// FIX (S2): jobActionStatuses / jobActionErrors removed (see full comment below).
//
// FIX (P2 — W5): AsyncValue<List<...>> replaces manual isLoading/errorMessage/jobs.
//
// ALGO FIX: _sortJobs previously called order.indexOf(status) inside the sort
// comparator. indexOf is O(k) per call and comparators are invoked O(n log n)
// times, giving O(k · n log n) total — k=7 status values here. Replaced with
// a precomputed Map<ServiceStatus, int> lookup that is O(1), reducing sort
// complexity to O(n log n) with a small constant.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_request_enhanced_model.dart';
import '../models/message_enums.dart';
import '../utils/logger.dart';
import 'core_providers.dart';
import 'job_action_controller.dart';

export 'job_action_controller.dart' show JobActionStatus, JobActionState, jobActionControllerProvider;

// ============================================================================
// ENUMS
// ============================================================================

enum JobFilter { all, pending, accepted, inProgress, completed }

// ============================================================================
// STATE
// ============================================================================

class WorkerJobsState {
  final AsyncValue<List<ServiceRequestEnhancedModel>> jobsAsync;
  final JobFilter activeFilter;
  final bool isRefreshing;

  const WorkerJobsState({
    this.jobsAsync    = const AsyncValue.loading(),
    this.activeFilter = JobFilter.all,
    this.isRefreshing = false,
  });

  // ── Backward-compatible surface ───────────────────────────────────────────

  List<ServiceRequestEnhancedModel> get jobs =>
      jobsAsync.value ?? const [];

  bool get isLoading => jobsAsync is AsyncLoading;

  String? get errorMessage =>
      jobsAsync.asError?.error.toString();

  List<ServiceRequestEnhancedModel> get allJobs => jobs;

  List<ServiceRequestEnhancedModel> get filteredJobs {
    if (activeFilter == JobFilter.all) return jobs;
    return jobs.where((j) => _matchesFilter(j, activeFilter)).toList();
  }

  bool _matchesFilter(ServiceRequestEnhancedModel job, JobFilter filter) {
    switch (filter) {
      case JobFilter.pending:
        return job.status == ServiceStatus.open ||
            job.status == ServiceStatus.awaitingSelection;
      case JobFilter.accepted:
        return job.status == ServiceStatus.bidSelected;
      case JobFilter.inProgress:
        return job.status == ServiceStatus.inProgress;
      case JobFilter.completed:
        return job.status == ServiceStatus.completed;
      case JobFilter.all:
        return true;
    }
  }

  int countFor(JobFilter filter) {
    if (filter == JobFilter.all) return jobs.length;
    return jobs.where((j) => _matchesFilter(j, filter)).length;
  }

  WorkerJobsState copyWith({
    AsyncValue<List<ServiceRequestEnhancedModel>>? jobsAsync,
    JobFilter? activeFilter,
    bool? isRefreshing,
  }) {
    return WorkerJobsState(
      jobsAsync:    jobsAsync    ?? this.jobsAsync,
      activeFilter: activeFilter ?? this.activeFilter,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

// ============================================================================
// CONTROLLER
// ============================================================================

class WorkerJobsController extends StateNotifier<WorkerJobsState> {
  final Ref _ref;
  StreamSubscription<List<ServiceRequestEnhancedModel>>? _jobsSubscription;
  String? _workerId;

  WorkerJobsController(this._ref) : super(const WorkerJobsState()) {
    _initialize();
  }

  @override
  void dispose() {
    _jobsSubscription?.cancel();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Init
  // --------------------------------------------------------------------------

  void _initialize() {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(
        jobsAsync: AsyncValue.error(
          Exception('worker_not_authenticated'),
          StackTrace.current,
        ),
      );
      return;
    }
    _workerId = user.uid;
    _subscribeToJobs(user.uid);
  }

  void _subscribeToJobs(String workerId) {
    _jobsSubscription?.cancel();

    state = state.copyWith(jobsAsync: const AsyncValue.loading());

    _jobsSubscription = _ref
        .read(firestoreServiceProvider)
        .streamWorkerServiceRequests(workerId)
        .listen(
      (jobs) {
        if (!mounted) return;
        final sorted = _sortJobs(jobs);
        state = state.copyWith(
          jobsAsync:    AsyncValue.data(sorted),
          isRefreshing: false,
        );
        AppLogger.debug('WorkerJobsController: ${jobs.length} jobs');
      },
      onError: (error) {
        AppLogger.error('WorkerJobsController._subscribeToJobs', error);
        if (!mounted) return;
        state = state.copyWith(
          jobsAsync:    AsyncValue.error(error, StackTrace.current),
          isRefreshing: false,
        );
      },
    );
  }

  // FIX: replaced order.indexOf(status) inside sort comparator with a
  // precomputed Map<ServiceStatus, int> lookup.
  //
  // OLD: order.indexOf() is O(k) per call; comparators are called O(n log n)
  //      times → O(k · n log n) total (k=7 status buckets here).
  //
  // NEW: Map lookup is O(1) → O(n log n) with a small constant.
  //      The map is built once per _sortJobs() call (O(k)) and reused
  //      throughout the sort.
  static const List<ServiceStatus> _sortOrder = [
    ServiceStatus.bidSelected,
    ServiceStatus.inProgress,
    ServiceStatus.awaitingSelection,
    ServiceStatus.open,
    ServiceStatus.completed,
    ServiceStatus.cancelled,
    ServiceStatus.expired,
  ];

  // Precomputed at class level: constant cost, never rebuilt.
  static final Map<ServiceStatus, int> _sortRank = {
    for (int i = 0; i < _sortOrder.length; i++) _sortOrder[i]: i,
  };

  List<ServiceRequestEnhancedModel> _sortJobs(
      List<ServiceRequestEnhancedModel> jobs) {
    return List.from(jobs)
      ..sort((a, b) {
        // O(1) map lookup replaces O(k) indexOf.
        final ia = _sortRank[a.status] ?? _sortOrder.length;
        final ib = _sortRank[b.status] ?? _sortOrder.length;
        if (ia != ib) return ia.compareTo(ib);
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  // --------------------------------------------------------------------------
  // Filter
  // --------------------------------------------------------------------------

  void setFilter(JobFilter filter) {
    AppLogger.debug('WorkerJobsController: filter=$filter');
    state = state.copyWith(activeFilter: filter);
  }

  // --------------------------------------------------------------------------
  // Refresh
  // --------------------------------------------------------------------------

  Future<void> refresh() async {
    if (state.isRefreshing || _workerId == null) return;
    state = state.copyWith(isRefreshing: true);
    _subscribeToJobs(_workerId!);

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && state.isRefreshing) {
        state = state.copyWith(isRefreshing: false);
      }
    });
  }

  // --------------------------------------------------------------------------
  // Action stubs — delegate to jobActionControllerProvider family
  // --------------------------------------------------------------------------

  Future<void> acceptJob(String jobId) async {
    await _ref.read(jobActionControllerProvider(jobId).notifier).startJob();
  }

  Future<void> completeJob(
    String jobId, {
    String? notes,
    double? finalPrice,
  }) async {
    await _ref.read(jobActionControllerProvider(jobId).notifier).completeJob(
      notes:      notes,
      finalPrice: finalPrice,
    );
  }

  Future<void> declineJob(String jobId) async {
    await _ref.read(jobActionControllerProvider(jobId).notifier).declineJob();
  }

  void clearJobError(String jobId) =>
      _ref.read(jobActionControllerProvider(jobId).notifier).clearError();
}

// ============================================================================
// PROVIDER
// ============================================================================

final workerJobsControllerProvider =
    StateNotifierProvider.autoDispose<WorkerJobsController, WorkerJobsState>(
  (ref) {
    final link = ref.keepAlive();
    ref.listen<bool>(isLoggedInProvider, (_, isLoggedIn) {
      if (!isLoggedIn) link.close();
    });
    return WorkerJobsController(ref);
  },
);
