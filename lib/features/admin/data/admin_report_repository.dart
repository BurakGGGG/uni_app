import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../domain/models/admin_report_model.dart';
import '../../reviews/domain/models/review_model.dart';

/// Admin Rapor Repository — Firestore `reports` koleksiyonu üzerinde
/// admin tarafı CRUD işlemleri.
class AdminReportRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  AdminReportRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      _firestore.collection('reports');

  CollectionReference<Map<String, dynamic>> get _reviewsRef =>
      _firestore.collection('reviews');

  // ─── Stream: Tüm raporları dinle ──────────────────────────────────
  Stream<List<AdminReportModel>> watchAllReports() {
    return _reportsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdminReportModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // ─── Stream: Belirli statüdeki raporları dinle ────────────────────
  Stream<List<AdminReportModel>> watchReportsByStatus(ReportStatus status) {
    return _reportsRef
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdminReportModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // ─── Stream: Bekleyen rapor sayısı (badge) ────────────────────────
  Stream<int> watchPendingReportCount() {
    // status alanı olmayanlar da pending kabul edileceğinden,
    // tüm raporları çekip client-side filtre yapıyoruz
    return _reportsRef.snapshots().map((snap) {
      return snap.docs.where((d) {
        final status = d.data()['status'] as String?;
        return status == null || status == 'pending';
      }).length;
    });
  }

  // ─── Bir yoruma ait tüm şikayetleri getir ────────────────────────
  Stream<List<AdminReportModel>> watchReportsForReview(String reviewId) {
    return _reportsRef
        .where('reviewId', isEqualTo: reviewId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdminReportModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // ─── Rapor durumunu güncelle ──────────────────────────────────────
  Future<void> updateReportStatus(
    String reportId, {
    required ReportStatus status,
    String? adminNote,
  }) async {
    await _callAdminAction({
      'action': 'updateReportStatus',
      'reportId': reportId,
      'status': status.name,
      'adminNote': ?adminNote,
    });
  }

  // ─── Şikayet edilen yorumu gizle (isApproved = false) ────────────
  Future<void> hideReportedReview(
    String reviewId, {
    String? reportId,
    String? adminNote,
  }) async {
    await _callAdminAction({
      'action': 'hideReview',
      'reviewId': reviewId,
      'reportId': ?reportId,
      'adminNote': ?adminNote,
    });
  }

  // ─── Gizlenen yorumu geri aç (isApproved = true) ─────────────────
  Future<void> unhideReview(String reviewId) async {
    await _callAdminAction({'action': 'unhideReview', 'reviewId': reviewId});
  }

  // ─── Şikayet edilen yorumu kalıcı sil ────────────────────────────
  Future<void> deleteReportedReview(
    String reviewId, {
    String? reportId,
    String? adminNote,
  }) async {
    await _callAdminAction({
      'action': 'deleteReview',
      'reviewId': reviewId,
      'reportId': ?reportId,
      'adminNote': ?adminNote,
    });
  }

  // ─── Engellenen (isApproved=false) yorumları dinle ────────────────
  Stream<List<ReviewModel>> watchBlockedReviews() {
    return _reviewsRef
        .where('isApproved', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ReviewModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // ─── Belirli bir yoruma ait şikayet sayısını getir ────────────────
  Future<int> getReportCountForReview(String reviewId) async {
    final snap = await _reportsRef
        .where('reviewId', isEqualTo: reviewId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<void> _callAdminAction(Map<String, Object?> payload) async {
    final callable = _functions.httpsCallable(
      'performAdminModerationAction',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    await callable.call<Object?>(payload);
  }
}
