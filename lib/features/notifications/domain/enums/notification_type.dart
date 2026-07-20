enum NotificationType {
  reviewLiked,
  reviewModerated,
  favoriteNewReview,
  reviewCampaign,

  /// Üni'nin tercih takvimi hatırlatmaları (sunucu: uni_reminders.ts).
  uniReminder;

  String get firestoreValue {
    switch (this) {
      case NotificationType.reviewLiked: return 'review_liked';
      case NotificationType.reviewModerated: return 'review_moderated';
      case NotificationType.favoriteNewReview: return 'favorite_new_review';
      case NotificationType.reviewCampaign: return 'review_campaign';
      case NotificationType.uniReminder: return 'uni_reminder';
    }
  }

  static NotificationType fromString(String? value) {
    switch (value) {
      case 'review_liked': return NotificationType.reviewLiked;
      case 'review_moderated': return NotificationType.reviewModerated;
      case 'favorite_new_review': return NotificationType.favoriteNewReview;
      case 'review_campaign': return NotificationType.reviewCampaign;
      case 'uni_reminder': return NotificationType.uniReminder;
      default: return NotificationType.reviewLiked;
    }
  }
}
