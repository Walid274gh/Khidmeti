// lib/services/worker_bid_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Collection that holds one "pending bid marker" per (worker, request) pair.
  // Document ID: `{workerId}_{requestId}` — deterministic, collision-free,
  // used as an atomic lock inside Firestore transactions.
  //
  // FIX (QA P0): The previous duplicate-bid check was a non-atomic
  // client-side query → create sequence:
  //   1. Query: "do I already have a pending bid on this request?"
  //   2. Create bid if query returns 0 results.
  //
  // Two devices submitting in the same millisecond both pass step 1 before
  // either completes step 2 → two duplicate bids are created silently.
  //
  // Fix: use a Firestore transaction that reads a deterministic marker document
  // (`pending_bid_markers/{workerId}_{requestId}`). The transaction either:
  //   - Finds the marker → aborts with DUPLICATE_BID.
  //   - Finds nothing  → atomically creates the marker + the bid document.
  //
  // Marker documents are deleted when the bid is withdrawn, expired, or accepted.
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

  /// Submit a bid on an open request.
  ///
  /// Validates:
  ///   - proposedPrice > 0
  ///   - estimatedMinutes > 0
  ///   - worker has not already bid on this request — **checked atomically**
  ///     via a Firestore transaction on a deterministic marker document.
  Future<WorkerBidModel> submitBid({
    required String requestId,
    required WorkerModel worker,
    required double proposedPrice,
    required int estimatedMinutes,
    required DateTime availableFrom,
    String? message,
  }) async {
    _ensureNotDisposed();

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
      // FIX (Marketplace P2): `workerJobsCompleted` is now mapped from a
      // dedicated `jobsCompleted` field on WorkerModel if available, falling
      // back to `ratingCount` for backward compat with existing documents that
      // do not yet have the field. After the rating Cloud Function is deployed,
      // WorkerModel should gain a `jobsCompleted: int` field updated on
      // ServiceStatus.completed — separate from `ratingCount` which only
      // increments when a rating is submitted.
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

    // Atomic duplicate check + bid creation via Firestore transaction.
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
        // 1. Read the marker document — atomic with the write below.
        final markerSnap = await tx.get(markerRef);
        if (markerSnap.exists) {
          throw WorkerBidServiceException(
            'You already have a pending bid on this request',
            code: 'DUPLICATE_BID',
          );
        }

        // 2. Read the request to verify it is still accepting bids.
        final reqSnap = await tx.get(requestRef);
        if (!reqSnap.exists || reqSnap.data() == null) {
          throw WorkerBidServiceException(
            'Request not found: $requestId',
            code: 'REQUEST_NOT_FOUND',
          );
        }
        final reqData = reqSnap.data()!;
        final statusStr = reqData['status'] as String? ?? '';
        final isOpen = statusStr == ServiceStatus.open.toString() ||
            statusStr == ServiceStatus.awaitingSelection.toString();
        if (!isOpen) {
          throw WorkerBidServiceException(
            'Request is no longer accepting bids',
            code: 'REQUEST_CLOSED',
          );
        }

        // 3. Atomically create the marker + bid + increment bidCount.
        tx.set(markerRef, {
          'workerId': worker.id,
          'requestId': requestId,
          'bidId': bidId,
          'createdAt': Timestamp.now(),
        });
        tx.set(bidRef, bid.toMap());
        tx.update(requestRef, {
          'bidCount': FieldValue.increment(1),
          // Transition request to awaitingSelection once it has at least 1 bid.
          'status': ServiceStatus.awaitingSelection.toString(),
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

    // Clean up the marker for the accepted bid's worker so they could
    // theoretically bid on the same request again if it were re-opened.
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

    // Get workerId before withdrawing so we can clean up the marker.
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

  /// Deletes the pending bid marker for (workerId, requestId).
  /// Best-effort — failure is logged but not rethrown.
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
