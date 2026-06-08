import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_stats_repository.dart';
import '../../domain/models/admin_stats_model.dart';

/// Admin istatistik repository provider
final adminStatsRepositoryProvider = Provider<AdminStatsRepository>((ref) {
  return AdminStatsRepository();
});

/// Seçili zaman filtresi (0=Bugün, 1=Bu Hafta, 2=Bu Ay, 3=Tüm Zamanlar)
final statsTimePeriodProvider = StateProvider<int>((ref) => 3);

/// İstatistik verilerini çeken ana provider.
/// Zaman filtresi değiştiğinde otomatik yenilenir.
final adminStatsProvider = FutureProvider<AdminStatsModel>((ref) async {
  final repo = ref.read(adminStatsRepositoryProvider);
  final period = ref.watch(statsTimePeriodProvider);

  switch (period) {
    case 0: // Bugün
      return repo.getTodayStats();
    case 1: // Bu Hafta
      return repo.getStatsForPeriod(7);
    case 2: // Bu Ay
      return repo.getStatsForPeriod(30);
    case 3: // Tüm Zamanlar
    default:
      return repo.getAllTimeStats();
  }
});

/// Aktif story sayısı (counter'dan bağımsız, live query)
final activeStoryCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.read(adminStatsRepositoryProvider);
  return repo.getActiveStoryCount();
});

/// Gerçek kullanıcı sayısı (users koleksiyonundan)
final liveUserCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.read(adminStatsRepositoryProvider);
  return repo.getLiveUserCount();
});
