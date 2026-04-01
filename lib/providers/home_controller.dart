// lib/providers/home_controller.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/worker_model.dart';

import '../services/firestore_service.dart';
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
  /// Set to true while the first geo-query result has not yet arrived.
  final bool isWorkersStreamInitialising;
  /// ID of the highest-scored worker after an AI search (rating + proximity).
  /// Null when no AI search has been run or after filter reset.
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
    // Explicit-clear flags
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

  /// Real-time Firestore subscription for online workers.
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _workersStreamSub;

  /// Debounce timer — prevents rapid location changes from spawning multiple
  /// Firestore streams in quick succession.
  Timer? _streamRebuildDebounce;

  HomeController(this._ref) : super(const HomeState()) {
    _syncFromLocationController();

    // React to every location update emitted by UserLocationController.
    _ref.listen<UserLocationState>(
      userLocationControllerProvider,
      (prev, next) {
        if (!mounted) return;

        // ── GPS hardware off ───────────────────────────────────────────────
        if (next.isGpsDisabled) {
          AppLogger.warning('HomeController: GPS hardware disabled');
          state = state.copyWith(
            locationStatus: HomeLocationStatus.gpsDisabled,
          );
          return;
        }

        // ── Permission denied ──────────────────────────────────────────────
        if (next.isDenied && state.userLocation == null) {
          AppLogger.warning(
              'HomeController: location denied — using default location');
          _useDefaultLocation();
          return;
        }

        // ── New location arrived ───────────────────────────────────────────
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

  /// Sets the best-scored worker ID after an AI search.
  /// Pass null to clear the highlight (e.g. on filter reset).
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
      // Rebuild the real-time stream (picks up any wilaya / cell change).
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

  /// Called whenever a valid location becomes available or changes.
  void _onLocationUpdated(LatLng location) {
    _fetchAddress(location);

    // Debounce stream rebuilds so rapid GPS fixes don't thrash Firestore.
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
      // Swallow — UI handles null address gracefully.
    }
  }

  // --------------------------------------------------------------------------
  // Private — real-time geo-aware Firestore stream
  // --------------------------------------------------------------------------

  Future<void> _subscribeToNearbyWorkers(LatLng location) async {
    // Cancel the previous subscription before rebuilding.
    await _workersStreamSub?.cancel();
    _workersStreamSub = null;

    if (!mounted) return;
    state = state.copyWith(
      isWorkersStreamInitialising: true,
      clearWorkersError:           true,
    );

    try {
      // ── 1. Determine user's wilaya ────────────────────────────────────────
      final gridService = _ref.read(geographicGridServiceProvider);
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

      // ── 2. Collect wilaya codes to query ──────────────────────────────────
      final wilayaModel = wilayaManager.wilayas[wilayaCode];
      final allCodes = <int>[wilayaCode];
      if (wilayaModel != null) {
        for (final neighbour in wilayaModel.neighboringWilayas) {
          if (allCodes.length >= 10) break;
          allCodes.add(neighbour);
        }
      }

      AppLogger.debug(
          'HomeController: querying wilaya codes $allCodes');

      // ── 3. Firestore real-time stream ─────────────────────────────────────
      // B8 FIX: use FirestoreService.workersCollection constant instead of
      // the hardcoded string 'workers' so collection renames stay consistent.
      final query = FirebaseFirestore.instance
          .collection(FirestoreService.workersCollection)
          .where('isOnline', isEqualTo: true)
          .where('wilayaCode', whereIn: allCodes);

      _workersStreamSub = query.snapshots().listen(
        (snapshot) {
          if (!mounted) return;

          AppLogger.debug(
              'HomeController: workers snapshot — '
              '${snapshot.docs.length} raw docs');

          final filtered = _processWorkerSnapshot(snapshot, location);

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

  /// Fallback: query all online workers without wilaya scoping, then filter
  /// by distance in Dart. Used when the wilaya lookup fails or the indexed
  /// query is unavailable (e.g. first-run before index build).
  ///
  /// B7 FIX: added .limit(AppConstants.fallbackWorkerQueryLimit) to prevent
  /// reading every online worker document on every snapshot in production.
  /// B8 FIX: use FirestoreService.workersCollection instead of 'workers'.
  void _subscribeFallback(LatLng location) {
    AppLogger.info('HomeController: using fallback unscoped stream');

    _workersStreamSub?.cancel();

    // B8 FIX: FirestoreService.workersCollection instead of 'workers'.
    // B7 FIX: .limit() cap to prevent unbounded reads in production.
    _workersStreamSub = FirebaseFirestore.instance
        .collection(FirestoreService.workersCollection)
        .where('isOnline', isEqualTo: true)
        .limit(AppConstants.fallbackWorkerQueryLimit)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;

        final filtered = _processWorkerSnapshot(snapshot, location);
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
  // Private — snapshot processing
  // --------------------------------------------------------------------------

  List<WorkerModel> _processWorkerSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    LatLng userLocation,
  ) {
    final maxKm = AppConstants.defaultSearchRadiusKm;

    final workers = snapshot.docs
        .map((doc) => WorkerModel.fromMap(doc.data(), doc.id))
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

    return workers;
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
