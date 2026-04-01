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
  final List<ServiceRequestEnhancedModel> jobs;
  final JobFilter activeFilter;
  final bool isLoading;
  final String? errorMessage;
  final bool isRefreshing;

  const WorkerJobsState({
    this.jobs         = const [],
    this.activeFilter = JobFilter.all,
    this.isLoading    = true,
    this.errorMessage,
    this.isRefreshing = false,
  });

  /// Alias kept for job_detail_screen.dart: `jobsState.allJobs.where(...)`.
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
    List<ServiceRequestEnhancedModel>? jobs,
    JobFilter? activeFilter,
    bool? isLoading,
    String? errorMessage,
    bool? isRefreshing,
    bool clearError = false,
  }) {
    return WorkerJobsState(
      jobs:         jobs         ?? this.jobs,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoading:    isLoading    ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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
        isLoading:    false,
        errorMessage: 'worker_not_authenticated',
      );
      return;
    }
    _workerId = user.uid;
    _subscribeToJobs(user.uid);
  }

  void _subscribeToJobs(String workerId) {
    _jobsSubscription?.cancel();

    _jobsSubscription = _ref
        .read(firestoreServiceProvider)
        .streamWorkerServiceRequests(workerId)
        .listen(
      (jobs) {
        if (!mounted) return;
        final sorted = _sortJobs(jobs);
        state = state.copyWith(
          jobs:         sorted,
          isLoading:    false,
          isRefreshing: false,
          clearError:   true,
        );
        AppLogger.debug('WorkerJobsController: ${jobs.length} jobs');
      },
      onError: (error) {
        AppLogger.error('WorkerJobsController._subscribeToJobs', error);
        if (!mounted) return;
        state = state.copyWith(
          isLoading:    false,
          isRefreshing: false,
          errorMessage: error.toString(),
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
