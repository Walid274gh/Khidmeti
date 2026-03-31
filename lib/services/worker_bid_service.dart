// lib/services/worker_bid_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/service_request_enhanced_model.dart';
import '../models/worker_bid_model.dart';
import '../models/worker_model.dart';
import '../models/message_enums.dart';
import '../utils/constants.dart';
import 'firestore_service.dart';

/// High-level service for the Hybrid Bid Model.
/// Wraps FirestoreService with business-logic validation and worker data
/// enrichment so controllers stay thin.
class WorkerBidService {
  final FirestoreService _firestore;
  bool _isDisposed = false;

  static const String _pendingBidMarkersCollection = 'pending_bid_markers';

  WorkerBidService(this._firestore);

  bool get isDisposed => _isDisposed;

  // =========================================================================
  // BROWSING — available requests for a worker
  // =========================================================================

  Stream<List<ServiceRequestEnhancedModel>> streamAvailableRequests({
    required int wilayaCode,
    required String serviceType,
  }) {
    _ensureNotDisposed();
    return _firestore.streamAvailableRequests(
      wilayaCode: wilayaCode,
      serviceType: serviceType,
    );
  }

  Stream<List<ServiceRequestEnhancedModel>> streamWorkerActiveJobs(
      String workerId) {
    _ensureNotDisposed();
    return _firestore.streamWorkerActiveJobs(workerId);
  }

  Stream<List<WorkerBidModel>> streamWorkerBids(String workerId) {
    _ensureNotDisposed();
    return _firestore.streamWorkerBids(workerId);
  }

  // =========================================================================
  // BID SUBMISSION
  // =========================================================================

  /// FIX (Security): verify caller identity before submitting.
  /// FIX (Critical): status check supports both .name and legacy .toString()
  ///   formats for backward compatibility with existing Firestore documents.
  /// FIX (Critical): status write uses .name ('awaitingSelection') to match
  ///   what ServiceRequestEnhancedModel.toMap() writes.
  Future<WorkerBidModel> submitBid({
    required String requestId,
    required WorkerModel worker,
    required double proposedPrice,
    required int estimatedMinutes,
    required DateTime availableFrom,
    String? message,
  }) async {
    _ensureNotDisposed();

    // FIX: Verify the caller is actually the worker they claim to be.
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != worker.id) {
      throw WorkerBidServiceException(
        'Cannot submit bid: authenticated user does not match worker identity',
        code: 'AUTH_MISMATCH',
      );
    }

    if (proposedPrice <= 0) {
      throw WorkerBidServiceException(
        'Proposed price must be greater than 0',
        code: 'INVALID_PRICE',
      );
    }
    if (estimatedMinutes <= 0) {
      throw WorkerBidServiceException(
        'Estimated duration must be greater than 0',
        code: 'INVALID_DURATION',
      );
    }

    final bidId = const Uuid().v4();
    final deadline = DateTime.now().add(
      const Duration(minutes: AppConstants.biddingDeadlineMinutes),
    );

    final bid = WorkerBidModel(
      id: bidId,
      serviceRequestId: requestId,
      workerId: worker.id,
      workerName: worker.name,
      workerAverageRating: worker.averageRating,
      workerJobsCompleted: worker.ratingCount,
      workerProfileImageUrl: worker.profileImageUrl,
      proposedPrice: proposedPrice,
      estimatedMinutes: estimatedMinutes,
      availableFrom: availableFrom,
      message: message?.trim().isEmpty ?? true ? null : message!.trim(),
      status: BidStatus.pending,
      createdAt: DateTime.now(),
      expiresAt: deadline,
    );

    final markerDocId = '${worker.id}_$requestId';
    final markerRef = _firestore.firestore
        .collection(_pendingBidMarkersCollection)
        .doc(markerDocId);
    final bidRef = _firestore.firestore
        .collection(FirestoreService.workerBidsCollection)
        .doc(bidId);
    final requestRef = _firestore.firestore
        .collection(FirestoreService.serviceRequestsCollection)
        .doc(requestId);

    try {
      await _firestore.firestore.runTransaction((tx) async {
        final markerSnap = await tx.get(markerRef);
        if (markerSnap.exists) {
          throw WorkerBidServiceException(
            'You already have a pending bid on this request',
            code: 'DUPLICATE_BID',
          );
        }

        final reqSnap = await tx.get(requestRef);
        if (!reqSnap.exists || reqSnap.data() == null) {
          throw WorkerBidServiceException(
            'Request not found: $requestId',
            code: 'REQUEST_NOT_FOUND',
          );
        }

        final reqData = reqSnap.data()!;
        final statusStr = reqData['status'] as String? ?? '';

        // FIX: accept both .name ('open', 'awaitingSelection') and legacy
        // .toString() ('ServiceStatus.open', 'ServiceStatus.awaitingSelection')
        // formats so the check works regardless of which write path created
        // the document.
        final isOpen =
            statusStr == ServiceStatus.open.name ||
            statusStr == ServiceStatus.awaitingSelection.name ||
            statusStr == ServiceStatus.open.toString() ||
            statusStr == ServiceStatus.awaitingSelection.toString();

        if (!isOpen) {
          throw WorkerBidServiceException(
            'Request is no longer accepting bids',
            code: 'REQUEST_CLOSED',
          );
        }

        tx.set(markerRef, {
          'workerId': worker.id,
          'requestId': requestId,
          'bidId': bidId,
          'createdAt': Timestamp.now(),
        });
        tx.set(bidRef, bid.toMap());
        tx.update(requestRef, {
          'bidCount': FieldValue.increment(1),
          // FIX: use .name ('awaitingSelection') not .toString()
          'status': ServiceStatus.awaitingSelection.name,
        });
      }).timeout(const Duration(seconds: 15));

      _logInfo('Bid submitted atomically: $bidId by ${worker.id} on $requestId');
      return bid;
    } on WorkerBidServiceException {
      rethrow;
    } catch (e) {
      _logError('submitBid', e);
      throw WorkerBidServiceException(
        'Failed to submit bid',
        code: 'SUBMIT_BID_FAILED',
        originalError: e,
      );
    }
  }

  // =========================================================================
  // BID ACCEPTANCE (client action)
  // =========================================================================

  Future<void> acceptBid({
    required String requestId,
    required WorkerBidModel bid,
  }) async {
    _ensureNotDisposed();

    await _firestore.acceptBidTransaction(
      requestId: requestId,
      bidId: bid.id,
      workerId: bid.workerId,
      workerName: bid.workerName,
      agreedPrice: bid.proposedPrice,
    );

    await _deleteMarker(bid.workerId, requestId);

    _logInfo('Bid accepted: ${bid.id} — worker ${bid.workerId} on $requestId');
  }

  // =========================================================================
  // BID WITHDRAWAL (worker action)
  // =========================================================================

  Future<void> withdrawBid({
    required String bidId,
    required String requestId,
  }) async {
    _ensureNotDisposed();

    String? workerId;
    try {
      final snap = await _firestore.firestore
          .collection(FirestoreService.workerBidsCollection)
          .doc(bidId)
          .get()
          .timeout(const Duration(seconds: 10));
      workerId = snap.data()?['workerId'] as String?;
    } catch (_) {
      // Non-fatal: marker cleanup is best-effort.
    }

    await _firestore.withdrawBid(bidId: bidId, requestId: requestId);

    if (workerId != null) {
      await _deleteMarker(workerId, requestId);
    }

    _logInfo('Bid withdrawn: $bidId');
  }

  // =========================================================================
  // JOB LIFECYCLE
  // =========================================================================

  Future<void> startJob(String requestId) async {
    _ensureNotDisposed();
    await _firestore.startJob(requestId);
    _logInfo('Job started: $requestId');
  }

  Future<void> completeJob({
    required String requestId,
    String? workerNotes,
    double? finalPrice,
  }) async {
    _ensureNotDisposed();
    await _firestore.completeJob(
      requestId: requestId,
      workerNotes: workerNotes,
      finalPrice: finalPrice,
    );
    _logInfo('Job completed: $requestId');
  }

  // =========================================================================
  // BIDS STREAM — client side
  // =========================================================================

  Stream<List<WorkerBidModel>> streamBidsForRequest(String requestId) {
    _ensureNotDisposed();
    return _firestore.streamBidsForRequest(requestId).map(
      (bids) {
        final sorted = List<WorkerBidModel>.from(bids)
          ..sort((a, b) {
            final priceCmp = a.proposedPrice.compareTo(b.proposedPrice);
            if (priceCmp != 0) return priceCmp;
            return b.workerAverageRating
                .compareTo(a.workerAverageRating);
          });
        return sorted;
      },
    );
  }

  // =========================================================================
  // RATING
  // =========================================================================

  Future<void> submitClientRating({
    required String requestId,
    required int stars,
    String? comment,
  }) async {
    _ensureNotDisposed();
    await _firestore.submitClientRating(
      requestId: requestId,
      stars: stars,
      comment: comment,
    );
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  Future<void> _deleteMarker(String workerId, String requestId) async {
    try {
      final markerDocId = '${workerId}_$requestId';
      await _firestore.firestore
          .collection(_pendingBidMarkersCollection)
          .doc(markerDocId)
          .delete()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      _logWarning('Could not delete bid marker for $workerId/$requestId: $e');
    }
  }

  void dispose() {
    _isDisposed = true;
    _logInfo('WorkerBidService disposed');
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw WorkerBidServiceException(
        'WorkerBidService has been disposed',
        code: 'SERVICE_DISPOSED',
      );
    }
  }

  void _logInfo(String message) {
    if (kDebugMode) debugPrint('[WorkerBidService] INFO: $message');
  }

  void _logWarning(String message) {
    if (kDebugMode) debugPrint('[WorkerBidService] WARNING: $message');
  }

  void _logError(String method, dynamic error) {
    if (kDebugMode) debugPrint('[WorkerBidService] ERROR in $method: $error');
  }
}

class WorkerBidServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  WorkerBidServiceException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() =>
      'WorkerBidServiceException: $message${code != null ? ' (Code: $code)' : ''}';
}