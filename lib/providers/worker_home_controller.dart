// lib/providers/worker_home_controller.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/message_enums.dart';
import '../models/service_request_enhanced_model.dart';
import '../models/worker_model.dart';
import '../providers/core_providers.dart';
import '../providers/location_controller.dart';
import '../providers/location_permission_controller.dart';
import '../utils/logger.dart';

// ============================================================================
// WORKER HOME STATE
// ============================================================================

/// Reason the "Go Online" action was blocked.
/// Exposed so the UI can show the specific corrective dialog.
enum GoOnlineBlockReason {
  /// Location app-permission is denied (not permanently).
  permissionDenied,
  /// Location app-permission is permanently denied — user must open Settings.
  permissionPermanentlyDenied,
  /// GPS hardware is switched off — user must enable it in device settings.
  gpsHardwareDisabled,
}

class WorkerHomeState {
  final AsyncValue<WorkerModel> workerAsync;
  final bool isTogglingOnline;
  final List<ServiceRequestEnhancedModel> recentRequests;
  final bool isLoadingRequests;
  final String? requestsError;
  final bool isRefreshing;
  final String? toggleError;
  /// Non-null when Go Online was blocked due to GPS/permission issues.
  final GoOnlineBlockReason? goOnlineBlockReason;

  const WorkerHomeState({
    this.workerAsync = const AsyncValue.loading(),
    this.isTogglingOnline = false,
    this.recentRequests = const [],
    this.isLoadingRequests = false,
    this.requestsError,
    this.isRefreshing = false,
    this.toggleError,
    this.goOnlineBlockReason,
  });

  // Convenience getters.
  int get pendingCount =>
      recentRequests.where((r) => r.status == ServiceStatus.pending).length;

  int get activeCount => recentRequests
      .where((r) =>
          r.status == ServiceStatus.accepted ||
          r.status == ServiceStatus.inProgress)
      .length;

  int get completedCount =>
      recentRequests.where((r) => r.status == ServiceStatus.completed).length;

  WorkerModel? get worker => workerAsync.value;
  bool get isOnline       => worker?.isOnline ?? false;
  bool get isWorkerLoaded  => workerAsync is AsyncData;
  bool get isWorkerLoading => workerAsync is AsyncLoading;
  bool get isWorkerError   => workerAsync is AsyncError;

  WorkerHomeState copyWith({
    AsyncValue<WorkerModel>? workerAsync,
    bool? isTogglingOnline,
    List<ServiceRequestEnhancedModel>? recentRequests,
    bool? isLoadingRequests,
    String? requestsError,
    bool? isRefreshing,
    String? toggleError,
    GoOnlineBlockReason? goOnlineBlockReason,
    bool clearToggleError       = false,
    bool clearRequestsError     = false,
    bool clearGoOnlineBlockReason = false,
  }) {
    return WorkerHomeState(
      workerAsync:       workerAsync       ?? this.workerAsync,
      isTogglingOnline:  isTogglingOnline  ?? this.isTogglingOnline,
      recentRequests:    recentRequests    ?? this.recentRequests,
      isLoadingRequests: isLoadingRequests ?? this.isLoadingRequests,
      requestsError: clearRequestsError
          ? null
          : (requestsError ?? this.requestsError),
      isRefreshing:  isRefreshing ?? this.isRefreshing,
      toggleError:   clearToggleError ? null : (toggleError ?? this.toggleError),
      goOnlineBlockReason: clearGoOnlineBlockReason
          ? null
          : (goOnlineBlockReason ?? this.goOnlineBlockReason),
    );
  }
}

// ============================================================================
// CONTROLLER
// ============================================================================

class WorkerHomeController extends StateNotifier<WorkerHomeState> {
  final Ref _ref;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _workerSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?   _requestsSub;

  WorkerHomeController(this._ref) : super(const WorkerHomeState()) {
    _initialize();
  }

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  /// Attempts to toggle the worker's online status.
  ///
  /// **Enterprise GPS enforcement** — the toggle is COMPLETELY ABORTED if:
  ///   1. The GPS hardware (physical switch) is off.
  ///   2. The app location permission is denied or permanently denied.
  ///
  /// The block reason is stored in [WorkerHomeState.goOnlineBlockReason] so
  /// the UI can show the appropriate dialog ("Turn on GPS" vs "Open Settings").
  Future<void> toggleOnlineStatus() async {
    if (state.isTogglingOnline) return;
    final worker = state.worker;
    if (worker == null) return;

    final newIsOnline = !worker.isOnline;

    // ── GPS / Permission enforcement (only relevant when going ONLINE) ─────
    if (newIsOnline) {
      final blockReason = await _resolveGoOnlineBlockReason();
      if (blockReason != null) {
        AppLogger.warning(
            'WorkerHomeController: Go Online blocked — $blockReason');
        state = state.copyWith(goOnlineBlockReason: blockReason);
        return;
      }
    }

    AppLogger.info(
        'WorkerHomeController: toggling online → $newIsOnline for ${worker.id}');

    state = state.copyWith(
      isTogglingOnline:     true,
      clearToggleError:     true,
      clearGoOnlineBlockReason: true,
    );

    try {
      final Map<String, dynamic> updates = {
        'isOnline':    newIsOnline,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (newIsOnline) {
        // ── Capture fresh GPS coordinates ────────────────────────────────────
        // Force a GPS refresh so the position stored in Firestore reflects
        // where the worker actually is right now, not a stale cached value.
        try {
          final locationNotifier =
              _ref.read(userLocationControllerProvider.notifier);
          await locationNotifier.retryLocation();

          final locationState = _ref.read(userLocationControllerProvider);
          if (locationState.userLocation != null) {
            updates['latitude']  = locationState.userLocation!.latitude;
            updates['longitude'] = locationState.userLocation!.longitude;
            AppLogger.info(
                'WorkerHomeController: GPS captured — '
                '${locationState.userLocation!.latitude}, '
                '${locationState.userLocation!.longitude}');
          }
        } catch (gpsError) {
          // Non-fatal: going online without live coords is still allowed;
          // the native background service will update them shortly.
          AppLogger.warning(
              'WorkerHomeController: GPS refresh failed — '
              'going online without live coords: $gpsError');
        }

        // ── Assign to geographic cell (updates cellId / wilayaCode) ─────────
        try {
          final locState = _ref.read(userLocationControllerProvider);
          if (locState.userLocation != null) {
            final gridService = _ref.read(geographicGridServiceProvider);
            await gridService.assignWorkerToCell(
              workerId:  worker.id,
              latitude:  locState.userLocation!.latitude,
              longitude: locState.userLocation!.longitude,
            );
            AppLogger.info(
                'WorkerHomeController: worker assigned to geographic cell');
          }
        } catch (cellError) {
          AppLogger.warning(
              'WorkerHomeController: geographic cell assignment failed '
              '(non-fatal): $cellError');
        }

        // ── Start native background location service ─────────────────────────
        try {
          final nativeService = _ref.read(nativeChannelServiceProvider);
          await nativeService.startLocationService(
            userId:   worker.id,
            isWorker: true,
          );
          AppLogger.info(
              'WorkerHomeController: background location service started');
        } catch (e) {
          AppLogger.warning(
              'WorkerHomeController: native location service start failed: $e');
        }
      } else {
        // ── Stop native background location service ──────────────────────────
        try {
          final nativeService = _ref.read(nativeChannelServiceProvider);
          await nativeService.stopLocationService();
          AppLogger.info(
              'WorkerHomeController: background location service stopped');
        } catch (e) {
          AppLogger.warning(
              'WorkerHomeController: native location service stop failed: $e');
        }
      }

      await FirebaseFirestore.instance
          .collection('workers')
          .doc(worker.id)
          .update(updates);

      AppLogger.info(
          'WorkerHomeController: online status updated → $newIsOnline');
    } catch (e) {
      AppLogger.error('WorkerHomeController.toggleOnlineStatus', e);
      if (!mounted) return;
      state = state.copyWith(toggleError: e.toString());
    } finally {
      if (mounted) state = state.copyWith(isTogglingOnline: false);
    }
  }

  Future<void> acceptRequest(String requestId) async {
    AppLogger.info('WorkerHomeController: accepting request $requestId');
    await _updateRequestStatus(requestId, ServiceStatus.accepted);
  }

  Future<void> declineRequest(String requestId) async {
    AppLogger.info('WorkerHomeController: declining request $requestId');
    await _updateRequestStatus(requestId, ServiceStatus.declined);
  }

  Future<void> markInProgress(String requestId) async {
    AppLogger.info('WorkerHomeController: marking in-progress $requestId');
    await _updateRequestStatus(requestId, ServiceStatus.inProgress);
  }

  Future<void> markCompleted(String requestId) async {
    AppLogger.info('WorkerHomeController: marking completed $requestId');
    await _updateRequestStatus(
      requestId,
      ServiceStatus.completed,
      completedAt: DateTime.now(),
    );
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true);
    try {
      final worker = state.worker;
      if (worker != null) await _loadRequests(worker.id);
    } finally {
      if (mounted) state = state.copyWith(isRefreshing: false);
    }
  }

  void clearToggleError() =>
      state = state.copyWith(clearToggleError: true);

  void clearGoOnlineBlock() =>
      state = state.copyWith(clearGoOnlineBlockReason: true);

  // --------------------------------------------------------------------------
  // Private — GPS / permission gate
  // --------------------------------------------------------------------------

  /// Returns the [GoOnlineBlockReason] if the current device state prevents
  /// going online, or null if everything is clear.
  ///
  /// Checks are ordered from most-restrictive to least so the returned reason
  /// always reflects the most actionable thing for the user to fix.
  Future<GoOnlineBlockReason?> _resolveGoOnlineBlockReason() async {
    // Re-read latest permission state (it's already reactive, so this is fast).
    final permState =
        _ref.read(locationPermissionControllerProvider);

    // ── Check 1: GPS hardware ────────────────────────────────────────────────
    // We do a live hardware check here rather than relying solely on cached
    // permission-controller state, because the user might have toggled GPS
    // between the last poll and this moment.
    try {
      final locationService = _ref.read(locationServiceProvider);
      final gpsOn = await locationService.isLocationServiceEnabled();
      if (!gpsOn) {
        // Also update the permission controller so its state is coherent.
        _ref
            .read(locationPermissionControllerProvider.notifier)
            .recheck();
        return GoOnlineBlockReason.gpsHardwareDisabled;
      }
    } catch (e) {
      AppLogger.warning(
          'WorkerHomeController: GPS hardware check failed — '
          'blocking as a precaution: $e');
      return GoOnlineBlockReason.gpsHardwareDisabled;
    }

    // ── Check 2: App permission ──────────────────────────────────────────────
    if (permState.needsSettings) {
      return GoOnlineBlockReason.permissionPermanentlyDenied;
    }
    if (!permState.isGranted) {
      return GoOnlineBlockReason.permissionDenied;
    }

    return null; // All clear.
  }

  // --------------------------------------------------------------------------
  // Private — initialisation
  // --------------------------------------------------------------------------

  void _initialize() {
    final authService = _ref.read(authServiceProvider);
    final uid = authService.user?.uid;

    if (uid == null) {
      AppLogger.warning(
          'WorkerHomeController: no authenticated user — aborting');
      state = state.copyWith(
        workerAsync: AsyncValue.error(
            Exception('User not authenticated'), StackTrace.current),
      );
      return;
    }

    AppLogger.info('WorkerHomeController: initialising for uid=$uid');
    _subscribeToWorker(uid);
  }

  void _subscribeToWorker(String uid) {
    _workerSub?.cancel();
    _workerSub = FirebaseFirestore.instance
        .collection('workers')
        .doc(uid)
        .snapshots()
        .listen(
      (doc) {
        if (!mounted) return;
        if (!doc.exists || doc.data() == null) {
          state = state.copyWith(
            workerAsync: AsyncValue.error(
                Exception('Worker profile not found'), StackTrace.current),
          );
          return;
        }
        final worker = WorkerModel.fromMap(doc.data()!, doc.id);
        AppLogger.debug(
            'WorkerHomeController: worker snapshot — online=${worker.isOnline}');
        state = state.copyWith(workerAsync: AsyncValue.data(worker));
        _subscribeToRequests(uid);
      },
      onError: (Object error) {
        AppLogger.error('WorkerHomeController._subscribeToWorker', error);
        if (!mounted) return;
        state = state.copyWith(
          workerAsync: AsyncValue.error(error, StackTrace.current),
        );
      },
    );
  }

  void _subscribeToRequests(String workerId) {
    if (_requestsSub != null) return; // Already subscribed.

    AppLogger.info(
        'WorkerHomeController: subscribing to requests for $workerId');
    state = state.copyWith(
      isLoadingRequests: true,
      clearRequestsError: true,
    );

    _requestsSub = FirebaseFirestore.instance
        .collection('service_requests')
        .where('workerId', isEqualTo: workerId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .listen(
      (snap) {
        if (!mounted) return;
        final requests = snap.docs
            .map((doc) =>
                ServiceRequestEnhancedModel.fromMap(doc.data(), doc.id))
            .toList();
        AppLogger.info(
            'WorkerHomeController: loaded ${requests.length} requests');
        state = state.copyWith(
          recentRequests:    requests,
          isLoadingRequests: false,
        );
      },
      onError: (Object error) {
        AppLogger.error('WorkerHomeController._subscribeToRequests', error);
        if (!mounted) return;
        state = state.copyWith(
          isLoadingRequests: false,
          requestsError:     error.toString(),
        );
      },
    );
  }

  Future<void> _loadRequests(String workerId) async {
    _requestsSub?.cancel();
    _requestsSub = null;
    _subscribeToRequests(workerId);
  }

  Future<void> _updateRequestStatus(
    String requestId,
    ServiceStatus newStatus, {
    DateTime? completedAt,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status':      newStatus.toString(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      if (newStatus == ServiceStatus.accepted) {
        updates['acceptedAt'] = FieldValue.serverTimestamp();
      }
      if (completedAt != null) {
        updates['completedAt'] = Timestamp.fromDate(completedAt);
      }
      await FirebaseFirestore.instance
          .collection('service_requests')
          .doc(requestId)
          .update(updates);
      AppLogger.info(
          'WorkerHomeController: request $requestId → $newStatus');
    } catch (e) {
      AppLogger.error('WorkerHomeController._updateRequestStatus', e);
      rethrow;
    }
  }

  @override
  void dispose() {
    AppLogger.debug('WorkerHomeController: disposing');
    _workerSub?.cancel();
    _requestsSub?.cancel();
    super.dispose();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

// keepAlive() prevents Firestore stream disposal on tab switch.
// The KeepAliveLink is released on sign-out to cancel streams and free
// resources, ensuring a clean state for the next session.
final workerHomeControllerProvider =
    StateNotifierProvider.autoDispose<WorkerHomeController, WorkerHomeState>(
  (ref) {
    final link = ref.keepAlive();
    ref.listen<bool>(isLoggedInProvider, (_, isLoggedIn) {
      if (!isLoggedIn) link.close();
    });
    return WorkerHomeController(ref);
  },
);
