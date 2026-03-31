// lib/providers/home_search_controller.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/search_intent.dart';
import '../models/search_result_model.dart';
import '../models/worker_model.dart';
import '../services/ai_intent_extractor.dart';
import '../utils/model_extensions.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import 'core_providers.dart';
import 'home_controller.dart';

// ============================================================================
// STATE
// ============================================================================

enum HomeSearchStatus {
  idle,
  listening,
  extracting,
  searching,
  results,
  error,
}

/// Structured error type exposed to the UI for distinct user-facing messages.
enum HomeSearchErrorType {
  quotaExceeded,   // 429 — show "retry in a few minutes"
  modelOverloaded, // 503 — show "service temporarily unavailable"
  timeout,         // 15s hard timeout
  network,         // generic connectivity error
  unknown,
}

class HomeSearchState {
  final HomeSearchStatus  status;
  final String            interimText;
  final SearchIntent?     lastIntent;
  final List<GeoSearchResult<WorkerModel>> results;
  final String?           error;
  final HomeSearchErrorType? errorType;

  const HomeSearchState({
    this.status      = HomeSearchStatus.idle,
    this.interimText = '',
    this.lastIntent,
    this.results     = const [],
    this.error,
    this.errorType,
  });

  bool get isLoading =>
      status == HomeSearchStatus.extracting ||
      status == HomeSearchStatus.searching;

  bool get hasResults => status == HomeSearchStatus.results;
  bool get isEmpty    => hasResults && results.isEmpty;
  bool get hasError   => status == HomeSearchStatus.error;

  HomeSearchState copyWith({
    HomeSearchStatus?                   status,
    String?                             interimText,
    SearchIntent?                       lastIntent,
    List<GeoSearchResult<WorkerModel>>? results,
    String?                             error,
    HomeSearchErrorType?                errorType,
    bool                                clearError  = false,
    bool                                clearIntent = false,
  }) {
    return HomeSearchState(
      status:      status      ?? this.status,
      interimText: interimText ?? this.interimText,
      lastIntent:  clearIntent ? null : (lastIntent ?? this.lastIntent),
      results:     results     ?? this.results,
      error:       clearError  ? null : (error ?? this.error),
      errorType:   clearError  ? null : (errorType ?? this.errorType),
    );
  }
}

// ============================================================================
// CONTROLLER
// ============================================================================

class HomeSearchController extends StateNotifier<HomeSearchState> {
  final Ref _ref;

  // FIX (AI Cost): per-session rate limit — max 20 AI calls per hour.
  // Timestamps are stored in memory; the window is a rolling 1-hour period.
  // This guards against accidental runaway (e.g. automation, rapid retries)
  // before server-side enforcement (Firebase App Check / Cloud Function) is in place.
  static const int      _maxCallsPerHour = 20;
  static const Duration _windowDuration  = Duration(hours: 1);
  final List<DateTime>  _callTimestamps  = [];

  HomeSearchController(this._ref) : super(const HomeSearchState());

  // --------------------------------------------------------------------------
  // Rate limiter helpers
  // --------------------------------------------------------------------------

  bool _isRateLimited() {
    final now    = DateTime.now();
    final cutoff = now.subtract(_windowDuration);
    _callTimestamps.removeWhere((t) => t.isBefore(cutoff));
    return _callTimestamps.length >= _maxCallsPerHour;
  }

  void _recordCall() => _callTimestamps.add(DateTime.now());

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  Future<void> submitSearch(
    String text, {
    Uint8List? imageBytes,
    String?    mime,
  }) async {
    final hasText  = text.trim().isNotEmpty;
    final hasImage = imageBytes != null && imageBytes.isNotEmpty;
    if (!hasText && !hasImage) return;

    if (_isRateLimited()) {
      AppLogger.warning(
          'HomeSearchController: rate limit reached ($_maxCallsPerHour/hour)');
      state = state.copyWith(
        status:    HomeSearchStatus.error,
        error:     'rate_limit_exceeded',
        errorType: HomeSearchErrorType.quotaExceeded,
      );
      return;
    }

    state = state.copyWith(
      status:     HomeSearchStatus.extracting,
      clearError: true,
    );

    // FIX (Analytics): log search attempt.
    _ref.read(analyticsServiceProvider).logBrowseFilterApplied(
      filter:       hasImage ? 'image_search' : 'text_search',
      resultsCount: 0,
    );

    SearchIntent intent;
    try {
      final extractor = _ref.read(aiIntentExtractorProvider);
      intent = await extractor.extract(text,
          imageBytes: imageBytes, mime: mime);
      _recordCall();
      AppLogger.info('HomeSearchController: intent → ${intent.toJson()}');
    } on AiIntentExtractorException catch (e) {
      AppLogger.error('HomeSearchController.submitSearch [extract]', e);
      state = state.copyWith(
        status:    HomeSearchStatus.error,
        error:     e.message,
        errorType: _mapErrorCode(e.code),
      );
      return;
    } catch (e) {
      AppLogger.error('HomeSearchController.submitSearch [extract]', e);
      state = state.copyWith(
        status:    HomeSearchStatus.error,
        error:     e.toString(),
        errorType: HomeSearchErrorType.unknown,
      );
      return;
    }

    state = state.copyWith(
      status:     HomeSearchStatus.searching,
      lastIntent: intent,
    );

    try {
      final results = await _search(intent);

      // FIX (Analytics): log results with profession + count.
      _ref.read(analyticsServiceProvider).logBrowseFilterApplied(
        filter:       intent.profession ?? 'no_profession',
        resultsCount: results.length,
      );

      state = state.copyWith(
        status:  HomeSearchStatus.results,
        results: results,
      );
    } catch (e) {
      AppLogger.error('HomeSearchController.submitSearch [search]', e);
      state = state.copyWith(
        status:    HomeSearchStatus.error,
        error:     e.toString(),
        errorType: HomeSearchErrorType.network,
      );
    }
  }

  Future<void> startListening() async {
    final audio   = _ref.read(audioServiceProvider);
    final hasPerm = await audio.hasAudioPermission();
    if (!hasPerm || !mounted) {
      state = state.copyWith(
        status: HomeSearchStatus.error,
        error:  'mic_unavailable',
      );
      return;
    }

    try {
      await audio.startRecording();
      if (!mounted) return;
      state = state.copyWith(
        status:      HomeSearchStatus.listening,
        interimText: '',
        clearError:  true,
      );
    } catch (e) {
      AppLogger.error('HomeSearchController.startListening', e);
      if (mounted) {
        state = state.copyWith(
          status: HomeSearchStatus.error,
          error:  'mic_unavailable',
        );
      }
    }
  }

  Future<void> stopListening() async {
    if (!mounted || state.status != HomeSearchStatus.listening) return;
    state = state.copyWith(
        status: HomeSearchStatus.extracting, clearError: true);

    final audio = _ref.read(audioServiceProvider);
    String? filePath;
    try {
      filePath = await audio.stopRecording();
    } catch (e) {
      AppLogger.error('HomeSearchController.stopListening [stop]', e);
      if (mounted) {
        state = state.copyWith(
            status: HomeSearchStatus.error, error: 'recording_failed');
      }
      return;
    }

    if (filePath == null) {
      if (mounted) state = state.copyWith(status: HomeSearchStatus.idle);
      return;
    }

    Uint8List audioBytes;
    try {
      final file = File(filePath);
      audioBytes = await file.readAsBytes();
      await file.delete();
    } catch (e) {
      AppLogger.error('HomeSearchController.stopListening [read]', e);
      if (mounted) {
        state = state.copyWith(
            status: HomeSearchStatus.error, error: 'recording_failed');
      }
      return;
    }

    if (!mounted) return;

    if (_isRateLimited()) {
      if (mounted) {
        state = state.copyWith(
          status:    HomeSearchStatus.error,
          error:     'rate_limit_exceeded',
          errorType: HomeSearchErrorType.quotaExceeded,
        );
      }
      return;
    }

    SearchIntent intent;
    try {
      final extractor = _ref.read(aiIntentExtractorProvider);
      intent = await extractor.extractFromAudio(audioBytes);
      _recordCall();
      AppLogger.info(
          'HomeSearchController: audio intent → ${intent.toJson()}');
    } on AiIntentExtractorException catch (e) {
      AppLogger.error('HomeSearchController.stopListening [extract]', e);
      if (mounted) {
        state = state.copyWith(
          status:    HomeSearchStatus.error,
          error:     e.message,
          errorType: _mapErrorCode(e.code),
        );
      }
      return;
    } catch (e) {
      AppLogger.error('HomeSearchController.stopListening [extract]', e);
      if (mounted) {
        state = state.copyWith(
            status: HomeSearchStatus.error, error: e.toString());
      }
      return;
    }

    if (!mounted) return;
    state = state.copyWith(
        status: HomeSearchStatus.searching, lastIntent: intent);
    try {
      final results = await _search(intent);
      if (mounted) {
        state = state.copyWith(
            status: HomeSearchStatus.results, results: results);
      }
    } catch (e) {
      AppLogger.error('HomeSearchController.stopListening [search]', e);
      if (mounted) {
        state = state.copyWith(
            status: HomeSearchStatus.error, error: e.toString());
      }
    }
  }

  void applyToMap() {
    final intent       = state.lastIntent;
    final results      = state.results;
    final homeNotifier = _ref.read(homeControllerProvider.notifier);
    final homeState    = _ref.read(homeControllerProvider);

    if (intent?.profession != null) {
      homeNotifier.setServiceFilter(intent!.profession);
    }

    if (results.isNotEmpty) {
      final userLoc   = homeState.userLocation;
      final nearbyIds = homeState.nearbyWorkers.map((w) => w.id).toSet();
      final intersected =
          results.where((r) => nearbyIds.contains(r.data.id)).toList();

      final List<GeoSearchResult<WorkerModel>> pool;
      if (intersected.isNotEmpty) {
        pool = intersected;
      } else {
        final professionWorkers = intent?.profession != null
            ? homeState.nearbyWorkers
                .where((w) => w.profession == intent!.profession)
                .toList()
            : homeState.nearbyWorkers;
        if (professionWorkers.isEmpty) {
          homeNotifier.enterMapFullscreen();
          return;
        }
        pool = professionWorkers.map((w) {
          final distance = userLoc != null
              ? w.distanceTo(userLoc.latitude, userLoc.longitude)
              : 0.0;
          return GeoSearchResult<WorkerModel>(
            data:       w,
            distance:   distance,
            cellId:     w.cellId     ?? '',
            wilayaCode: w.wilayaCode ?? 0,
            source:     SearchResultSource.currentCell,
          );
        }).toList();
      }

      final maxRating = pool
          .map((r) => r.data.averageRating)
          .reduce((a, b) => a > b ? a : b);
      final minRating = pool
          .map((r) => r.data.averageRating)
          .reduce((a, b) => a < b ? a : b);
      final maxDist = pool
          .map((r) => r.distance)
          .reduce((a, b) => a > b ? a : b);
      final minDist = pool
          .map((r) => r.distance)
          .reduce((a, b) => a < b ? a : b);

      final ratingRange =
          (maxRating - minRating).clamp(0.01, double.infinity);
      final distRange =
          (maxDist - minDist).clamp(0.01, double.infinity);

      String? bestId;
      double  bestScore = -1;

      for (final r in pool) {
        final normRating = (r.data.averageRating - minRating) / ratingRange;
        final normDist   = 1.0 - ((r.distance - minDist) / distRange);
        final score      = normRating * 0.6 + normDist * 0.4;
        if (score > bestScore) {
          bestScore = score;
          bestId    = r.data.id;
        }
      }

      AppLogger.info(
          'HomeSearchController: best worker → $bestId '
          '(score ${bestScore.toStringAsFixed(2)})');
      homeNotifier.setBestWorker(bestId);
    }

    homeNotifier.enterMapFullscreen();
  }

  void reset() {
    _ref.read(audioServiceProvider).cancelRecording();
    state = const HomeSearchState();
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  HomeSearchErrorType _mapErrorCode(AiExtractorErrorCode code) {
    switch (code) {
      case AiExtractorErrorCode.quotaExceeded:
        return HomeSearchErrorType.quotaExceeded;
      case AiExtractorErrorCode.modelOverloaded:
        return HomeSearchErrorType.modelOverloaded;
      case AiExtractorErrorCode.timeout:
        return HomeSearchErrorType.timeout;
      default:
        return HomeSearchErrorType.network;
    }
  }

  Future<List<GeoSearchResult<WorkerModel>>> _search(
      SearchIntent intent) async {
    final homeState = _ref.read(homeControllerProvider);
    final userLoc   = homeState.userLocation;
    final maxRadius =
        intent.maxRadiusKm ?? AppConstants.defaultSearchRadiusKm;

    if (userLoc == null) {
      return _buildFallbackResults(intent, homeState);
    }

    final gridService = _ref.read(geographicGridServiceProvider);
    final wilayaCode  = gridService.getWilayaCodeFromCoordinates(
      userLoc.latitude,
      userLoc.longitude,
    );

    if (intent.profession == null) {
      return _buildFallbackResults(intent, homeState);
    }

    if (wilayaCode != null) {
      try {
        final searchService = _ref.read(smartSearchServiceProvider);
        return await searchService.searchWorkers(
          userLat:        userLoc.latitude,
          userLng:        userLoc.longitude,
          userWilayaCode: wilayaCode,
          serviceType:    intent.profession!,
          maxResults:     20,
          maxRadius:      maxRadius,
        );
      } catch (e) {
        AppLogger.warning(
            'HomeSearchController: SmartSearch failed, falling back. $e');
      }
    }

    return _buildFallbackResults(intent, homeState);
  }

  List<GeoSearchResult<WorkerModel>> _buildFallbackResults(
    SearchIntent intent,
    HomeState    homeState,
  ) {
    final userLoc = homeState.userLocation;
    final workers = intent.profession == null
        ? homeState.nearbyWorkers
        : homeState.nearbyWorkers
            .where((w) => w.profession == intent.profession)
            .toList();

    return workers.map((w) {
      final distance = userLoc != null
          ? w.distanceTo(userLoc.latitude, userLoc.longitude)
          : 0.0;
      return GeoSearchResult<WorkerModel>(
        data:       w,
        distance:   distance,
        cellId:     w.cellId     ?? '',
        wilayaCode: w.wilayaCode ?? 0,
        source:     SearchResultSource.currentCell,
      );
    }).toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
  }

  @override
  void dispose() {
    _ref.read(audioServiceProvider).cancelRecording();
    super.dispose();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

final homeSearchControllerProvider =
    StateNotifierProvider.autoDispose<HomeSearchController, HomeSearchState>(
        (ref) => HomeSearchController(ref));
