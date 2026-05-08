import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../domain/models/comparison_result.dart';
import '../providers/comparison_providers.dart';
import '../widgets/comparison_uni_picker.dart';
import '../widgets/comparison_hero_section.dart';
import '../widgets/animated_comparison_bar.dart';
import '../widgets/comparison_radar_chart.dart';
import '../widgets/comparison_stats_table.dart';
import '../widgets/comparison_share_card.dart';
import '../widgets/comparison_ai_summary_card.dart';

/// Üniversite Karşılaştırma Ekranı — Yeniden Yazım (Gün 3)
/// Hero Section + 4 Tab'lı sonuç görünümü
class UniversityComparisonScreen extends ConsumerWidget {
  const UniversityComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(comparisonSelectionProvider);
    final resultAsync = ref.watch(comparisonResultProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Üniversite Karşılaştır',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        actions: [
          if (selection.uniIdA != null || selection.uniIdB != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Sıfırla',
              color: AppColors.error,
              onPressed: () =>
                  ref.read(comparisonSelectionProvider.notifier).reset(),
            ),
          if (selection.bothSelected) ...[
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, size: 22),
              tooltip: 'Yer Değiştir',
              onPressed: () =>
                  ref.read(comparisonSelectionProvider.notifier).swap(),
            ),
            IconButton(
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              tooltip: 'Paylaş',
              onPressed: () async {
                final result = resultAsync.valueOrNull;
                if (result != null) {
                  await ComparisonShareCard.shareCard(context, result);
                }
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // ─── Üniversite Seçici ──────────────────────────────
          const ComparisonUniPicker(),

          // ─── Sonuç Alanı ────────────────────────────────────
          Expanded(
            child: _buildBody(context, selection, resultAsync, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ComparisonSelection selection,
    AsyncValue<ComparisonResult?> resultAsync,
    bool isDark,
  ) {
    if (!selection.bothSelected) {
      return _EmptyState(isDark: isDark);
    }

    return resultAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Hata: $e', textAlign: TextAlign.center),
        ),
      ),
      data: (result) {
        if (result == null) return _EmptyState(isDark: isDark);
        return _TabbedResultView(result: result);
      },
    );
  }
}

// ─── Boş durum ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: EmptyStateWidget(
          illustration: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'assets/icons/compare_icon.svg',
              width: 56,
              height: 56,
            ),
          ),
          title: 'İki üniversite seç',
          description:
              'Yukarıdan iki üniversite seçince karşılaştırma sonuçları burada gözükür.',
        ),
      ),
    );
  }
}

// ─── Tab'lı sonuç görünümü ──────────────────────────────────────────

class _TabbedResultView extends StatefulWidget {
  final ComparisonResult result;
  const _TabbedResultView({required this.result});

  @override
  State<_TabbedResultView> createState() => _TabbedResultViewState();
}

class _TabbedResultViewState extends State<_TabbedResultView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ['Genel', 'Kategoriler', 'Grafik', 'İstatistik'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // ─── Hero Section ──────────────────────────────────
        ComparisonHeroSection(result: widget.result),

        // ─── Animasyonlu Tab Bar ───────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: isDark ? Colors.white : AppColors.textPrimary,
            unselectedLabelColor: AppColors.textTertiary,
            labelStyle: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            labelPadding: EdgeInsets.zero,
            tabs: _tabs
                .map((t) => Tab(height: 36, text: t))
                .toList(),
          ),
        ),

        // ─── Tab İçerikleri ────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _GeneralTab(result: widget.result),
              _CategoriesTab(result: widget.result),
              _ChartTab(result: widget.result),
              _StatsTab(result: widget.result),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Genel Tab ─────────────────────────────────────────────────────

class _GeneralTab extends ConsumerWidget {
  final ComparisonResult result;
  const _GeneralTab({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canUseAi = ref.watch(canUseAiComparisonProvider);
    final usage = ref.watch(usageStatsProvider);
    final tier = ref.watch(subscriptionTierProvider).valueOrNull ?? SubscriptionTier.free;
    final loadingAi = usage.isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Büyük puan kartları
          Row(
            children: [
              Expanded(
                child: _BigInfoCard(
                  label: result.uniA.name,
                  score: result.uniA.avgRating,
                  reviewCount: result.uniA.reviewCount,
                  color: AppColors.primary,
                  type: result.uniA.type,
                  year: result.uniA.establishedYear,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigInfoCard(
                  label: result.uniB.name,
                  score: result.uniB.avgRating,
                  reviewCount: result.uniB.reviewCount,
                  color: AppColors.secondary,
                  type: result.uniB.type,
                  year: result.uniB.establishedYear,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Öne çıkan karşılaştırma özeti
          _SummaryCard(result: result, isDark: isDark),
          const SizedBox(height: 16),

          ComparisonAiSummaryCard(
            loading: loadingAi,
            canUseAi: canUseAi,
            isLimitReached: tier == SubscriptionTier.pro && !canUseAi,
            summaryText: result.summaryText,
          ),
          const SizedBox(height: 16),

          // Quick stats
          _QuickStatsRow(result: result, isDark: isDark),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _BigInfoCard extends StatelessWidget {
  final String label;
  final double score;
  final int reviewCount;
  final Color color;
  final String type;
  final int year;
  final bool isDark;

  const _BigInfoCard({
    required this.label,
    required this.score,
    required this.reviewCount,
    required this.color,
    required this.type,
    required this.year,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            score > 0 ? score.toStringAsFixed(1) : '-',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$reviewCount yorum',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$type • $year',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ComparisonResult result;
  final bool isDark;
  const _SummaryCard({required this.result, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final winner = result.overallWinnerId;
    final winnerName = winner == result.uniA.id
        ? result.uniA.name
        : (winner == result.uniB.id ? result.uniB.name : null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.04),
            AppColors.secondary.withValues(alpha: isDark ? 0.05 : 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Karşılaştırma Özeti',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.summaryText,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (winnerName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🏆 $winnerName ${result.categoriesAWins > result.categoriesBWins ? result.categoriesAWins : result.categoriesBWins}/${result.categoryComparisons.length} kategoride önde',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final ComparisonResult result;
  final bool isDark;
  const _QuickStatsRow({required this.result, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickStat(
          icon: Icons.school_rounded,
          label: 'Bölüm',
          valueA: result.stats.totalDepartmentsA.toString(),
          valueB: result.stats.totalDepartmentsB.toString(),
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _QuickStat(
          icon: Icons.place_rounded,
          label: 'Mekan',
          valueA: result.placeCountA.toString(),
          valueB: result.placeCountB.toString(),
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _QuickStat(
          icon: Icons.rate_review_rounded,
          label: 'Yorum',
          valueA: result.uniA.reviewCount.toString(),
          valueB: result.uniB.reviewCount.toString(),
          isDark: isDark,
        ),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valueA;
  final String valueB;
  final bool isDark;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.valueA,
    required this.valueB,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.textTertiary),
            const SizedBox(height: 6),
            Text(label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary, fontSize: 10)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(valueA,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    )),
                Text(' / ',
                    style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 11)),
                Text(valueB,
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Kategoriler Tab ───────────────────────────────────────────────

class _CategoriesTab extends StatelessWidget {
  final ComparisonResult result;
  const _CategoriesTab({required this.result});

  @override
  Widget build(BuildContext context) {
    final categories = result.categoryComparisons.values.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return AnimatedComparisonBar(
          comparison: categories[index],
          uniAId: result.uniA.id,
          uniBId: result.uniB.id,
          delay: Duration(milliseconds: index * 100),
        );
      },
    );
  }
}

// ─── Grafik Tab ────────────────────────────────────────────────────

class _ChartTab extends StatelessWidget {
  final ComparisonResult result;
  const _ChartTab({required this.result});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
      child: ComparisonRadarChart(result: result),
    );
  }
}

// ─── İstatistik Tab ────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final ComparisonResult result;
  const _StatsTab({required this.result});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
      child: ComparisonStatsTable(result: result),
    );
  }
}
