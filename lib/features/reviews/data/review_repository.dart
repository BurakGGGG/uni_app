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

  Future<ReviewModel?> getReview(String reviewId) async {
    final doc = await _firestore.collection('reviews').doc(reviewId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ReviewModel.fromMap(doc.data()!, doc.id);
  }

  // TODO(sprint3): Yorum ekleme
  Future<void> addReview(ReviewModel review) async {
    final docRef = _firestore.collection('reviews').doc();
    await docRef.set(review.toMap());
    
    // Kullanıcının reviewCount alanını artır
    await _firestore.collection('users').doc(review.userId).update({
      'reviewCount': FieldValue.increment(1),
    });
  }

  // TODO(sprint3): Yorum güncelleme
  Future<void> updateReview(ReviewModel review) async {
    await _firestore.collection('reviews').doc(review.id).update({
      ...review.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // TODO(sprint3): Yorum silme
  Future<void> deleteReview(String reviewId, String userId) async {
    await _firestore.collection('reviews').doc(reviewId).delete();
    
    // Kullanıcının reviewCount alanını azalt
    await _firestore.collection('users').doc(userId).update({
      'reviewCount': FieldValue.increment(-1),
    });
  }

  // Üniversiteye ait yorumları getir (sort destekli)
  Stream<List<ReviewModel>> getUniversityReviews(String universityId, {int limit = 20, String orderBy = 'createdAt'}) {
    return _reviewsRef
        .where('targetId', isEqualTo: universityId)
        .where('isApproved', isEqualTo: true)
        .orderBy(orderBy, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Bölüme ait yorumları getir (sort destekli)
  Stream<List<ReviewModel>> getDepartmentReviews(String departmentId, {int limit = 20, String orderBy = 'createdAt'}) {
    return _reviewsRef
        .where('targetId', isEqualTo: departmentId)
        .where('isApproved', isEqualTo: true)
        .orderBy(orderBy, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // TODO(sprint3): Son yorumları getir (ana sayfa için)
  Stream<List<ReviewModel>> getRecentReviews({int limit = 10}) {
    return _reviewsRef
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // TODO(sprint3): Kullanıcının yorumlarını getir
  Stream<List<ReviewModel>> getUserReviews(String userId) {
    return _reviewsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // TODO(sprint3): Yorum beğenme
  Future<void> likeReview(String reviewId, String userId) async {
    final likeRef = _firestore
        .collection('reviews')
        .doc(reviewId)
        .collection('likes')
        .doc(userId);

    final doc = await likeRef.get();
    
    if (doc.exists) {
      await likeRef.delete();
      await _firestore.collection('reviews').doc(reviewId).update({
        'likes': FieldValue.increment(-1),
      });
    } else {
      await likeRef.set({
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('reviews').doc(reviewId).update({
        'likes': FieldValue.increment(1),
      });
    }
  }
}
