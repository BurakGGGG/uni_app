import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_stats_repository.dart';
import '../../domain/models/admin_stats_model.dart';

final adminStatsRepositoryProvider = Provider<AdminStatsRepository>((ref) {
  return AdminStatsRepository();
});

/// Seçili zaman filtresi (0=Bugün, 1=Bu Hafta, 2=Bu Ay, 3=Tüm Zamanlar)
final statsTimePeriodProvider = StateProvider<int>((ref) => 3);

final adminStatsProvider = FutureProvider<AdminStatsModel>((ref) async {
  final repo = ref.read(adminStatsRepositoryProvider);
  final period = ref.watch(statsTimePeriodProvider);

  switch (period) {
    case 0:
      return repo.getTodayStats();
    case 1:
      return repo.getStatsForPeriod(7);
    case 2:
      return repo.getStatsForPeriod(30);
    case 3:
    default:
      return repo.getAllTimeStats();
  }
});

final activeStoryCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.read(adminStatsRepositoryProvider);
  return repo.getActiveStoryCount();
});

final liveUserCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.read(adminStatsRepositoryProvider);
  return repo.getLiveUserCount();
});

final adminLiveStatsProvider = FutureProvider<AdminLiveStatsModel>((ref) async {
  final repo = ref.read(adminStatsRepositoryProvider);
  return repo.getLiveStats();
});

final dailyTrendProvider = FutureProvider<List<DailyTrendPoint>>((ref) async {
  final repo = ref.read(adminStatsRepositoryProvider);
  return repo.getDailyTrend(7);
});

final weekComparisonProvider =
    FutureProvider<PeriodComparisonModel>((ref) async {
  final repo = ref.read(adminStatsRepositoryProvider);
  return repo.getWeekOverWeekComparison();
});

final topUniversitiesProvider =
    FutureProvider<List<TopUniversityStat>>((ref) async {
  final repo = ref.read(adminStatsRepositoryProvider);
  return repo.getTopUniversities();
});

final adminDerivedStatsProvider = Provider<AdminDerivedStats>((ref) {
  final stats = ref.watch(adminStatsProvider).valueOrNull ?? AdminStatsModel.empty;
  final live = ref.watch(adminLiveStatsProvider).valueOrNull ?? AdminLiveStatsModel.empty;
  final activeStories = ref.watch(activeStoryCountProvider).valueOrNull ?? 0;
  final period = ref.watch(statsTimePeriodProvider);

  final userBase = period == 3 ? live.totalUsers : stats.totalUsers;
  final effectiveUserBase = userBase > 0 ? userBase : live.totalUsers;

  return AdminDerivedStats.compute(
    stats: stats,
    live: live,
    activeStoryCount: activeStories,
    userBase: effectiveUserBase > 0 ? effectiveUserBase : 1,
  );
});
