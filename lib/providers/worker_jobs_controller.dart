// lib/providers/worker_jobs_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_request_enhanced_model.dart';
import '../models/message_enums.dart';
import '../services/worker_bid_service.dart';
import '../services/firestore_service.dart';
import '../utils/logger.dart';
import 'core_providers.dart';

// ============================================================================
// ENUMS  (unchanged interface — widgets depend on these)
// ============================================================================

enum JobFilter { all, pending, accepted, inProgress, completed }

enum JobActionStatus { idle, loading, success, error }

// ============================================================================
// STATE
// ============================================================================

class WorkerJobsState {
  final List<ServiceRequestEnhancedModel> jobs;
  final JobFilter activeFilter;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, JobActionStatus> jobActionStatuses;
  final Map<String, String?> jobActionErrors;
  final bool isRefreshing;

  const WorkerJobsState({
    this.jobs = const [],
    this.activeFilter = JobFilter.all,
    this.isLoading = true,
    this.errorMessage,
    this.jobActionStatuses = const {},
    this.jobActionErrors = const {},
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

  JobActionStatus actionStatusFor(String jobId) =>
      jobActionStatuses[jobId] ?? JobActionStatus.idle;

  String? actionErrorFor(String jobId) => jobActionErrors[jobId];

  WorkerJobsState copyWith({
    List<ServiceRequestEnhancedModel>? jobs,
    JobFilter? activeFilter,
    bool? isLoading,
    String? errorMessage,
    Map<String, JobActionStatus>? jobActionStatuses,
    Map<String, String?>? jobActionErrors,
    bool? isRefreshing,
    bool clearError = false,
  }) {
    return WorkerJobsState(
      jobs: jobs ?? this.jobs,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      jobActionStatuses: jobActionStatuses ?? this.jobActionStatuses,
      jobActionErrors: jobActionErrors ?? this.jobActionErrors,
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
        isLoading: false,
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
        // Clear isRefreshing when stream emits so the pull-to-refresh
        // indicator disappears as soon as Firestore responds.
        state = state.copyWith(
          jobs: sorted,
          isLoading: false,
          isRefreshing: false,
          clearError: true,
        );
        AppLogger.debug('WorkerJobsController: ${jobs.length} jobs');
      },
      onError: (error) {
        AppLogger.error('WorkerJobsController._subscribeToJobs', error);
        if (!mounted) return;
        state = state.copyWith(
          isLoading: false,
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

  // isRefreshing is cleared by the stream listener on the next Firestore
  // emission. A 10-second safety timeout prevents the indicator from hanging
  // forever if Firestore fails to respond.
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
  // Accept Job (Start Job in hybrid model)
  // --------------------------------------------------------------------------

  // In the hybrid bid model, "Accept" is semantically "start the job"
  // (the worker confirms they are starting the work after the client has
  // already accepted their bid). Delegates to WorkerBidService.startJob().
  Future<void> acceptJob(String jobId) async {
    _setJobStatus(jobId, JobActionStatus.loading);
    try {
      await _ref.read(workerBidServiceProvider).startJob(jobId);
      AppLogger.success('WorkerJobsController: started job $jobId');
      if (!mounted) return;
      _setJobStatus(jobId, JobActionStatus.success);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) _setJobStatus(jobId, JobActionStatus.idle);
    } catch (e) {
      AppLogger.error('WorkerJobsController.acceptJob', e);
      if (!mounted) return;
      _setJobStatusError(jobId, e.toString());
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) _setJobStatus(jobId, JobActionStatus.idle);
    }
  }

  // --------------------------------------------------------------------------
  // Complete Job
  // --------------------------------------------------------------------------

  Future<void> completeJob(
    String jobId, {
    String? notes,
    double? finalPrice,
  }) async {
    _setJobStatus(jobId, JobActionStatus.loading);
    try {
      await _ref.read(workerBidServiceProvider).completeJob(
            requestId: jobId,
            workerNotes: notes,
            finalPrice: finalPrice,
          );
      AppLogger.success('WorkerJobsController: completed job $jobId');
      if (!mounted) return;
      _setJobStatus(jobId, JobActionStatus.success);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) _setJobStatus(jobId, JobActionStatus.idle);
    } catch (e) {
      AppLogger.error('WorkerJobsController.completeJob', e);
      if (!mounted) return;
      _setJobStatusError(jobId, e.toString());
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) _setJobStatus(jobId, JobActionStatus.idle);
    }
  }

  // --------------------------------------------------------------------------
  // Decline Job (Cancel after selection in hybrid model)
  // --------------------------------------------------------------------------

  // In the hybrid bid model, "Decline" is semantically "cancel the request
  // after being selected" — the worker backs out of a job they were matched
  // to. Delegates to FirestoreService.cancelRequest().
  Future<void> declineJob(String jobId) async {
    _setJobStatus(jobId, JobActionStatus.loading);
    try {
      await _ref.read(firestoreServiceProvider).cancelRequest(jobId);
      AppLogger.success('WorkerJobsController: declined/cancelled job $jobId');
      if (!mounted) return;
      _setJobStatus(jobId, JobActionStatus.success);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) _setJobStatus(jobId, JobActionStatus.idle);
    } catch (e) {
      AppLogger.error('WorkerJobsController.declineJob', e);
      if (!mounted) return;
      _setJobStatusError(jobId, e.toString());
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) _setJobStatus(jobId, JobActionStatus.idle);
    }
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  void _setJobStatus(String jobId, JobActionStatus status) {
    final updated =
        Map<String, JobActionStatus>.from(state.jobActionStatuses);
    updated[jobId] = status;
    final errors = Map<String, String?>.from(state.jobActionErrors);
    if (status != JobActionStatus.error) errors.remove(jobId);
    state = state.copyWith(
        jobActionStatuses: updated, jobActionErrors: errors);
  }

  void _setJobStatusError(String jobId, String error) {
    final updated =
        Map<String, JobActionStatus>.from(state.jobActionStatuses);
    updated[jobId] = JobActionStatus.error;
    final errors = Map<String, String?>.from(state.jobActionErrors);
    errors[jobId] = error;
    state = state.copyWith(
        jobActionStatuses: updated, jobActionErrors: errors);
  }

  void clearJobError(String jobId) =>
      _setJobStatus(jobId, JobActionStatus.idle);
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
