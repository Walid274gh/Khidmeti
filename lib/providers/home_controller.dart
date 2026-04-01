// lib/providers/home_controller.dart
//
// TASK 2 FIX — Removed direct FirebaseFirestore.instance usage.
//
// WHAT CHANGED:
//   • _subscribeToNearbyWorkers(): replaced the inline Firestore query
//     (FirebaseFirestore.instance.collection(workersCollection).where(...))
//     with firestoreServiceProvider.streamOnlineWorkersByWilayas(allCodes).
//   • _subscribeFallback(): replaced the inline Firestore query with
//     firestoreServiceProvider.streamOnlineWorkersUnscoped(limit: ...).
//   • _workersStreamSub type: QuerySnapshot<...> → List<WorkerModel>.
//   • _processWorkerSnapshot() → _filterAndSortWorkers(): same distance-
//     filter + sort logic, but now operates on List<WorkerModel> (the typed
//     result from the service) instead of a raw QuerySnapshot. WorkerModel
//     parsing is now the service's responsibility.
//   • Removed: `import 'package:cloud_firestore/cloud_firestore.dart'` —
//     no longer needed since the controller holds no Firestore type references.
//   • Removed: `import '../services/firestore_service.dart'` — workersCollection
//     constant was only needed for the inline queries; the service encapsulates it.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/worker_model.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import '../utils/model_extensions.dart';
import 'core_providers.dart';
import 'location_controller.dart';
import 'location_permission_controller.dart';


// ============================================================================
// STATE
// ============================================================================

enum HomeLocationStatus { idle, loading, loaded, denied, gpsDisabled, error }

class HomeState {
  final HomeLocationStatus locationStatus;
  final LatLng? userLocation;
  final String? userAddress;
  final List<WorkerModel> nearbyWorkers;
  final bool isLoadingWorkers;
  final String? workersError;
  final bool isMapFullscreen;
  final String? activeServiceFilter;
  final bool isRefreshing;
  final bool isWorkersStreamInitialising;
  final String? bestWorkerId;

  const HomeState({
    this.locationStatus = HomeLocationStatus.idle,
    this.userLocation,
    this.userAddress,
    this.nearbyWorkers = const [],
    this.isLoadingWorkers = false,
    this.workersError,
    this.isMapFullscreen = false,
    this.activeServiceFilter,
    this.isRefreshing = false,
    this.isWorkersStreamInitialising = false,
    this.bestWorkerId,
  });

  int get workerCountForFilter => activeServiceFilter == null
      ? nearbyWorkers.length
      : nearbyWorkers
          .where((w) => w.profession == activeServiceFilter)
          .length;

  List<WorkerModel> get filteredWorkers => activeServiceFilter == null
      ? nearbyWorkers
      : nearbyWorkers
          .where((w) => w.profession == activeServiceFilter)
          .toList();

  HomeState copyWith({
    HomeLocationStatus? locationStatus,
    LatLng? userLocation,
    String? userAddress,
    List<WorkerModel>? nearbyWorkers,
    bool? isLoadingWorkers,
    String? workersError,
    bool? isMapFullscreen,
    String? activeServiceFilter,
    bool? isRefreshing,
    bool? isWorkersStreamInitialising,
    String? bestWorkerId,
    bool clearLocation = false,
    bool clearFilter = false,
    bool clearWorkersError = false,
    bool clearAddress = false,
    bool clearBestWorker = false,
  }) {
    return HomeState(
      locationStatus:   locationStatus   ?? this.locationStatus,
      userLocation:     clearLocation ? null : (userLocation ?? this.userLocation),
      userAddress:      clearAddress  ? null : (userAddress  ?? this.userAddress),
      nearbyWorkers:    nearbyWorkers    ?? this.nearbyWorkers,
      isLoadingWorkers: isLoadingWorkers ?? this.isLoadingWorkers,
      workersError:     clearWorkersError
          ? null
          : (workersError ?? this.workersError),
      isMapFullscreen:  isMapFullscreen  ?? this.isMapFullscreen,
      activeServiceFilter: clearFilter
          ? null
          : (activeServiceFilter ?? this.activeServiceFilter),
      isRefreshing:    isRefreshing    ?? this.isRefreshing,
      isWorkersStreamInitialising:
          isWorkersStreamInitialising ?? this.isWorkersStreamInitialising,
      bestWorkerId: clearBestWorker ? null : (bestWorkerId ?? this.bestWorkerId),
    );
  }
}

// ============================================================================
// CONTROLLER
// ============================================================================

class HomeController extends StateNotifier<HomeState> {
  final Ref _ref;

  // TASK 2 FIX: type changed from StreamSubscription<QuerySnapshot<...>> to
  // StreamSubscription<List<WorkerModel>> — the service now handles Firestore
  // snapshot → model parsing, so the controller receives typed data.
  StreamSubscription<List<WorkerModel>>? _workersStreamSub;

  Timer? _streamRebuildDebounce;

  HomeController(this._ref) : super(const HomeState()) {
    _syncFromLocationController();

    _ref.listen<UserLocationState>(
      userLocationControllerProvider,
      (prev, next) {
        if (!mounted) return;

        if (next.isGpsDisabled) {
          AppLogger.warning('HomeController: GPS hardware disabled');
          state = state.copyWith(
            locationStatus: HomeLocationStatus.gpsDisabled,
          );
          return;
        }

        if (next.isDenied && state.userLocation == null) {
          AppLogger.warning(
              'HomeController: location denied — using default location');
          _useDefaultLocation();
          return;
        }

        if (next.userLocation != null &&
            next.userLocation != prev?.userLocation) {
          AppLogger.info(
              'HomeController: received updated location from UserLocationController');
          state = state.copyWith(
            locationStatus: HomeLocationStatus.loaded,
            userLocation:   next.userLocation,
          );
          _onLocationUpdated(next.userLocation!);
        }
      },
    );
  }

  @override
  void dispose() {
    _streamRebuildDebounce?.cancel();
    _workersStreamSub?.cancel();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  Future<void> retryLocation() async {
    state = state.copyWith(locationStatus: HomeLocationStatus.loading);
    await _ref.read(userLocationControllerProvider.notifier).retryLocation();
  }

  void enterMapFullscreen() {
    AppLogger.debug('HomeController: entering fullscreen map');
    state = state.copyWith(isMapFullscreen: true);
  }

  void exitMapFullscreen() {
    AppLogger.debug('HomeController: exiting fullscreen map');
    state = state.copyWith(isMapFullscreen: false);
  }

  void toggleServiceFilter(String? filter) {
    final next = filter == state.activeServiceFilter ? null : filter;
    AppLogger.debug('HomeController: filter → $next');
    state = state.copyWith(
      activeServiceFilter: next,
      clearFilter:         next == null,
      clearBestWorker:     true,
    );
  }

  void setServiceFilter(String? filter) {
    AppLogger.debug('HomeController: setServiceFilter → $filter');
    state = state.copyWith(
      activeServiceFilter: filter,
      clearFilter:         filter == null,
      clearBestWorker:     true,
    );
  }

  void setBestWorker(String? workerId) {
    AppLogger.debug('HomeController: bestWorkerId → $workerId');
    state = state.copyWith(
      bestWorkerId:    workerId,
      clearBestWorker: workerId == null,
    );
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true);
    if (state.userLocation != null) {
      await _subscribeToNearbyWorkers(state.userLocation!);
      await _fetchAddress(state.userLocation!);
    } else {
      await retryLocation();
    }
    if (mounted) state = state.copyWith(isRefreshing: false);
  }

  // --------------------------------------------------------------------------
  // Private — bootstrap
  // --------------------------------------------------------------------------

  void _syncFromLocationController() {
    final locState = _ref.read(userLocationControllerProvider);

    if (locState.isGpsDisabled) {
      state = state.copyWith(locationStatus: HomeLocationStatus.gpsDisabled);
    } else if (locState.userLocation != null) {
      AppLogger.info('HomeController: instant location from cache');
      state = state.copyWith(
        locationStatus: HomeLocationStatus.loaded,
        userLocation:   locState.userLocation,
      );
      _onLocationUpdated(locState.userLocation!);
    } else if (locState.isDenied) {
      _useDefaultLocation();
    } else {
      state = state.copyWith(locationStatus: HomeLocationStatus.loading);
    }
  }

  void _useDefaultLocation() {
    const algiers = LatLng(36.7372, 3.0865);
    AppLogger.info('HomeController: falling back to default location (Algiers)');
    state = state.copyWith(
      locationStatus: HomeLocationStatus.loaded,
      userLocation:   algiers,
    );
    _onLocationUpdated(algiers);
  }

  // --------------------------------------------------------------------------
  // Private — location change handler
  // --------------------------------------------------------------------------

  void _onLocationUpdated(LatLng location) {
    _fetchAddress(location);

    _streamRebuildDebounce?.cancel();
    _streamRebuildDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _subscribeToNearbyWorkers(location);
    });
  }

  // --------------------------------------------------------------------------
  // Private — address
  // --------------------------------------------------------------------------

  Future<void> _fetchAddress(LatLng location) async {
    try {
      final address = await _ref
          .read(geocodingServiceProvider)
          .getAddressFromCoordinates(
            lat: location.latitude,
            lng: location.longitude,
          );
      if (!mounted) return;
      AppLogger.info('HomeController: address resolved — $address');
      state = state.copyWith(userAddress: address);
    } catch (e) {
      AppLogger.warning('HomeController._fetchAddress: $e');
    }
  }

  // --------------------------------------------------------------------------
  // TASK 2 FIX — real-time geo-aware stream via firestoreServiceProvider
  // --------------------------------------------------------------------------

  Future<void> _subscribeToNearbyWorkers(LatLng location) async {
    await _workersStreamSub?.cancel();
    _workersStreamSub = null;

    if (!mounted) return;
    state = state.copyWith(
      isWorkersStreamInitialising: true,
      clearWorkersError:           true,
    );

    try {
      final gridService  = _ref.read(geographicGridServiceProvider);
      final wilayaManager = _ref.read(wilayaManagerProvider);

      final wilayaCode = gridService.getWilayaCodeFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (wilayaCode == null) {
        AppLogger.warning(
            'HomeController: could not determine wilaya — falling back to '
            'unscoped query');
        _subscribeFallback(location);
        return;
      }

      AppLogger.info(
          'HomeController: subscribing to workers in wilaya $wilayaCode '
          'and neighbours');

      final wilayaModel = wilayaManager.wilayas[wilayaCode];
      final allCodes = <int>[wilayaCode];
      if (wilayaModel != null) {
        for (final neighbour in wilayaModel.neighboringWilayas) {
          if (allCodes.length >= 10) break;
          allCodes.add(neighbour);
        }
      }

      AppLogger.debug('HomeController: querying wilaya codes $allCodes');

      // TASK 2 FIX: use firestoreServiceProvider instead of
      // FirebaseFirestore.instance.collection(...).where(...).snapshots().
      // WorkerFirestoreRepository.streamOnlineWorkersByWilayas() constructs
      // the same Firestore query internally and returns List<WorkerModel>.
      _workersStreamSub = _ref
          .read(firestoreServiceProvider)
          .streamOnlineWorkersByWilayas(allCodes)
          .listen(
        (workers) {
          if (!mounted) return;

          AppLogger.debug(
              'HomeController: workers snapshot — ${workers.length} raw docs');

          final filtered = _filterAndSortWorkers(workers, location);

          state = state.copyWith(
            nearbyWorkers:               filtered,
            isWorkersStreamInitialising: false,
            clearWorkersError:           true,
          );

          AppLogger.info(
              'HomeController: ${filtered.length} workers within '
              '${AppConstants.defaultSearchRadiusKm.toInt()} km');
        },
        onError: (Object e) {
          AppLogger.error('HomeController workers stream error', e);
          if (!mounted) return;
          AppLogger.warning(
              'HomeController: wilaya stream failed — falling back to '
              'unscoped query');
          _subscribeFallback(location);
        },
        cancelOnError: false,
      );
    } catch (e) {
      AppLogger.error('HomeController._subscribeToNearbyWorkers', e);
      if (!mounted) return;
      _subscribeFallback(location);
    }
  }

  // TASK 2 FIX: fallback also uses firestoreServiceProvider.
  // WorkerFirestoreRepository.streamOnlineWorkersUnscoped() applies the same
  // .limit() cap that was previously in the inline query.
  void _subscribeFallback(LatLng location) {
    AppLogger.info('HomeController: using fallback unscoped stream');

    _workersStreamSub?.cancel();

    _workersStreamSub = _ref
        .read(firestoreServiceProvider)
        .streamOnlineWorkersUnscoped(
          limit: AppConstants.fallbackWorkerQueryLimit,
        )
        .listen(
      (workers) {
        if (!mounted) return;

        final filtered = _filterAndSortWorkers(workers, location);
        state = state.copyWith(
          nearbyWorkers:               filtered,
          isWorkersStreamInitialising: false,
          clearWorkersError:           true,
        );

        AppLogger.info(
            'HomeController (fallback): ${filtered.length} workers within '
            '${AppConstants.defaultSearchRadiusKm.toInt()} km');
      },
      onError: (Object e) {
        AppLogger.error('HomeController fallback stream error', e);
        if (!mounted) return;
        state = state.copyWith(
          isWorkersStreamInitialising: false,
          workersError: e.toString(),
        );
      },
      cancelOnError: false,
    );
  }

  // --------------------------------------------------------------------------
  // TASK 2 FIX — distance filter + sort (was _processWorkerSnapshot)
  // --------------------------------------------------------------------------

  /// Filters [workers] to those within the max search radius and sorts by
  /// ascending distance to [userLocation]. Replaces _processWorkerSnapshot
  /// which took a raw QuerySnapshot — the service now handles model parsing.
  List<WorkerModel> _filterAndSortWorkers(
    List<WorkerModel> workers,
    LatLng userLocation,
  ) {
    final maxKm = AppConstants.defaultSearchRadiusKm;

    return workers
        .where((w) => w.latitude != null && w.longitude != null)
        .where((w) {
          final distKm = w.distanceTo(
            userLocation.latitude,
            userLocation.longitude,
          );
          return distKm <= maxKm;
        })
        .toList()
      ..sort((a, b) {
          final da =
              a.distanceTo(userLocation.latitude, userLocation.longitude);
          final db =
              b.distanceTo(userLocation.latitude, userLocation.longitude);
          return da.compareTo(db);
        });
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

final homeControllerProvider =
    StateNotifierProvider.autoDispose<HomeController, HomeState>((ref) {
  final link = ref.keepAlive();
  ref.listen<bool>(isLoggedInProvider, (_, isLoggedIn) {
    if (!isLoggedIn) link.close();
  });
  return HomeController(ref);
});
