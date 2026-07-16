import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../domain/badge_catalog.dart';
import '../../domain/engagement_stats.dart';

/// Kullanıcının kazandığı rozetler (badgeId -> kazanım anı) — canlı stream.
///
/// currentUserProvider'ın repository önbelleği yüzünden rozet kutlaması
/// dakikalar geç görünebilirdi; bu provider users/{uid} dokümanını doğrudan
/// dinler (kutlama akışının tek veri kaynağı).
final userBadgesProvider = StreamProvider<Map<String, DateTime>>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(const {});

  return FirebaseFirestore.instance
      .collection('users')
      .doc(auth.uid)
      .snapshots()
      .map((snap) {
    final raw = snap.data()?['badges'];
    if (raw is! Map) return const <String, DateTime>{};
    final result = <String, DateTime>{};
    raw.forEach((key, value) {
      if (key is String && value is Timestamp) {
        result[key] = value.toDate();
      }
    });
    return result;
  });
});

/// users/{uid}/stats/engagement — rozet ilerleme sayaçları (server yazar).
final engagementStatsProvider = StreamProvider<EngagementStats>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(EngagementStats.empty);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(auth.uid)
      .collection('stats')
      .doc('engagement')
      .snapshots()
      .map((snap) => EngagementStats.fromMap(snap.data()));
});

/// Katalogdaki her rozet için kullanıcı özel ilerleme durumu.
/// Sunucudan gelen bilinmeyen rozet id'leri sessizce yok sayılır
/// (server yeni rozeti app güncellemesinden önce yayınlayabilir).
final badgeProgressProvider = Provider<List<BadgeProgress>>((ref) {
  final earned = ref.watch(userBadgesProvider).valueOrNull ?? const {};
  final stats =
      ref.watch(engagementStatsProvider).valueOrNull ?? EngagementStats.empty;
  final user = ref.watch(currentUserProvider).valueOrNull;
  final favoriteCount =
      ref.watch(favoritesProvider).valueOrNull?.length ?? 0;

  final membershipDays = user == null
      ? 0
      : DateTime.now().difference(user.createdAt).inDays;

  int currentFor(BadgeMetric metric) {
    switch (metric) {
      case BadgeMetric.reviews:
        return user?.reviewCount ?? 0;
      case BadgeMetric.likesReceived:
        return stats.totalLikesReceived;
      case BadgeMetric.favorites:
        return favoriteCount;
      case BadgeMetric.universitiesViewed:
        return stats.viewedUniversityCount;
      case BadgeMetric.citiesViewed:
        return stats.viewedCityCount;
      case BadgeMetric.comparisons:
        return stats.comparisonCount;
      case BadgeMetric.shares:
        return stats.shareCount;
      case BadgeMetric.streak:
        return stats.currentStreak;
      case BadgeMetric.membershipDays:
        return membershipDays;
      case BadgeMetric.none:
        return 0;
    }
  }

  return [
    for (final definition in badgeCatalog)
      BadgeProgress(
        definition: definition,
        earnedAt: earned[definition.id],
        current: currentFor(definition.metric),
      ),
  ];
});

/// Kazanılan rozet sayısı — "Rozetlerim (8/25)" başlığı için.
final earnedBadgeCountProvider = Provider<int>((ref) {
  final progress = ref.watch(badgeProgressProvider);
  return progress.where((p) => p.earned).length;
});
