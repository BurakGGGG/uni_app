enum NotificationType {
  reviewLiked,
  reviewModerated,
  favoriteNewReview;
  
  String get firestoreValue {
    switch (this) {
      case NotificationType.reviewLiked: return 'review_liked';
      case NotificationType.reviewModerated: return 'review_moderated';
      case NotificationType.favoriteNewReview: return 'favorite_new_review';
    }
  }
  
  static NotificationType fromString(String? value) {
    switch (value) {
      case 'review_liked': return NotificationType.reviewLiked;
      case 'review_moderated': return NotificationType.reviewModerated;
      case 'favorite_new_review': return NotificationType.favoriteNewReview;
      default: return NotificationType.reviewLiked;
    }
  }
}
