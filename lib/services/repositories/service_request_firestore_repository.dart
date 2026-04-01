// lib/services/repositories/service_request_firestore_repository.dart
//
// TASK 2 FIX — Added streamWorkerAssignedRequests().
//
// NEW METHOD:
//   streamWorkerAssignedRequests(workerId, {limit}): simple single-stream query
//   for requests assigned to a specific worker. Used by WorkerHomeController
//   dashboard. Previously the controller built this query via
//   FirebaseFirestore.instance directly.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/message_enums.dart';
import '../../models/notification_model.dart';
import '../../models/service_request_enhanced_model.dart';
import '../../models/service_request_model.dart';
import '../../models/worker_bid_model.dart';
import 'firestore_repository_base.dart';

class ServiceRequestFirestoreRepository extends FirestoreRepositoryBase {
  static const String serviceRequestsCollection = 'service_requests';
  static const String workerBidsCollection = 'worker_bids';
  static const String notificationsCollection = 'notifications';

  static const int _maxBidsToDecline = 50;

  ServiceRequestFirestoreRepository(super.firestore);

  @override
  String get logTag => '[ServiceRequestRepo]';

  // --------------------------------------------------------------------------
  // SERVICE REQUESTS — CRUD
  // --------------------------------------------------------------------------

  Future<void> createServiceRequest(
      ServiceRequestEnhancedModel request) async {
    ensureNotDisposed();
    if (request.id.trim().isEmpty) {
      throw FirestoreServiceException(
        'Service request ID cannot be empty',
        code: 'INVALID_REQUEST_ID',
      );
    }

    return retryOperation(() async {
      try {
        await firestore
            .collection(serviceRequestsCollection)
            .doc(request.id)
            .set(request.toMap())
            .timeout(FirestoreRepositoryBase.operationTimeout);
        logInfo('Service request created: ${request.id}');
      } catch (e) {
        logError('createServiceRequest', e);
        throw FirestoreServiceException(
          'Error creating service request',
          code: 'REQUEST_CREATE_FAILED',
          originalError: e,
        );
      }
    });
  }

  Future<ServiceRequestEnhancedModel?> getServiceRequest(
      String requestId) async {
    ensureNotDisposed();
    if (requestId.trim().isEmpty) {
      logWarning('getServiceRequest called with empty requestId');
      return null;
    }

    return retryOperation(() async {
      try {
        final doc = await firestore
            .collection(serviceRequestsCollection)
            .doc(requestId)
            .get()
            .timeout(FirestoreRepositoryBase.operationTimeout);
        if (!doc.exists || doc.data() == null) return null;
        return ServiceRequestEnhancedModel.fromMap(doc.data()!, doc.id);
      } catch (e) {
        logError('getServiceRequest', e);
        return null;
      }
    });
  }

  Future<void> updateServiceRequest(
      ServiceRequestEnhancedModel request) async {
    ensureNotDisposed();
    if (request.id.trim().isEmpty) {
      throw FirestoreServiceException(
        'Service request ID cannot be empty',
        code: 'INVALID_REQUEST_ID',
      );
    }

    return retryOperation(() async {
      try {
        await firestore
            .collection(serviceRequestsCollection)
            .doc(request.id)
            .update(request.toMap())
            .timeout(FirestoreRepositoryBase.operationTimeout);
        logInfo('Service request updated: ${request.id}');
      } catch (e) {
        logError('updateServiceRequest', e);
        throw FirestoreServiceException(
          'Error updating service request',
          code: 'REQUEST_UPDATE_FAILED',
          originalError: e,
        );
      }
    });
  }

  // --------------------------------------------------------------------------
  // SERVICE REQUESTS — STREAMS
  // --------------------------------------------------------------------------

  Stream<ServiceRequestEnhancedModel?> streamServiceRequest(
      String requestId) {
    if (requestId.trim().isEmpty) {
      logWarning('streamServiceRequest called with empty requestId');
      return Stream.value(null);
    }
    return firestore
        .collection(serviceRequestsCollection)
        .doc(requestId)
        .snapshots()
        .handleError((e) => logError('streamServiceRequest', e))
        .map((doc) {
          try {
            if (!doc.exists || doc.data() == null) return null;
            return ServiceRequestEnhancedModel.fromMap(doc.data()!, doc.id);
          } catch (e) {
            logError('streamServiceRequest.parsing', e);
            return null;
          }
        });
  }

  Stream<List<ServiceRequestEnhancedModel>> streamUserServiceRequests(
      String userId) {
    if (userId.trim().isEmpty) {
      logWarning('streamUserServiceRequests called with empty userId');
      return Stream.value([]);
    }
    return firestore
        .collection(serviceRequestsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) => logError('streamUserServiceRequests', e))
        .map((s) =>
            _parseRequestList(s.docs, 'streamUserServiceRequests'));
  }

  Stream<List<ServiceRequestEnhancedModel>> streamWorkerServiceRequests(
      String workerId) {
    if (workerId.trim().isEmpty) {
      logWarning(
          'streamWorkerServiceRequests called with empty workerId');
      return Stream.value([]);
    }

    List<ServiceRequestEnhancedModel> assignedJobs = [];
    List<ServiceRequestEnhancedModel> openJobs = [];
    StreamSubscription? assignedSub;
    StreamSubscription? openSub;

    late StreamController<List<ServiceRequestEnhancedModel>> controller;

    void emit() {
      if (controller.isClosed) return;
      final dedup = <String, ServiceRequestEnhancedModel>{};
      for (final j in [...assignedJobs, ...openJobs]) {
        dedup[j.id] = j;
      }
      controller.add(dedup.values.toList());
    }

    controller = StreamController<List<ServiceRequestEnhancedModel>>.broadcast(
      onListen: () {
        assignedSub = firestore
            .collection(serviceRequestsCollection)
            .where('workerId', isEqualTo: workerId)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen(
          (s) {
            assignedJobs =
                _parseRequestList(s.docs, 'workerAssigned');
            emit();
          },
          onError: (e) {
            logError('streamWorkerServiceRequests.assigned', e);
            if (!controller.isClosed) controller.addError(e);
          },
        );

        openSub = firestore
            .collection(serviceRequestsCollection)
            .where('status', whereIn: [
              ServiceStatus.open.name,
              ServiceStatus.awaitingSelection.name,
            ])
            .where('workerId', isNull: true)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen(
          (s) {
            openJobs = _parseRequestList(s.docs, 'workerOpen');
            emit();
          },
          onError: (e) {
            logError('streamWorkerServiceRequests.open', e);
            if (!controller.isClosed) controller.addError(e);
          },
        );
      },
      onCancel: () {
        assignedSub?.cancel();
        openSub?.cancel();
      },
    );

    return controller.stream;
  }

  Stream<List<ServiceRequestEnhancedModel>> streamAvailableRequests({
    required int wilayaCode,
    required String serviceType,
  }) {
    return firestore
        .collection(serviceRequestsCollection)
        .where('wilayaCode', isEqualTo: wilayaCode)
        .where('serviceType', isEqualTo: serviceType)
        .where('status', whereIn: [
          ServiceStatus.open.name,
          ServiceStatus.awaitingSelection.name,
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) => logError('streamAvailableRequests', e))
        .map((s) =>
            _parseRequestList(s.docs, 'streamAvailableRequests'));
  }

  Stream<List<ServiceRequestEnhancedModel>> streamWorkerActiveJobs(
      String workerId) {
    if (workerId.trim().isEmpty) {
      logWarning('streamWorkerActiveJobs called with empty workerId');
      return Stream.value([]);
    }
    return firestore
        .collection(serviceRequestsCollection)
        .where('workerId', isEqualTo: workerId)
        .where('status', whereIn: [
          ServiceStatus.bidSelected.name,
          ServiceStatus.inProgress.name,
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) => logError('streamWorkerActiveJobs', e))
        .map((s) =>
            _parseRequestList(s.docs, 'streamWorkerActiveJobs'));
  }

  // --------------------------------------------------------------------------
  // TASK 2 — WORKER HOME ASSIGNED REQUESTS STREAM
  // --------------------------------------------------------------------------

  /// Streams service requests assigned to [workerId], ordered by createdAt
  /// descending, limited to [limit] docs.
  ///
  /// This is a simpler single-stream query vs. streamWorkerServiceRequests
  /// (which merges assigned + open marketplace listings for the browse view).
  /// WorkerHomeController uses this for the dashboard summary — only requests
  /// with this worker's ID, no open marketplace entries.
  ///
  /// Previously WorkerHomeController._subscribeToRequests() constructed this
  /// query directly via FirebaseFirestore.instance. Now fully injected through
  /// firestoreServiceProvider, making the controller testable.
  Stream<List<ServiceRequestEnhancedModel>> streamWorkerAssignedRequests(
      String workerId, {int limit = 30}) {
    if (workerId.trim().isEmpty) {
      logWarning('streamWorkerAssignedRequests called with empty workerId');
      return Stream.value([]);
    }
    return firestore
        .collection(serviceRequestsCollection)
        .where('workerId', isEqualTo: workerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((Object e) =>
            logError('streamWorkerAssignedRequests', e))
        .map((s) =>
            _parseRequestList(s.docs, 'streamWorkerAssignedRequests'));
  }

  // --------------------------------------------------------------------------
  // WORKER BIDS — CRUD
  // --------------------------------------------------------------------------

  Stream<List<WorkerBidModel>> streamBidsForRequest(String requestId) {
    if (requestId.trim().isEmpty) {
      logWarning('streamBidsForRequest called with empty requestId');
      return Stream.value([]);
    }
    return firestore
        .collection(workerBidsCollection)
        .where('serviceRequestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .handleError((e) => logError('streamBidsForRequest', e))
        .map((s) => _parseBidList(s.docs, 'streamBidsForRequest'));
  }

  Stream<List<WorkerBidModel>> streamWorkerBids(String workerId) {
    if (workerId.trim().isEmpty) {
      logWarning('streamWorkerBids called with empty workerId');
      return Stream.value([]);
    }
    return firestore
        .collection(workerBidsCollection)
        .where('workerId', isEqualTo: workerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) => logError('streamWorkerBids', e))
        .map((s) => _parseBidList(s.docs, 'streamWorkerBids'));
  }

  Future<WorkerBidModel> createBid(WorkerBidModel bid) async {
    ensureNotDisposed();
    if (bid.id.trim().isEmpty) {
      throw FirestoreServiceException('Bid ID cannot be empty',
          code: 'INVALID_BID_ID');
    }
    return retryOperation(() async {
      try {
        await firestore
            .collection(workerBidsCollection)
            .doc(bid.id)
            .set(bid.toMap())
            .timeout(FirestoreRepositoryBase.operationTimeout);
        logInfo('Bid created: ${bid.id}');
        return bid;
      } catch (e) {
        logError('createBid', e);
        throw FirestoreServiceException('Error creating bid',
            code: 'BID_CREATE_FAILED', originalError: e);
      }
    });
  }

  // --------------------------------------------------------------------------
  // BID LIFECYCLE
  // --------------------------------------------------------------------------

  Future<void> acceptBidTransaction({
    required String requestId,
    required String bidId,
    required String workerId,
    required String workerName,
    required double agreedPrice,
  }) async {
    ensureNotDisposed();
    try {
      final requestRef = firestore
          .collection(serviceRequestsCollection)
          .doc(requestId);

      await firestore.runTransaction((tx) async {
        final reqSnap = await tx.get(requestRef);
        if (!reqSnap.exists || reqSnap.data() == null) {
          throw FirestoreServiceException(
            'Request not found: $requestId',
            code: 'REQUEST_NOT_FOUND',
          );
        }
        final req = ServiceRequestEnhancedModel.fromMap(
            reqSnap.data()!, reqSnap.id);
        if (req.status != ServiceStatus.awaitingSelection &&
            req.status != ServiceStatus.open) {
          throw FirestoreServiceException(
            'Cannot accept bid — invalid state',
            code: 'INVALID_REQUEST_STATE',
          );
        }
        tx.update(
          firestore.collection(workerBidsCollection).doc(bidId),
          {
            'status': BidStatus.accepted.name,
            'acceptedAt': Timestamp.now(),
          },
        );
        tx.update(requestRef, {
          'status': ServiceStatus.bidSelected.name,
          'selectedBidId': bidId,
          'workerId': workerId,
          'workerName': workerName,
          'agreedPrice': agreedPrice,
          'bidSelectedAt': Timestamp.now(),
        });
      }).timeout(const Duration(seconds: 20));

      final others = await firestore
          .collection(workerBidsCollection)
          .where('serviceRequestId', isEqualTo: requestId)
          .where('status', isEqualTo: BidStatus.pending.name)
          .limit(_maxBidsToDecline)
          .get()
          .timeout(FirestoreRepositoryBase.operationTimeout);

      final batch = firestore.batch();
      for (final doc in others.docs) {
        if (doc.id != bidId) {
          batch.update(doc.reference,
              {'status': BidStatus.declined.name});
        }
      }
      if (others.docs.isNotEmpty) {
        await batch
            .commit()
            .timeout(FirestoreRepositoryBase.operationTimeout);
      }

      logInfo('Bid accepted: $bidId → request $requestId bidSelected');
    } catch (e) {
      logError('acceptBidTransaction', e);
      if (e is FirestoreServiceException) rethrow;
      throw FirestoreServiceException('Error accepting bid',
          code: 'BID_ACCEPT_FAILED', originalError: e);
    }
  }

  Future<void> withdrawBid({
    required String bidId,
    required String requestId,
  }) async {
    ensureNotDisposed();
    try {
      await firestore.runTransaction((tx) async {
        final bidRef =
            firestore.collection(workerBidsCollection).doc(bidId);
        final snap = await tx.get(bidRef);
        if (!snap.exists) {
          throw FirestoreServiceException('Bid not found: $bidId',
              code: 'BID_NOT_FOUND');
        }
        final bid =
            WorkerBidModel.fromMap(snap.data()!, snap.id);
        if (bid.status != BidStatus.pending) {
          throw FirestoreServiceException(
              'Can only withdraw pending bids',
              code: 'INVALID_BID_STATE');
        }
        tx.update(bidRef, {'status': BidStatus.withdrawn.name});
        tx.update(
          firestore
              .collection(serviceRequestsCollection)
              .doc(requestId),
          {'bidCount': FieldValue.increment(-1)},
        );
      }).timeout(const Duration(seconds: 15));
      logInfo('Bid withdrawn: $bidId');
    } catch (e) {
      logError('withdrawBid', e);
      if (e is FirestoreServiceException) rethrow;
      throw FirestoreServiceException('Error withdrawing bid',
          code: 'BID_WITHDRAW_FAILED', originalError: e);
    }
  }

  // --------------------------------------------------------------------------
  // JOB LIFECYCLE
  // --------------------------------------------------------------------------

  Future<void> startJob(String requestId) async {
    ensureNotDisposed();
    await _updateRequestStatus(requestId, ServiceStatus.inProgress,
        extras: {'acceptedAt': Timestamp.now()});
    logInfo('Job started: $requestId');
  }

  Future<void> completeJob({
    required String requestId,
    String? workerNotes,
    double? finalPrice,
  }) async {
    ensureNotDisposed();
    await _updateRequestStatus(requestId, ServiceStatus.completed,
        extras: {
          'completedAt': Timestamp.now(),
          if (workerNotes != null) 'workerNotes': workerNotes,
          if (finalPrice != null) 'finalPrice': finalPrice,
        });
    logInfo('Job completed: $requestId');
  }

  Future<void> cancelRequest(String requestId) async {
    ensureNotDisposed();
    await _updateRequestStatus(requestId, ServiceStatus.cancelled);
    logInfo('Request cancelled: $requestId');
  }

  Future<void> _updateRequestStatus(
    String requestId,
    ServiceStatus status, {
    Map<String, dynamic> extras = const {},
  }) async {
    if (requestId.trim().isEmpty) {
      throw FirestoreServiceException('requestId cannot be empty',
          code: 'INVALID_REQUEST_ID');
    }
    await retryOperation(() async {
      try {
        await firestore
            .collection(serviceRequestsCollection)
            .doc(requestId)
            .update({'status': status.name, ...extras})
            .timeout(FirestoreRepositoryBase.operationTimeout);
      } catch (e) {
        logError('_updateRequestStatus', e);
        throw FirestoreServiceException('Error updating request status',
            code: 'STATUS_UPDATE_FAILED', originalError: e);
      }
    });
  }

  // --------------------------------------------------------------------------
  // RATING
  // --------------------------------------------------------------------------

  Future<void> submitClientRating({
    required String requestId,
    required int stars,
    String? comment,
  }) async {
    ensureNotDisposed();

    if (stars < 1 || stars > 5) {
      throw FirestoreServiceException('Stars must be 1–5',
          code: 'INVALID_RATING');
    }
    if (requestId.trim().isEmpty) {
      throw FirestoreServiceException('Request ID cannot be empty',
          code: 'INVALID_REQUEST_ID');
    }

    try {
      await firestore.runTransaction((tx) async {
        final reqRef = firestore
            .collection(serviceRequestsCollection)
            .doc(requestId);
        final reqSnap = await tx.get(reqRef);

        if (!reqSnap.exists || reqSnap.data() == null) {
          throw FirestoreServiceException(
              'Request not found: $requestId',
              code: 'REQUEST_NOT_FOUND');
        }

        final req = ServiceRequestEnhancedModel.fromMap(
            reqSnap.data()!, reqSnap.id);

        tx.update(reqRef, {
          'clientRating': stars,
          if (comment != null && comment.isNotEmpty)
            'reviewComment': comment,
        });

        if (req.workerId != null && req.workerId!.isNotEmpty) {
          final workerRef =
              firestore.collection('workers').doc(req.workerId!);
          final workerSnap = await tx.get(workerRef);

          final oldCount =
              workerSnap.data()?['ratingCount'] as int? ?? 0;
          final oldAvg =
              (workerSnap.data()?['averageRating'] as num?)
                  ?.toDouble() ??
              0.0;
          final newCount = oldCount + 1;
          final newAvg = ((oldAvg * oldCount) + stars) / newCount;

          tx.update(workerRef, {
            'averageRating': newAvg,
            'ratingCount': newCount,
            'lastRating': stars,
            'lastRatedAt': Timestamp.now(),
          });
        }
      }).timeout(FirestoreRepositoryBase.operationTimeout);

      logInfo('Rating submitted: $stars ★ for $requestId');
    } catch (e) {
      logError('submitClientRating', e);
      if (e is FirestoreServiceException) rethrow;
      throw FirestoreServiceException('Error submitting rating',
          code: 'RATING_FAILED', originalError: e);
    }
  }

  // --------------------------------------------------------------------------
  // NOTIFICATIONS
  // --------------------------------------------------------------------------

  Future<void> createNotification(NotificationModel notification) async {
    ensureNotDisposed();
    if (notification.id.trim().isEmpty) {
      throw FirestoreServiceException(
          'Notification ID cannot be empty',
          code: 'INVALID_NOTIFICATION_ID');
    }
    return retryOperation(() async {
      try {
        await firestore
            .collection(notificationsCollection)
            .doc(notification.id)
            .set(notification.toMap())
            .timeout(FirestoreRepositoryBase.operationTimeout);
        logInfo('Notification created: ${notification.id}');
      } catch (e) {
        logError('createNotification', e);
        rethrow;
      }
    });
  }

  // --------------------------------------------------------------------------
  // HELPERS
  // --------------------------------------------------------------------------

  List<ServiceRequestEnhancedModel> _parseRequestList(
    List<QueryDocumentSnapshot> docs,
    String tag,
  ) {
    return docs
        .map((doc) {
          try {
            return ServiceRequestEnhancedModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id);
          } catch (e) {
            logError('$tag.parsing', e);
            return null;
          }
        })
        .whereType<ServiceRequestEnhancedModel>()
        .toList();
  }

  List<WorkerBidModel> _parseBidList(
    List<QueryDocumentSnapshot> docs,
    String tag,
  ) {
    return docs
        .map((doc) {
          try {
            return WorkerBidModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id);
          } catch (e) {
            logError('$tag.parsing', e);
            return null;
          }
        })
        .whereType<WorkerBidModel>()
        .toList();
  }

  // --------------------------------------------------------------------------
  // DISPOSE
  // --------------------------------------------------------------------------

  void dispose() {
    if (isDisposed) return;
    markDisposed();
    logInfo('ServiceRequestFirestoreRepository disposed');
  }
}
