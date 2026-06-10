import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/admin_stats_model.dart';
import '../providers/admin_stats_providers.dart';
import '../widgets/stat_section.dart';
import '../widgets/stats_overview_card.dart';
import '../widgets/stats_ratio_section.dart';
import '../widgets/stats_top_universities.dart';
import '../widgets/stats_trend_chart.dart';

class AdminStatsScreen extends ConsumerWidget {
  const AdminStatsScreen({super.key});

  static const _periodLabels = ['Bugün', 'Bu Hafta', 'Bu Ay', 'Tümü'];

  void _refreshAll(WidgetRef ref) {
    ref.invalidate(adminStatsProvider);
    ref.invalidate(activeStoryCountProvider);
    ref.invalidate(liveUserCountProvider);
    ref.invalidate(adminLiveStatsProvider);
    ref.invalidate(dailyTrendProvider);
    ref.invalidate(weekComparisonProvider);
    ref.invalidate(topUniversitiesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(statsTimePeriodProvider);
    final statsAsync = ref.watch(adminStatsProvider);
    final activeStoriesAsync = ref.watch(activeStoryCountProvider);
    final liveUsersAsync = ref.watch(liveUserCountProvider);
    final liveStatsAsync = ref.watch(adminLiveStatsProvider);
    final trendAsync = ref.watch(dailyTrendProvider);
    final weekComparisonAsync = ref.watch(weekComparisonProvider);
    final topUniversitiesAsync = ref.watch(topUniversitiesProvider);
    final derived = ref.watch(adminDerivedStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        title: Text(
          'İstatistikler',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: AppColors.surfaceFor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _refreshAll(ref),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Güncelle',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.surfaceFor(context),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantFor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLightFor(context)),
              ),
              child: Row(
                children: List.generate(_periodLabels.length, (index) {
                  final isSelected = selectedPeriod == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(statsTimePeriodProvider.notifier).state = index;
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          _periodLabels[index],
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondaryFor(context),
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: statsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                error: error,
                onRetry: () => _refreshAll(ref),
              ),
              data: (stats) {
                final liveStats =
                    liveStatsAsync.valueOrNull ?? AdminLiveStatsModel.empty;
                final liveUserCount = liveUsersAsync.valueOrNull ??
                    liveStats.totalUsers;
                final activeStoryCount =
                    activeStoriesAsync.valueOrNull ?? 0;
                final userCount = selectedPeriod == 3
                    ? liveUserCount
                    : stats.totalUsers;
                final userLabel = selectedPeriod == 3
                    ? 'Toplam Kullanıcı'
                    : 'Yeni Kullanıcı';

                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    StatsOverviewCard(
                      periodLabel: _periodLabels[selectedPeriod],
                      userCount: userCount,
                      userLabel: userLabel,
                      loginCount: stats.totalLogins,
                      reviewCount: stats.totalReviews,
                      comparisonCount: stats.totalComparisons,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          trendAsync.when(
                            loading: () => const SizedBox(
                              height: 80,
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            error: (_, _) => const SizedBox.shrink(),
                            data: (points) => StatsTrendChart(
                              points: points,
                              comparison: weekComparisonAsync.valueOrNull,
                            ),
                          ),
                          const SizedBox(height: 12),

                          StatSection(
                            title: 'Kullanıcı Büyümesi',
                            icon: Icons.trending_up_rounded,
                            accentColor: const Color(0xFF3B82F6),
                            cards: [
                              StatCardData(
                                icon: Icons.people_rounded,
                                color: const Color(0xFF3B82F6),
                                label: userLabel,
                                value: userCount,
                              ),
                              StatCardData(
                                icon: Icons.verified_rounded,
                                color: const Color(0xFF10B981),
                                label: 'Doğrulanmış Öğrenci',
                                value: liveStats.verifiedStudents,
                              ),
                              StatCardData(
                                icon: Icons.person_pin_rounded,
                                color: const Color(0xFF8B5CF6),
                                label: 'Aktif (7 gün)',
                                value: liveStats.activeUsers7d,
                              ),
                              StatCardData(
                                icon: Icons.groups_rounded,
                                color: const Color(0xFF06B6D4),
                                label: 'Aktif (30 gün)',
                                value: liveStats.activeUsers30d,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          StatSection(
                            title: 'Keşif & Etkileşim',
                            icon: Icons.explore_rounded,
                            accentColor: const Color(0xFFF59E0B),
                            cards: [
                              StatCardData(
                                icon: Icons.school_rounded,
                                color: const Color(0xFF3B82F6),
                                label: 'Üniversite Görüntüleme',
                                value: stats.totalUniversityViews,
                              ),
                              StatCardData(
                                icon: Icons.menu_book_rounded,
                                color: const Color(0xFF8B5CF6),
                                label: 'Bölüm Görüntüleme',
                                value: stats.totalDepartmentViews,
                              ),
                              StatCardData(
                                icon: Icons.search_rounded,
                                color: const Color(0xFF10B981),
                                label: 'Arama',
                                value: stats.totalSearches,
                              ),
                              StatCardData(
                                icon: Icons.chat_bubble_rounded,
                                color: const Color(0xFFF59E0B),
                                label: 'Yorum',
                                value: stats.totalReviews,
                              ),
                              StatCardData(
                                icon: Icons.favorite_rounded,
                                color: const Color(0xFFEF4444),
                                label: 'Beğeni',
                                value: stats.totalLikes,
                              ),
                              StatCardData(
                                icon: Icons.star_rounded,
                                color: const Color(0xFFEAB308),
                                label: 'Favori',
                                value: stats.totalFavorites,
                              ),
                              StatCardData(
                                icon: Icons.list_alt_rounded,
                                color: const Color(0xFF6366F1),
                                label: 'Tercih Listesi',
                                value: stats.totalPreferenceLists,
                              ),
                              StatCardData(
                                icon: Icons.share_rounded,
                                color: const Color(0xFF0EA5E9),
                                label: 'Liste Paylaşımı',
                                value: stats.totalPreferenceListShares,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          StatsRatioSection(derived: derived),
                          const SizedBox(height: 12),

                          StatSection(
                            title: 'Abonelik & Monetizasyon',
                            icon: Icons.workspace_premium_rounded,
                            accentColor: const Color(0xFFEAB308),
                            cards: [
                              StatCardData(
                                icon: Icons.diamond_rounded,
                                color: const Color(0xFFEAB308),
                                label: 'Pro Abone',
                                value: liveStats.proSubscribers,
                              ),
                              StatCardData(
                                icon: Icons.star_half_rounded,
                                color: const Color(0xFF8B5CF6),
                                label: 'Plus Abone',
                                value: liveStats.plusSubscribers,
                              ),
                              StatCardData(
                                icon: Icons.percent_rounded,
                                color: const Color(0xFF10B981),
                                label: 'Pro Oranı (%)',
                                value: derived.proRatePercent.round(),
                              ),
                              StatCardData(
                                icon: Icons.lock_rounded,
                                color: const Color(0xFFEF4444),
                                label: 'Paywall Gösterimi',
                                value: stats.totalPaywallShown,
                              ),
                              StatCardData(
                                icon: Icons.play_circle_rounded,
                                color: const Color(0xFF3B82F6),
                                label: 'Reklam İzleme',
                                value: stats.totalAdWatched,
                              ),
                              StatCardData(
                                icon: Icons.shopping_cart_rounded,
                                color: const Color(0xFF10B981),
                                label: 'Abonelik Satın Alma',
                                value: stats.totalSubscriptionPurchased,
                              ),
                              StatCardData(
                                icon: Icons.auto_awesome_rounded,
                                color: const Color(0xFF6366F1),
                                label: 'AI Karşılaştırma',
                                value: stats.totalAiComparisons,
                              ),
                              StatCardData(
                                icon: Icons.psychology_rounded,
                                color: const Color(0xFF06B6D4),
                                label: 'AI Öneri',
                                value: stats.totalAiRecommendations,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          StatSection(
                            title: 'İçerik',
                            icon: Icons.auto_stories_rounded,
                            accentColor: const Color(0xFF10B981),
                            cards: [
                              StatCardData(
                                icon: Icons.visibility_rounded,
                                color: const Color(0xFF10B981),
                                label: 'Story Görüntülenme',
                                value: stats.totalStoryViews,
                              ),
                              StatCardData(
                                icon: Icons.auto_stories_rounded,
                                color: const Color(0xFF06B6D4),
                                label: 'Aktif Story',
                                value: activeStoryCount,
                              ),
                              StatCardData(
                                icon: Icons.login_rounded,
                                color: const Color(0xFF8B5CF6),
                                label: 'Giriş Sayısı',
                                value: stats.totalLogins,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          StatSection(
                            title: 'Araç Kullanımı',
                            icon: Icons.build_rounded,
                            accentColor: const Color(0xFF6366F1),
                            cards: [
                              StatCardData(
                                icon: Icons.compare_arrows_rounded,
                                color: const Color(0xFF6366F1),
                                label: 'Karşılaştırma',
                                value: stats.totalComparisons,
                              ),
                              StatCardData(
                                icon: Icons.ios_share_rounded,
                                color: const Color(0xFF0EA5E9),
                                label: 'Karşılaştırma Paylaşımı',
                                value: stats.totalComparisonShares,
                              ),
                              StatCardData(
                                icon: Icons.calculate_rounded,
                                color: const Color(0xFFD97706),
                                label: 'Puan Hesaplama',
                                value: stats.totalScoreCalculations,
                              ),
                              StatCardData(
                                icon: Icons.flag_rounded,
                                color: const Color(0xFFDC2626),
                                label: 'Rapor',
                                value: stats.totalReports,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          topUniversitiesAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                            data: (universities) =>
                                StatsTopUniversities(universities: universities),
                          ),
                          const SizedBox(height: 20),

                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 14,
                                  color: AppColors.textTertiaryFor(context),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Güncelle butonuna basarak verileri yenileyebilirsiniz',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textTertiaryFor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              'İstatistikler yüklenemedi',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
