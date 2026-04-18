import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/review_model.dart';

/// Yorum repository — Sprint 3'te doldurulacak
///
/// Firestore path: reviews/{reviewId}
/// Index: universityId + createdAt (composite)
class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ignore: unused_element
  CollectionReference<Map<String, dynamic>> get _reviewsRef =>
      _firestore.collection('reviews');

  // TODO(sprint3): Yorum ekleme
  Future<void> addReview(ReviewModel review) async {
    throw UnimplementedError('Sprint 3\'te implemente edilecek');
  }

  // TODO(sprint3): Yorum güncelleme
  Future<void> updateReview(ReviewModel review) async {
    throw UnimplementedError('Sprint 3\'te implemente edilecek');
  }

  // TODO(sprint3): Yorum silme
  Future<void> deleteReview(String reviewId) async {
    throw UnimplementedError('Sprint 3\'te implemente edilecek');
  }

  // TODO(sprint3): Üniversiteye ait yorumları getir
  Stream<List<ReviewModel>> getUniversityReviews(String universityId) {
    throw UnimplementedError('Sprint 3\'te implemente edilecek');
  }

  // TODO(sprint3): Bölüme ait yorumları getir
  Stream<List<ReviewModel>> getDepartmentReviews(String departmentId) {
    throw UnimplementedError('Sprint 3\'te implemente edilecek');
  }

  // TODO(sprint3): Son yorumları getir (ana sayfa için)
  Stream<List<ReviewModel>> getRecentReviews({int limit = 10}) {
    throw UnimplementedError('Sprint 3\'te implemente edilecek');
  }

  // TODO(sprint3): Kullanıcının yorumlarını getir
  Stream<List<ReviewModel>> getUserReviews(String userId) {
    throw UnimplementedError('Sprint 3\'te implemente edilecek');
  }

  // TODO(sprint3): Yorum beğenme
  Future<void> likeReview(String reviewId, String userId) async {
    throw UnimplementedError('Sprint 3\'te implemente edilecek');
  }
}
