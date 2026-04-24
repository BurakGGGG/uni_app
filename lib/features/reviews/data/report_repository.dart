import 'package:cloud_firestore/cloud_firestore.dart';

/// Şikayet nedenleri
enum ReportReason {
  inappropriate,
  spam,
  offensive,
  misleading,
  other,
}

extension ReportReasonExt on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.inappropriate:
        return 'Uygunsuz içerik';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.offensive:
        return 'Hakaret / ayrımcılık';
      case ReportReason.misleading:
        return 'Yanıltıcı bilgi';
      case ReportReason.other:
        return 'Diğer';
    }
  }
}

/// Şikayet (Report) veritabanı işlemleri
class ReportRepository {
  final _firestore = FirebaseFirestore.instance;

  /// Bir yorumu şikayet et
  Future<void> reportReview({
    required String reviewId,
    required String userId,
    required ReportReason reason,
    String? explanation,
  }) async {
    final docId = '${reviewId}_$userId';
    await _firestore.collection('reports').doc(docId).set({
      'reviewId': reviewId,
      'userId': userId,
      'reason': reason.name,
      'explanation': explanation,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Bu kullanıcı bu yorumu daha önce şikayet etmiş mi?
  Future<bool> hasAlreadyReported(String reviewId, String userId) async {
    final doc =
        await _firestore.collection('reports').doc('${reviewId}_$userId').get();
    return doc.exists;
  }
}
