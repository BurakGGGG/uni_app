import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/revenuecat_service.dart';
import '../../data/subscription_repository.dart';
import '../../data/usage_stats_repository.dart';
import '../../domain/enums/subscription_tier.dart';
import '../../domain/models/subscription_model.dart';
import '../../domain/models/usage_stats_model.dart';

// ═══════════════════════════════════════════════════════════════
//  Repository Providers
// ═══════════════════════════════════════════════════════════════

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository();
});

final usageStatsRepositoryProvider = Provider<UsageStatsRepository>((ref) {
  return UsageStatsRepository();
});

// ═══════════════════════════════════════════════════════════════
//  Subscription Tier Provider (Ana Provider)
// ═══════════════════════════════════════════════════════════════

/// Kullanıcının aktif abonelik tier'ını dinler.
///
/// RevenueCat SDK → Firestore fallback stratejisi:
///   1. RC online → RC'den tier oku
///   2. RC offline → Firestore subscriptions/{uid}'den oku
///   3. Hiçbiri yoksa → free
final subscriptionTierProvider = StreamProvider<SubscriptionTier>((ref) {
  final subscriptionRepo = ref.watch(subscriptionRepositoryProvider);
  final revenueCatService = RevenueCatService();

  return Stream<SubscriptionTier>.multi((controller) {
    // Fallback kaynak: Firestore abonelik dokümanı.
    final firestoreSub =
        subscriptionRepo.watchEffectiveTier().listen(controller.add);

    // Primary kaynak: RevenueCat canlı entitlement akışı.
    final rcSub = revenueCatService.tierStream.listen(
      controller.add,
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await rcSub.cancel();
      await firestoreSub.cancel();
    };
  }).distinct();
});

/// Kullanıcının tam abonelik modelini dinler (Firestore'dan).
final subscriptionModelProvider = StreamProvider<SubscriptionModel>((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.watchSubscription();
});

// ═══════════════════════════════════════════════════════════════
//  Usage Stats Providers
// ═══════════════════════════════════════════════════════════════

/// Günlük kullanım istatistiklerini dinler.
final usageStatsProvider = StreamProvider<UsageStatsModel>((ref) {
  final repo = ref.watch(usageStatsRepositoryProvider);
  return repo.watchUsageStats();
});

/// Free kullanıcı karşılaştırma yapabilir mi? (günlük limit kontrolü)
final canFreeCompareProvider = Provider<bool>((ref) {
  final stats = ref.watch(usageStatsProvider);
  return stats.when(
    data: (s) => s.canFreeCompare,
    loading: () => true, // Yükleniyor — izin ver, sonra kontrol edilir
    error: (error, stackTrace) => true, // Hata — izin ver
  );
});

/// Pro kullanıcı AI karşılaştırma özeti alabilir mi?
final canAiCompareProvider = Provider<bool>((ref) {
  final stats = ref.watch(usageStatsProvider);
  return stats.when(
    data: (s) => s.canAiCompare,
    loading: () => true,
    error: (error, stackTrace) => false, // Hata — güvenli taraf: izin verme
  );
});

/// Pro kullanıcı AI öneri yapabilir mi?
final canAiRecommendProvider = Provider<bool>((ref) {
  final stats = ref.watch(usageStatsProvider);
  return stats.when(
    data: (s) => s.canAiRecommend,
    loading: () => true,
    error: (error, stackTrace) => false,
  );
});

/// Kalan AI karşılaştırma hakkı sayısı.
final remainingAiComparisonsProvider = Provider<int>((ref) {
  final stats = ref.watch(usageStatsProvider);
  return stats.when(
    data: (s) => s.remainingAiComparisons,
    loading: () => UsageStatsModel.proAiComparisonLimit,
    error: (error, stackTrace) => 0,
  );
});

/// Kalan AI öneri hakkı sayısı.
final remainingAiRecommendationsProvider = Provider<int>((ref) {
  final stats = ref.watch(usageStatsProvider);
  return stats.when(
    data: (s) => s.remainingAiRecommendations,
    loading: () => UsageStatsModel.proAiRecommendationLimit,
    error: (error, stackTrace) => 0,
  );
});

// ═══════════════════════════════════════════════════════════════
//  Kombine Feature Gate Providers
// ═══════════════════════════════════════════════════════════════

/// Bölüm karşılaştırması erişimi var mı? (Plus veya Pro)
final canCompareDepartmentsProvider = Provider<bool>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  return tier.when(
    data: (t) => canCompareDepartments(t),
    loading: () => false,
    error: (error, stackTrace) => false,
  );
});

/// Şehir karşılaştırması erişimi var mı? (Plus veya Pro)
final canCompareCitiesProvider = Provider<bool>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  return tier.when(
    data: (t) => canCompareCities(t),
    loading: () => false,
    error: (error, stackTrace) => false,
  );
});

/// Pro grafik paketi erişimi var mı?
final canUseProChartsProvider = Provider<bool>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  return tier.when(
    data: (t) => canUseProCharts(t),
    loading: () => false,
    error: (error, stackTrace) => false,
  );
});

/// AI karşılaştırma özeti erişimi var mı? (Pro + günlük limit)
final canUseAiComparisonProvider = Provider<bool>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  final canAi = ref.watch(canAiCompareProvider);
  return tier.when(
    data: (t) => canUseAiComparison(t) && canAi,
    loading: () => false,
    error: (error, stackTrace) => false,
  );
});
