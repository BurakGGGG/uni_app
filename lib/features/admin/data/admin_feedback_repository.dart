import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/admin_feedback_model.dart';

/// Admin Feedback Repository — Firestore `feedback` koleksiyonu üzerinde
/// admin tarafı CRUD işlemleri.
class AdminFeedbackRepository {
  final FirebaseFirestore _firestore;

  AdminFeedbackRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _feedbackRef =>
      _firestore.collection('feedback');

  // ─── Stream: Tüm feedbackleri dinle ───────────────────────────────
  Stream<List<AdminFeedbackModel>> watchAllFeedback() {
    return _feedbackRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AdminFeedbackModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ─── Stream: Belirli statüdeki feedbackleri dinle ─────────────────
  Stream<List<AdminFeedbackModel>> watchFeedbackByStatus(
      FeedbackStatus status) {
    return _feedbackRef
        .where('status', isEqualTo: status.firestoreValue)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AdminFeedbackModel.fromMap(d.data(), d.id))
            .toList());
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
    required String adminUserId,
  }) async {
    await _feedbackRef.doc(feedbackId).update({
      'status': status.firestoreValue,
      if (adminNote != null) 'adminNote': adminNote,
      'reviewedBy': adminUserId,
    });
  }

  // ─── Feedback sil ────────────────────────────────────────────────
  Future<void> deleteFeedback(String feedbackId) async {
    await _feedbackRef.doc(feedbackId).delete();
  }
}
