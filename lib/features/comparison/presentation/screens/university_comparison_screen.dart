import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../widgets/offline_banner.dart';
import '../../data/ai_comparison_summary_service.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../widgets/comparison_result_skeleton.dart';
import '../widgets/comparison_empty_state.dart';
import '../../../../core/utils/haptic.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Üniversite Karşılaştırma Ekranı — Yeniden Yazım (Gün 3)
/// Hero Section + 4 Tab'lı sonuç görünümü
class UniversityComparisonScreen extends ConsumerStatefulWidget {
  /// Deep-link veya geçmişten gelen önceden seçili üniversite ID'leri.
  /// Verilirse initState'te `comparisonSelectionProvider`'a set'lenir.
  final String? initialAId;
  final String? initialBId;

  const UniversityComparisonScreen({
    super.key,
    this.initialAId,
    this.initialBId,
  });

  @override
  ConsumerState<UniversityComparisonScreen> createState() =>
      _UniversityComparisonScreenState();
}

class _UniversityComparisonScreenState
    extends ConsumerState<UniversityComparisonScreen> {
  @override
  void initState() {
    super.initState();
    final a = widget.initialAId;
    final b = widget.initialBId;
    if (a == null && b == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(comparisonSelectionProvider.notifier);
      if (a != null && a.isNotEmpty) notifier.selectA(a);
      if (b != null && b.isNotEmpty) notifier.selectB(b);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(comparisonResultProvider, (previous, next) {
      if (next is! AsyncData<ComparisonResult?>) return;
      if (next.value == null) return;
      if (previous is AsyncLoading) {
        AppHaptic.compareSuccess();
      }
    });
    ref.listen(comparisonGateDecisionProvider, (previous, next) {
      next.whenData((decision) {
        if (decision != null && !decision.isAllowed) {
          AppHaptic.limitReached();
        }
      });
    });

    final selection = ref.watch(comparisonSelectionProvider);
    final resultAsync = ref.watch(comparisonResultProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          loc.comparisonUniversity,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        actions: [
          if (selection.uniIdA != null || selection.uniIdB != null)
            TextButton.icon(
              icon: Icon(Icons.refresh_rounded, size: 18, color: AppColors.error),
              label: Text(
                loc.reset,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => _showResetConfirmation(context, ref),
            ),
          if (selection.bothSelected) ...[
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: loc.swap,
              onPressed: () {
                AppHaptic.swap();
                ref.read(comparisonSelectionProvider.notifier).swap();
              },
            ),
            IconButton(
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              tooltip: loc.share,
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
          // ─── Offline Banner ──────────────────────────────────
          if (!ref.watch(isOnlineProvider))
            const OfflineBanner(),

          // ─── Üniversite Seçici (sadece sonuç yokken görünür) ───
          if (!selection.bothSelected || resultAsync.valueOrNull == null)
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
      loading: () => const ComparisonResultSkeleton(),
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

  static void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Icon(
          Icons.refresh_rounded,
          color: AppColors.error,
          size: 32,
        ),
        title: Text(
          'Karşılaştırmayı Sıfırla',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Mevcut karşılaştırma sıfırlansın mı? Yeni üniversiteler seçebilirsiniz.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'İptal',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              AppHaptic.reset();
              Navigator.pop(ctx);
              ref.read(comparisonSelectionProvider.notifier).reset();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(AppLocalizations.of(context).reset),
          ),
        ],
      ),
    );
  }
}

// ─── Boş durum ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return const ComparisonEmptyState(
      title: 'İki üniversite seç',
      subtitle: 'Yukarıdan iki üniversite seçince karşılaştırma sonuçları burada gözükür.',
      fallbackIcon: Icons.school_rounded,
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
    final loc = AppLocalizations.of(context);

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
            tabs: [
              Tab(
                height: 36,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.dashboard_rounded, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        loc.tabGeneral,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                height: 36,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.category_rounded, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        loc.tabCategories,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.result.categoryComparisons.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.result.categoryComparisons.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                height: 36,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insights_rounded, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        loc.tabChart,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                height: 36,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.analytics_rounded, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        loc.tabStats,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

/// Outer wrapper — sadece RefreshIndicator için ref kullanır.
/// Static kartlar (`_BigInfoCard`, `_SummaryCard`, `_QuickStatsRow`) sadece
/// `result` değişince rebuild olur. AI summary state'i `_AiSummarySection`
/// içinde izlenir; o değişince sadece o widget rebuild olur.
class _GeneralTab extends ConsumerWidget {
  final ComparisonResult result;
  const _GeneralTab({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(comparisonResultProvider);
        ref.invalidate(aiComparisonSummaryProvider);
        final selection = ref.read(comparisonSelectionProvider);
        if (selection.bothSelected) {
          final pair = ComparisonPair(
            idA: selection.uniIdA!,
            idB: selection.uniIdB!,
          );
          ref.invalidate(ratingTrendProvider(pair));
          ref.invalidate(categoryHeatMapProvider(pair));
        }
        await ref.read(comparisonResultProvider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Büyük puan kartları — result değişmedikçe rebuild olmaz
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

            // AI summary — kendi Consumer'ı içinde, izole rebuild
            _AiSummarySection(result: result),
            const SizedBox(height: 16),

            // Quick stats
            _QuickStatsRow(result: result, isDark: isDark),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

/// AI summary kartının izole Consumer'ı.
/// 4 provider izler ama yalnızca bu widget rebuild olur — kardeş kartlar etkilenmez.
class _AiSummarySection extends ConsumerWidget {
  final ComparisonResult result;
  const _AiSummarySection({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(aiComparisonSummaryProvider, (previous, next) {
      if (next is! AsyncData<AiComparisonSummaryResult?>) return;
      final summary = next.value;
      if (summary == null || summary.summary.trim().isEmpty) return;
      if (previous is AsyncLoading) {
        AppHaptic.aiSummaryReceived();
      }
    });

    // Regenerate feedback'i (başarılı veya hata) snackbar olarak göster
    ref.listen<RegenerateFeedback?>(regenerateFeedbackProvider, (prev, next) {
      if (next == null) return;
      if (prev?.tag == next.tag) return; // aynı feedback tekrar
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: next.isError ? AppColors.error : AppColors.success,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      // Tek sefer göstersin, hemen sıfırla
      Future.microtask(
        () => ref.read(regenerateFeedbackProvider.notifier).state = null,
      );
    });

    final canUseAi = ref.watch(canUseAiComparisonProvider);
    final usage = ref.watch(usageStatsProvider);
    final tier = ref.watch(subscriptionTierProvider).valueOrNull ??
        SubscriptionTier.free;
    final aiSummaryAsync = ref.watch(aiComparisonSummaryProvider);

    final bool aiLoading = usage.isLoading || aiSummaryAsync.isLoading;
    final String aiSummaryText = aiSummaryAsync.valueOrNull?.summary ?? '';
    final bool aiLimitReached = tier == SubscriptionTier.pro && !canUseAi;
    String? aiErrorMessage;
    if (aiSummaryAsync.hasError) {
      final err = aiSummaryAsync.error;
      if (err is AiSummaryFailure) {
        aiErrorMessage = err.userMessage;
      } else {
        aiErrorMessage = 'Beklenmeyen bir hata oluştu. Lütfen tekrar dene.';
      }
    }

    // Regenerate: Pro tier · özet hazır · hata yok · bu çift için kullanılmamış
    // (server kalıcı tutar — UI sadece UX için set'i kontrol eder)
    final usedKeys = ref.watch(regenerateUsedPairsProvider);
    final sortedIds = [result.uniA.id, result.uniB.id]..sort();
    final pairKey = '${sortedIds[0]}__${sortedIds[1]}';
    final bool regenerateAllowed = tier == SubscriptionTier.pro &&
        !aiLoading &&
        aiSummaryText.isNotEmpty &&
        aiErrorMessage == null &&
        !usedKeys.contains(pairKey);

    return ComparisonAiSummaryCard(
      loading: aiLoading,
      canUseAi: canUseAi,
      isLimitReached: aiLimitReached,
      summaryText: aiSummaryText.isNotEmpty ? aiSummaryText : result.summaryText,
      errorMessage: aiErrorMessage,
      onRetry: aiErrorMessage != null
          ? () => ref.invalidate(aiComparisonSummaryProvider)
          : null,
      regenerateAllowed: regenerateAllowed,
      onRegenerate: regenerateAllowed
          ? () => triggerAiRegenerate(ref)
          : null,
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
    if (categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: EmptyStateWidget(
            illustration: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rate_review_rounded, size: 32, color: AppColors.primary),
            ),
            title: 'Yeterli değerlendirme yok',
            description:
                'Bu iki üniversite için henüz kategori puanı oluşturacak yorum bulunmuyor.',
          ),
        ),
      );
    }
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
    if (result.categoryComparisons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: EmptyStateWidget(
            illustration: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.show_chart_rounded, size: 32, color: AppColors.secondary),
            ),
            title: 'Grafik üretmek için yorum gerekiyor',
            description: 'Henüz yeterli değerlendirme olmadığı için grafikler boş görünüyor.',
          ),
        ),
      );
    }
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
