import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPreferences {
  final bool reviewLikedEnabled;
  final bool reviewModeratedEnabled;
  final bool favoriteNewReviewEnabled;

  const NotificationPreferences({
    this.reviewLikedEnabled = true,
    this.reviewModeratedEnabled = true,
    this.favoriteNewReviewEnabled = true,
  });

  NotificationPreferences copyWith({
    bool? reviewLikedEnabled,
    bool? reviewModeratedEnabled,
    bool? favoriteNewReviewEnabled,
  }) {
    return NotificationPreferences(
      reviewLikedEnabled: reviewLikedEnabled ?? this.reviewLikedEnabled,
      reviewModeratedEnabled: reviewModeratedEnabled ?? this.reviewModeratedEnabled,
      favoriteNewReviewEnabled: favoriteNewReviewEnabled ?? this.favoriteNewReviewEnabled,
    );
  }
}

class NotificationPreferencesNotifier extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() async {
    // Stub implementation for UI development
    return const NotificationPreferences();
  }

  Future<void> toggle(String key, bool value) async {
    final current = state.value;
    if (current == null) return;

    NotificationPreferences updated;
    switch (key) {
      case 'reviewLikedEnabled':
        updated = current.copyWith(reviewLikedEnabled: value);
        break;
      case 'reviewModeratedEnabled':
        updated = current.copyWith(reviewModeratedEnabled: value);
        break;
      case 'favoriteNewReviewEnabled':
        updated = current.copyWith(favoriteNewReviewEnabled: value);
        break;
      default:
        return;
    }

    state = AsyncData(updated);
  }
}

final notificationPreferencesProvider =
    AsyncNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
  NotificationPreferencesNotifier.new,
);
