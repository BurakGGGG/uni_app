import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/admin_report_model.dart';
import '../../reviews/domain/models/review_model.dart';

/// Admin Rapor Repository — Firestore `reports` koleksiyonu üzerinde
/// admin tarafı CRUD işlemleri.
class AdminReportRepository {
  final FirebaseFirestore _firestore;

  AdminReportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

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
    required String adminUserId,
  }) async {
    await _reportsRef.doc(reportId).update({
      'status': status.name,
      'adminNote': ?adminNote,
      'reviewedBy': adminUserId,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Şikayet edilen yorumu gizle (isApproved = false) ────────────
  Future<void> hideReportedReview(String reviewId) async {
    await _reviewsRef.doc(reviewId).update({'isApproved': false});
  }

  // ─── Gizlenen yorumu geri aç (isApproved = true) ─────────────────
  Future<void> unhideReview(String reviewId) async {
    await _reviewsRef.doc(reviewId).update({'isApproved': true});
  }

  // ─── Şikayet edilen yorumu kalıcı sil ────────────────────────────
  Future<void> deleteReportedReview(
    String reviewId,
    List<String> photoUrls,
  ) async {
    // 1. Firestore'dan sil
    await _reviewsRef.doc(reviewId).delete();

    // 2. Fotoğrafları sil (best effort)
    for (final url in photoUrls) {
      try {
        await FirebaseStorage.instance.refFromURL(url).delete();
      } catch (e) {
        debugPrint('[AdminReport] Photo delete failed: $e');
      }
    }
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

  // ─── Bir rapora ait bildirim gönder (yorum sahibine) ─────────────
  Future<void> sendReportActionNotification({
    required String reviewOwnerId,
    required String action, // 'hidden' veya 'deleted'
    String? adminNote,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': reviewOwnerId,
      'type': 'review_moderated',
      'title': action == 'deleted' ? 'Yorumunuz silindi' : 'Yorumunuz gizlendi',
      'body': action == 'deleted'
          ? 'Topluluk kurallarına aykırı bulunan yorumunuz kaldırıldı.'
          : 'Topluluk kurallarına aykırı bulunan yorumunuz gizlendi.',
      'data': {'adminNote': ?adminNote},
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
