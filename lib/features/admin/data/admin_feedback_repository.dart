import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../domain/models/admin_feedback_model.dart';

/// Admin Feedback Repository — Firestore `feedback` koleksiyonu üzerinde
/// admin tarafı CRUD işlemleri.
class AdminFeedbackRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  AdminFeedbackRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  CollectionReference<Map<String, dynamic>> get _feedbackRef =>
      _firestore.collection('feedback');

  // ─── Stream: Tüm feedbackleri dinle ───────────────────────────────
  Stream<List<AdminFeedbackModel>> watchAllFeedback() {
    return _feedbackRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdminFeedbackModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // ─── Stream: Belirli statüdeki feedbackleri dinle ─────────────────
  Stream<List<AdminFeedbackModel>> watchFeedbackByStatus(
    FeedbackStatus status,
  ) {
    return _feedbackRef
        .where('status', isEqualTo: status.firestoreValue)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdminFeedbackModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // ─── Stream: Yeni feedback sayısı (badge) ─────────────────────────
  Stream<int> watchNewFeedbackCount() {
    return _feedbackRef
        .where('status', isEqualTo: 'new')
        .snapshots()
        .map((snap) => snap.size);
  }

  // ─── Feedback statüsünü güncelle ──────────────────────────────────
  Future<void> updateFeedbackStatus(
    String feedbackId, {
    required FeedbackStatus status,
    String? adminNote,
  }) async {
    await _callAdminAction({
      'action': 'updateFeedbackStatus',
      'feedbackId': feedbackId,
      'status': status.firestoreValue,
      'adminNote': ?adminNote,
    });
  }

  // ─── Feedback sil ────────────────────────────────────────────────
  Future<void> deleteFeedback(String feedbackId) async {
    await _callAdminAction({
      'action': 'deleteFeedback',
      'feedbackId': feedbackId,
    });
  }

  Future<void> _callAdminAction(Map<String, Object?> payload) async {
    final callable = _functions.httpsCallable(
      'performAdminModerationAction',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    await callable.call<Object?>(payload);
  }
}
