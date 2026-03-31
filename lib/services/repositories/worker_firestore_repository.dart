// lib/services/repositories/worker_firestore_repository.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/worker_model.dart';
import 'firestore_cache.dart';
import 'firestore_repository_base.dart';

class WorkerFirestoreRepository extends FirestoreRepositoryBase {
  static const String workersCollection = 'workers';

  final FirestoreCache<WorkerModel> _cache;

  WorkerFirestoreRepository(super.firestore)
      : _cache = FirestoreCache<WorkerModel>(
          ttl: const Duration(minutes: 15),
          maxSize: 100,
          tag: '[WorkerRepo]',
        );

  // FIX: renamed from `_logTag` (library-private) to `logTag` (public).
  // See firestore_repository_base.dart for the full explanation.
  @override
  String get logTag => '[WorkerRepo]';

  // --------------------------------------------------------------------------
  // READ
  // --------------------------------------------------------------------------

  Future<WorkerModel?> getWorker(String workerId) async {
    ensureNotDisposed();
    if (workerId.trim().isEmpty) {
      logWarning('getWorker called with empty workerId');
      return null;
    }

    final cached = _cache.get(workerId);
    if (cached != null) return cached;

    return retryOperation(() async {
      try {
        final doc = await firestore
            .collection(workersCollection)
            .doc(workerId)
            .get()
            .timeout(FirestoreRepositoryBase.operationTimeout);

        if (!doc.exists || doc.data() == null) {
          logWarning('Worker not found: $workerId');
          return null;
        }

        final worker = WorkerModel.fromMap(doc.data()!, doc.id);
        _cache.set(workerId, worker);
        return worker;
      } on TimeoutException {
        logError('getWorker', 'Timeout fetching worker: $workerId');
        return null;
      } catch (e) {
        logError('getWorker', e);
        return null;
      }
    });
  }

  Stream<WorkerModel?> streamWorker(String workerId) {
    if (workerId.trim().isEmpty) {
      logWarning('streamWorker called with empty workerId');
      return Stream.value(null);
    }

    return firestore
        .collection(workersCollection)
        .doc(workerId)
        .snapshots()
        // Re-propagate errors so consumers can show a proper error state
        // instead of silently displaying nothing.
        .handleError((Object error, StackTrace stack) {
          logError('streamWorker', error);
          throw error;
        })
        .map((doc) {
          try {
            if (!doc.exists || doc.data() == null) return null;
            final worker = WorkerModel.fromMap(doc.data()!, doc.id);
            _cache.set(workerId, worker);
            return worker;
          } catch (e) {
            logError('streamWorker.parsing', e);
            return null;
          }
        });
  }

  Future<List<WorkerModel>> getWorkersInCell({
    required String cellId,
    String? serviceType,
    bool onlineOnly = false,
  }) async {
    ensureNotDisposed();
    if (cellId.trim().isEmpty) {
      logWarning('getWorkersInCell called with empty cellId');
      return [];
    }

    return retryOperation(() async {
      try {
        Query query = firestore
            .collection(workersCollection)
            .where('cellId', isEqualTo: cellId);
        if (serviceType != null && serviceType.trim().isNotEmpty) {
          query = query.where('profession', isEqualTo: serviceType);
        }
        if (onlineOnly) query = query.where('isOnline', isEqualTo: true);

        final snapshot = await query
            .get()
            .timeout(FirestoreRepositoryBase.operationTimeout);
        return snapshot.docs
            .map((doc) {
              try {
                return WorkerModel.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id);
              } catch (e) {
                logError('getWorkersInCell.parsing', e);
                return null;
              }
            })
            .whereType<WorkerModel>()
            .toList();
      } catch (e) {
        logError('getWorkersInCell', e);
        return [];
      }
    });
  }

  Future<List<WorkerModel>> getWorkersInWilaya({
    required int wilayaCode,
    String? serviceType,
    bool onlineOnly = false,
  }) async {
    ensureNotDisposed();

    return retryOperation(() async {
      try {
        Query query = firestore
            .collection(workersCollection)
            .where('wilayaCode', isEqualTo: wilayaCode);
        if (serviceType != null && serviceType.trim().isNotEmpty) {
          query = query.where('profession', isEqualTo: serviceType);
        }
        if (onlineOnly) query = query.where('isOnline', isEqualTo: true);

        final snapshot = await query
            .get()
            .timeout(FirestoreRepositoryBase.operationTimeout);
        return snapshot.docs
            .map((doc) {
              try {
                return WorkerModel.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id);
              } catch (e) {
                logError('getWorkersInWilaya.parsing', e);
                return null;
              }
            })
            .whereType<WorkerModel>()
            .toList();
      } catch (e) {
        logError('getWorkersInWilaya', e);
        return [];
      }
    });
  }

  // --------------------------------------------------------------------------
  // WRITE
  // --------------------------------------------------------------------------

  Future<void> setWorker(WorkerModel worker) async {
    ensureNotDisposed();
    validateWorkerId(worker.id);

    return retryOperation(() async {
      try {
        await firestore
            .collection(workersCollection)
            .doc(worker.id)
            .set(worker.toMap(), SetOptions(merge: true))
            .timeout(FirestoreRepositoryBase.operationTimeout);

        _cache.set(worker.id, worker);
        logInfo('Worker saved: ${worker.id}');
      } catch (e) {
        logError('setWorker', e);
        throw FirestoreServiceException(
          'Error saving worker',
          code: 'WORKER_SAVE_FAILED',
          originalError: e,
        );
      }
    });
  }

  Future<void> createOrUpdateWorker(WorkerModel worker) => setWorker(worker);

  Future<void> updateWorkerLocation(
    String workerId,
    double latitude,
    double longitude, {
    String? cellId,
    int? wilayaCode,
    String? geoHash,
  }) async {
    ensureNotDisposed();
    validateWorkerId(workerId);
    validateCoordinates(latitude, longitude);

    return retryOperation(() async {
      try {
        final updateData = <String, dynamic>{
          'latitude': latitude,
          'longitude': longitude,
          'lastUpdated': Timestamp.now(),
          'lastLocationUpdate': Timestamp.now(),
        };
        if (cellId != null) updateData['cellId'] = cellId;
        if (wilayaCode != null) updateData['wilayaCode'] = wilayaCode;
        if (geoHash != null) updateData['geoHash'] = geoHash;

        await firestore
            .collection(workersCollection)
            .doc(workerId)
            .update(updateData)
            .timeout(FirestoreRepositoryBase.operationTimeout);

        _cache.update(
            workerId,
            (w) => w.copyWith(
                  latitude: latitude,
                  longitude: longitude,
                  cellId: cellId,
                  wilayaCode: wilayaCode,
                  geoHash: geoHash,
                  lastUpdated: DateTime.now(),
                  lastCellUpdate: DateTime.now(),
                ));
        logInfo('Worker location updated: $workerId');
      } catch (e) {
        logError('updateWorkerLocation', e);
        rethrow;
      }
    });
  }

  Future<void> updateWorkerStatus(String workerId, bool isOnline) async {
    ensureNotDisposed();
    validateWorkerId(workerId);

    return retryOperation(() async {
      try {
        await firestore
            .collection(workersCollection)
            .doc(workerId)
            .update({
          'isOnline': isOnline,
          'lastUpdated': Timestamp.now(),
        }).timeout(FirestoreRepositoryBase.operationTimeout);

        _cache.update(
            workerId,
            (w) => w.copyWith(
                  isOnline: isOnline,
                  lastUpdated: DateTime.now(),
                ));
        logInfo('Worker status updated: $workerId → $isOnline');
      } catch (e) {
        logError('updateWorkerStatus', e);
        rethrow;
      }
    });
  }

  Future<void> updateWorkerOnlineStatus(String workerId, bool isOnline) =>
      updateWorkerStatus(workerId, isOnline);

  // FIX (Backend Audit): UserFirestoreRepository had this method but
  // WorkerFirestoreRepository did not. Workers receive service-request push
  // notifications — the token must be kept up to date on their document.
  Future<void> updateFcmToken(String workerId, String token) async {
    ensureNotDisposed();
    validateWorkerId(workerId);

    if (token.trim().isEmpty) {
      throw FirestoreServiceException(
        'FCM token cannot be empty',
        code: 'INVALID_FCM_TOKEN',
      );
    }

    return retryOperation(() async {
      try {
        await firestore
            .collection(workersCollection)
            .doc(workerId)
            .update({
          'fcmToken': token,
          'lastFcmTokenUpdate': Timestamp.now(),
        }).timeout(FirestoreRepositoryBase.operationTimeout);

        logInfo('FCM token updated for worker: $workerId');
      } catch (e) {
        logError('updateFcmToken', e);
        rethrow;
      }
    });
  }

  // --------------------------------------------------------------------------
  // CACHE MANAGEMENT
  // --------------------------------------------------------------------------

  void cacheWorker(String workerId, WorkerModel worker) =>
      _cache.set(workerId, worker);

  void cleanExpiredCache() => _cache.cleanExpired();

  void clearCache() => _cache.clear();

  // --------------------------------------------------------------------------
  // DISPOSE
  // --------------------------------------------------------------------------

  void dispose() {
    if (isDisposed) return;
    markDisposed();
    _cache.clear();
    logInfo('WorkerFirestoreRepository disposed');
  }
}
