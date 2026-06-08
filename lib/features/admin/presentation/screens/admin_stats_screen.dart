import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/admin_stats_providers.dart';
import '../widgets/stat_section.dart';

/// Admin istatistik ekranı.
///
/// Zaman filtresi (Bugün / Bu Hafta / Bu Ay / Tüm Zamanlar) ile
/// pre-aggregated counter'lardan okunan istatistikleri gösterir.
class AdminStatsScreen extends ConsumerWidget {
  const AdminStatsScreen({super.key});

  static const _periodLabels = ['Bugün', 'Bu Hafta', 'Bu Ay', 'Tümü'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(statsTimePeriodProvider);
    final statsAsync = ref.watch(adminStatsProvider);
    final activeStoriesAsync = ref.watch(activeStoryCountProvider);
    final liveUsersAsync = ref.watch(liveUserCountProvider);

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
          // Güncelle butonu
          IconButton(
            onPressed: () {
              ref.invalidate(adminStatsProvider);
              ref.invalidate(activeStoryCountProvider);
              ref.invalidate(liveUserCountProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Güncelle',
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Zaman Filtresi ─────────────────────────────────────
          Container(
            width: double.infinity,
            color: AppColors.surfaceFor(context),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_periodLabels.length, (index) {
                  final isSelected = selectedPeriod == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(
                        _periodLabels[index],
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondaryFor(context),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceVariantFor(context),
                      checkmarkColor: Colors.white,
                      showCheckmark: false,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (_) {
                        ref.read(statsTimePeriodProvider.notifier).state =
                            index;
                      },
                    ),
                  );
                }),
              ),
            ),
          ),

          // ─── İçerik ─────────────────────────────────────────────
          Expanded(
            child: statsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
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
                        onPressed: () =>
                            ref.invalidate(adminStatsProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (stats) {
                final liveUserCount = liveUsersAsync.valueOrNull ?? 0;
                final activeStoryCount =
                    activeStoriesAsync.valueOrNull ?? 0;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // ─── Section 1: Genel Bakış ───────────────────
                    StatSection(
                      title: 'Genel Bakış',
                      cards: [
                        StatCardData(
                          icon: Icons.people_rounded,
                          color: const Color(0xFF3B82F6),
                          label: selectedPeriod == 3
                              ? 'Toplam Kullanıcı'
                              : 'Yeni Kullanıcı',
                          value: selectedPeriod == 3
                              ? liveUserCount
                              : stats.totalUsers,
                        ),
                        StatCardData(
                          icon: Icons.login_rounded,
                          color: const Color(0xFF8B5CF6),
                          label: 'Giriş Sayısı',
                          value: stats.totalLogins,
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
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ─── Section 2: İçerik ────────────────────────
                    StatSection(
                      title: 'İçerik',
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
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ─── Section 3: Araç Kullanımı ────────────────
                    StatSection(
                      title: 'Araç Kullanımı',
                      cards: [
                        StatCardData(
                          icon: Icons.compare_arrows_rounded,
                          color: const Color(0xFF6366F1),
                          label: 'Karşılaştırma',
                          value: stats.totalComparisons,
                        ),
                        StatCardData(
                          icon: Icons.calculate_rounded,
                          color: const Color(0xFFD97706),
                          label: 'Puan Hesaplama',
                          value: stats.totalScoreCalculations,
                        ),
                        StatCardData(
                          icon: Icons.star_rounded,
                          color: const Color(0xFFEAB308),
                          label: 'Favori',
                          value: stats.totalFavorites,
                        ),
                        StatCardData(
                          icon: Icons.flag_rounded,
                          color: const Color(0xFFDC2626),
                          label: 'Rapor',
                          value: stats.totalReports,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ─── Son güncelleme bilgisi ───────────────────
                    Center(
                      child: Text(
                        'Güncelle butonuna basarak verileri yenileyebilirsiniz',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiaryFor(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
