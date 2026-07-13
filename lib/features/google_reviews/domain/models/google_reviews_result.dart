/// getGoogleReviews CF yanıtının istemci modeli.
///
/// Places politikası: bu veri hiçbir zaman diske/Firestore'a yazılmaz —
/// yalnızca oturum içi bellekte (Riverpod keepAlive) tutulur ve atıflarla
/// (yazar adı/foto/profil linki + Google) gösterilir.
class GoogleReviewsResult {
  final double rating;
  final int userRatingCount;
  final List<GoogleReview> reviews;

  const GoogleReviewsResult({
    required this.rating,
    required this.userRatingCount,
    required this.reviews,
  });

  factory GoogleReviewsResult.fromMap(Map<String, dynamic> map) {
    return GoogleReviewsResult(
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      userRatingCount: (map['userRatingCount'] as num?)?.toInt() ?? 0,
      reviews: (map['reviews'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((r) => GoogleReview.fromMap(Map<String, dynamic>.from(r)))
          .toList(),
    );
  }

  bool get hasContent => userRatingCount > 0 || reviews.isNotEmpty;
}

class GoogleReview {
  final String authorName;
  final String? authorPhotoUri;
  final String? authorUri;
  final double rating;
  final String text;
  final String relativeTime;

  const GoogleReview({
    required this.authorName,
    this.authorPhotoUri,
    this.authorUri,
    required this.rating,
    required this.text,
    required this.relativeTime,
  });

  factory GoogleReview.fromMap(Map<String, dynamic> map) {
    return GoogleReview(
      authorName: map['authorName'] as String? ?? '',
      authorPhotoUri: map['authorPhotoUri'] as String?,
      authorUri: map['authorUri'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      text: map['text'] as String? ?? '',
      relativeTime: map['relativeTime'] as String? ?? '',
    );
  }
}
