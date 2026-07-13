import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../domain/models/review_model.dart';
import '../../admin/data/analytics_service.dart';
import '../../admin/domain/models/analytics_event.dart';

/// Yorum repository — Sprint 3'te doldurulacak
///
/// Firestore path: reviews/{reviewId}
/// Index: universityId + createdAt (composite)
class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  // ignore: unused_element
  CollectionReference<Map<String, dynamic>> get _reviewsRef =>
      _firestore.collection('reviews');

  Future<ReviewModel?> getReview(String reviewId) async {
    final doc = await _firestore.collection('reviews').doc(reviewId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ReviewModel.fromMap(doc.data()!, doc.id);
  }

  /// Kullanıcı bu hedefe daha önce yorum yazmış mı? (tek seferlik sorgu)
  ///
  /// Rules owner okumasına izin verir; onay beklemedeki yorumlar da sayılır
  /// ki kullanıcıya gereksiz "yorum yaz" istemi gösterilmesin.
  Future<bool> hasUserReviewed({
    required String userId,
    required String targetId,
    required ReviewType type,
  }) async {
    final snap = await _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .where('targetId', isEqualTo: targetId)
        .where('type', isEqualTo: type.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> addReview(ReviewModel review) async {
    try {
      await _functions
          .httpsCallable(
            'submitReview',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
          )
          .call(<String, dynamic>{
            'type': review.type.name,
            'targetId': review.targetId,
            'universityId': review.universityId,
            'rating': review.rating,
            'categoryRatings': review.categoryRatings,
            'comment': review.comment,
            'pros': review.pros,
            'cons': review.cons,
            'imageUrls': review.imageUrls,
            'isAnonymous': review.isAnonymous,
          });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        throw const ReviewRateLimitedException();
      }
      throw ReviewSubmissionException(
        e.message ?? 'Yorum gönderilirken bir hata oluştu.',
      );
    }

    // Analytics: yeni yorum
    AnalyticsService.instance.trackEvent(AnalyticsEvent.reviewCreated);
  }

  Future<ReviewSubmissionStatus> getSubmissionStatus() async {
    try {
      final result = await _functions
          .httpsCallable(
            'getReviewSubmissionStatus',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
          )
          .call();
      return ReviewSubmissionStatus.fromMap(
        Map<String, dynamic>.from(result.data as Map),
      );
    } on FirebaseFunctionsException catch (e) {
      throw ReviewSubmissionException(
        e.message ?? 'Yorum hakkı kontrol edilirken bir hata oluştu.',
      );
    }
  }

  Future<void> updateReview(ReviewModel review) async {
    await _firestore.collection('reviews').doc(review.id).update({
      'userName': review.userName,
      'userPhotoUrl': review.userPhotoUrl,
      'userUniversity': review.userUniversity,
      'rating': review.rating,
      'categoryRatings': review.categoryRatings,
      'comment': review.comment,
      'pros': review.pros,
      'cons': review.cons,
      'imageUrls': review.imageUrls,
      'isAnonymous': review.isAnonymous,
      'isApproved': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReview(String reviewId, List<String> photoUrls) async {
    // 1. Firestore'dan sil
    await _firestore.collection('reviews').doc(reviewId).delete();

    // 2. Fotoğrafları sil (best effort)
    for (final url in photoUrls) {
      try {
        await FirebaseStorage.instance.refFromURL(url).delete();
      } catch (e) {
        debugPrint('Photo delete failed: $e');
      }
    }
  }

  // Üniversiteye ait yorumları getir (sort destekli)
  Stream<List<ReviewModel>> getUniversityReviews(
    String universityId, {
    int limit = 20,
    String orderBy = 'createdAt',
  }) {
    return _reviewsRef
        .where('targetId', isEqualTo: universityId)
        .where('isApproved', isEqualTo: true)
        .orderBy(orderBy, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Tüm yorumları (Bölüm, Mekan, Üniversite karışık) universityId'ye göre getir
  Stream<List<ReviewModel>> getAllReviewsForUniversity(
    String universityId, {
    int limit = 50,
    String orderBy = 'createdAt',
  }) {
    return _reviewsRef
        .where('universityId', isEqualTo: universityId)
        .where('isApproved', isEqualTo: true)
        .orderBy(orderBy, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Bölüme ait yorumları getir (sort destekli)
  Stream<List<ReviewModel>> getDepartmentReviews(
    String departmentId, {
    int limit = 20,
    String orderBy = 'createdAt',
  }) {
    return _reviewsRef
        .where('targetId', isEqualTo: departmentId)
        .where('isApproved', isEqualTo: true)
        .orderBy(orderBy, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<ReviewModel>> getRecentReviews({int limit = 10}) {
    return _reviewsRef
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<ReviewModel>> getUserReviews(String userId) {
    return _reviewsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Başka bir kullanıcının profilinde gösterilecek yorumlar.
  ///
  /// Güvenlik kuralları onaysız yorumların sadece sahibi tarafından
  /// okunmasına izin verir; isApproved filtresi olmadan sorgu tümüyle
  /// permission-denied alır. Bu yüzden [getUserReviews]'tan ayrıdır.
  Stream<List<ReviewModel>> getUserPublicReviews(String userId) {
    return _reviewsRef
        .where('userId', isEqualTo: userId)
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Sprint 4 — Mekana ait yorumları getir (sort destekli)
  Stream<List<ReviewModel>> getPlaceReviews(
    String placeId, {
    int limit = 20,
    String orderBy = 'createdAt',
  }) {
    return _reviewsRef
        .where('targetId', isEqualTo: placeId)
        .where('type', isEqualTo: 'place')
        .where('isApproved', isEqualTo: true)
        .orderBy(orderBy, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Sprint 4 — Mekana ait onaylı yorum sayısı
  Future<int> getPlaceReviewCount(String placeId) async {
    final snap = await _reviewsRef
        .where('targetId', isEqualTo: placeId)
        .where('type', isEqualTo: 'place')
        .where('isApproved', isEqualTo: true)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<void> likeReview(String reviewId, String userId) async {
    // İki referans: review altındaki like + user altındaki likedReview
    final reviewLikeRef = _firestore
        .collection('reviews')
        .doc(reviewId)
        .collection('likes')
        .doc(userId);

    final userLikedRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('likedReviews')
        .doc(reviewId);

    // Atomik batch
    final batch = _firestore.batch();

    final doc = await reviewLikeRef.get();

    if (doc.exists) {
      // Unlike
      batch.delete(reviewLikeRef);
      batch.delete(userLikedRef);
    } else {
      // Like
      final ts = FieldValue.serverTimestamp();
      batch.set(reviewLikeRef, {'createdAt': ts});
      batch.set(userLikedRef, {'createdAt': ts, 'reviewId': reviewId});

      // Analytics: beğeni
      AnalyticsService.instance.trackEvent(AnalyticsEvent.reviewLiked);
    }

    await batch.commit();
  }

  /// Tüm yorumları filtrele ve stream olarak döndür.
  Stream<List<ReviewModel>> getAllReviews({
    String? universityId,
    ReviewType? reviewType,
    int limit = 50,
    String orderBy = 'createdAt',
  }) {
    Query<Map<String, dynamic>> query = _reviewsRef.where(
      'isApproved',
      isEqualTo: true,
    );

    if (reviewType != null) {
      query = query.where('type', isEqualTo: reviewType.name);
    }

    if (universityId != null) {
      query = query.where('universityId', isEqualTo: universityId);
    }

    query = query.orderBy(orderBy, descending: true).limit(limit);

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }
}

class ReviewRateLimitedException implements Exception {
  const ReviewRateLimitedException();
}

class ReviewSubmissionException implements Exception {
  final String message;

  const ReviewSubmissionException(this.message);

  @override
  String toString() => message;
}

class ReviewSubmissionStatus {
  final bool allowed;
  final int currentCount;
  final int remaining;
  final int limit;
  final int retryAfterSeconds;

  const ReviewSubmissionStatus({
    required this.allowed,
    required this.currentCount,
    required this.remaining,
    required this.limit,
    required this.retryAfterSeconds,
  });

  factory ReviewSubmissionStatus.fromMap(Map<String, dynamic> map) {
    return ReviewSubmissionStatus(
      allowed: map['allowed'] == true,
      currentCount: (map['currentCount'] as num?)?.toInt() ?? 0,
      remaining: (map['remaining'] as num?)?.toInt() ?? 0,
      limit: (map['limit'] as num?)?.toInt() ?? 0,
      retryAfterSeconds: (map['retryAfterSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}
