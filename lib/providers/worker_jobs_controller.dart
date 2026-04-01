// lib/providers/worker_jobs_controller.dart
//
// FIX (S2): jobActionStatuses: Map<String, JobActionStatus> and
// jobActionErrors: Map<String, String?> removed from WorkerJobsState.
// Any single job action previously triggered a full state copy + rebuild of
// every widget watching this provider (the entire job list).
//
// Per-job loading/error state is now owned by jobActionControllerProvider
// (StateNotifierProvider.autoDispose.family keyed on jobId), mirroring the
// MissionController pattern already used elsewhere in this codebase.
//
// MIGRATION for widgets:
//   OLD: ref.watch(workerJobsControllerProvider).actionStatusFor(jobId)
//   NEW: ref.watch(jobActionControllerProvider(jobId)).status
//
//   OLD: workerJobsController.acceptJob(jobId)
//   NEW: ref.read(jobActionControllerProvider(jobId).notifier).startJob()
//
// The stub methods acceptJob / completeJob / declineJob are kept on this
// controller to avoid a hard compile break during the widget migration window.
// They delegate to the family provider internally.
//
// FIX (P2 — W5): Replaced manual isLoading/errorMessage/jobs triple with
// AsyncValue<List<ServiceRequestEnhancedModel>>. Backward-compatible getters
// (isLoading, errorMessage, jobs) are preserved so UI widgets require no
// changes. filteredJobs, countFor, allJobs now unwrap from AsyncValue.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_request_enhanced_model.dart';
import '../models/message_enums.dart';
import '../utils/logger.dart';
import 'core_providers.dart';
import 'job_action_controller.dart';

// JobActionStatus is now defined in job_action_controller.dart and re-exported
// from there. Re-export here for backward compatibility with existing imports.
export 'job_action_controller.dart' show JobActionStatus, JobActionState, jobActionControllerProvider;

// ============================================================================
// ENUMS
// ============================================================================

enum JobFilter { all, pending, accepted, inProgress, completed }

// ============================================================================
// STATE
// ============================================================================

class WorkerJobsState {
  // FIX (P2 — W5): jobs list, isLoading, and errorMessage are now represented
  // as a single AsyncValue<List<...>>. Backward-compatible getters below mean
  // existing UI widgets continue to work without modification.
  final AsyncValue<List<ServiceRequestEnhancedModel>> jobsAsync;
  final JobFilter activeFilter;
  final bool isRefreshing;

  const WorkerJobsState({
    this.jobsAsync    = const AsyncValue.loading(),
    this.activeFilter = JobFilter.all,
    this.isRefreshing = false,
  });

  // ── Backward-compatible surface ───────────────────────────────────────────

  /// The raw job list; empty while loading or on error.
  List<ServiceRequestEnhancedModel> get jobs =>
      jobsAsync.value ?? const [];

  /// True while the initial stream data has not yet arrived.
  bool get isLoading => jobsAsync is AsyncLoading;

  /// Error message from the last stream failure; null when healthy.
  String? get errorMessage =>
      jobsAsync.asError?.error.toString();

  // ── Alias kept for job_detail_screen.dart ─────────────────────────────────
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

    // Set loading state while re-subscribing.
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

  List<ServiceRequestEnhancedModel> _sortJobs(
      List<ServiceRequestEnhancedModel> jobs) {
    const order = [
      ServiceStatus.bidSelected,
      ServiceStatus.inProgress,
      ServiceStatus.awaitingSelection,
      ServiceStatus.open,
      ServiceStatus.completed,
      ServiceStatus.cancelled,
      ServiceStatus.expired,
    ];
    return List.from(jobs)
      ..sort((a, b) {
        final ia = order.indexOf(a.status);
        final ib = order.indexOf(b.status);
        if (ia == -1 && ib == -1) return b.createdAt.compareTo(a.createdAt);
        if (ia == -1) return 1;
        if (ib == -1) return -1;
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
  //
  // These methods are kept for backward compatibility during the widget
  // migration window. Prefer watching jobActionControllerProvider(jobId)
  // directly for per-job loading state.
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

// keepAlive prevents stream disposal on tab switch.
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
