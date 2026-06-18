import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../domain/models/comparison_result.dart';
import '../../domain/models/triple_comparison_result.dart';
import '../../../university/domain/models/university_model.dart';
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
import '../widgets/triple_third_uni_picker.dart';
import '../widgets/university_logo_box.dart';
import '../widgets/comparison_notes_section.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';

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
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          loc.comparisonUniversity,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
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
            // 3. üniversite ekle (Pro feature). Pro değilse paywall'a yönlendirir.
            // allThreeSelected ise buton yerine "kaldır" gösterilir.
            if (!selection.allThreeSelected)
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.school_rounded),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.tierPro,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                tooltip: '3. üniversite ekle (Pro)',
                onPressed: () => _handleAddThird(context, ref, selection),
              ),
            if (selection.allThreeSelected)
              IconButton(
                icon: const Icon(Icons.domain_disabled_rounded),
                tooltip: '3. üniversiteyi kaldır',
                onPressed: () {
                  AppHaptic.reset();
                  ref.read(comparisonSelectionProvider.notifier).removeC();
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

          // ─── Üniversite Seçici (sadece ikili modda ve sonuç yokken) ──
          if (!selection.allThreeSelected &&
              (!selection.bothSelected || resultAsync.valueOrNull == null))
            const ComparisonUniPicker(),

          // ─── Sonuç Alanı ────────────────────────────────────
          // allThreeSelected → triple result, aksi halde ikili sonuç
          Expanded(
            child: selection.allThreeSelected
                ? const _TripleResultView()
                : _buildBody(context, selection, resultAsync, isDark),
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

  /// 3. üniversite ekleme akışı. Pro değilse paywall'a yönlendir,
  /// Pro ise picker bottom sheet aç ve seçim sonucu selectC çağır.
  Future<void> _handleAddThird(
    BuildContext context,
    WidgetRef ref,
    ComparisonSelection selection,
  ) async {
    final isPro = ref.read(canCompareTripleProvider);
    if (!isPro) {
      context.push('/compare/paywall');
      return;
    }
    final idA = selection.uniIdA;
    final idB = selection.uniIdB;
    if (idA == null || idB == null) return;
    AppHaptic.swap();
    final selectedId = await TripleThirdUniPicker.show(
      context,
      excludeIdA: idA,
      excludeIdB: idB,
    );
    if (selectedId == null) return;
    if (!context.mounted) return;
    ref.read(comparisonSelectionProvider.notifier).selectC(selectedId);
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
            color: AppColors.textSecondaryFor(context),
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
                color: AppColors.textSecondaryFor(context),
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

class _TabbedResultView extends ConsumerStatefulWidget {
  final ComparisonResult result;
  const _TabbedResultView({required this.result});

  @override
  ConsumerState<_TabbedResultView> createState() => _TabbedResultViewState();
}

class _TabbedResultViewState extends ConsumerState<_TabbedResultView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ─── Tab tanımları ────────────────────────────────────────────
  static const _tabIcons = [
    Icons.dashboard_rounded,
    Icons.category_rounded,
    Icons.insights_rounded,
    Icons.analytics_rounded,
    Icons.sticky_note_2_rounded,
  ];

  static const _tabShortNames = ['Gn', 'Kat', 'Grf', 'İst', 'Not'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> _tabFullNames(AppLocalizations loc) => [
        loc.tabGeneral,
        loc.tabCategories,
        loc.tabChart,
        loc.tabStats,
        'Notlarım',
      ];

  void _handleTabTap(int i) {
    final canUse = ref.read(canUseComparisonNotesProvider);
    if (i == 4 && !canUse) {
      // Non-Pro — paywall popup göster, tab'ı değiştirme
      _showProPaywall();
      return;
    }
    _tabController.animateTo(i);
  }

  Future<void> _showProPaywall() async {
    final authState = ref.read(authStateProvider);
    final isLoggedIn = authState.valueOrNull != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProNotesPaywallSheet(
        isLoggedIn: isLoggedIn,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final fullNames = _tabFullNames(loc);

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
          child: AnimatedBuilder(
            animation: _tabController.animation!,
            builder: (context, _) {
              final animValue = _tabController.animation!.value;
              return Row(
                children: List.generate(5, (i) {
                  final distance = (animValue - i).abs().clamp(0.0, 1.0);
                  final isActive = distance < 0.5;
                  final isNotes = i == 4;

                  // Notes tab her zaman altın renkte
                  final Color itemColor;
                  if (isNotes) {
                    itemColor = AppColors.tierPro;
                  } else if (isActive) {
                    itemColor = isDark ? Colors.white : AppColors.textPrimary;
                  } else {
                    itemColor = AppColors.textTertiary;
                  }

                  return Expanded(
                    flex: isActive ? 3 : 2,
                    child: GestureDetector(
                      onTap: () => _handleTabTap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _tabIcons[i],
                              size: 14,
                              color: itemColor,
                            ),
                            const SizedBox(width: 3),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              child: Text(
                                isActive
                                    ? fullNames[i]
                                    : _tabShortNames[i],
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontWeight:
                                      isActive ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: isActive ? 11.5 : 10.5,
                                  color: itemColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
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
              _NotesTab(result: widget.result),
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
              color: AppColors.textTertiaryFor(context),
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
              color: AppColors.textTertiaryFor(context),
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
                    color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
                  )),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.summaryText,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(context),
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
                : AppColors.borderLightFor(context),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.textTertiaryFor(context)),
            const SizedBox(height: 6),
            Text(label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiaryFor(context), fontSize: 10)),
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
                      color: AppColors.textTertiaryFor(context), fontSize: 11)),
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

// ─── Notlarım Tab (Pro) ────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  final ComparisonResult result;
  const _NotesTab({required this.result});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      child: ComparisonNotesSection(
        comparisonType: 'university',
        entityAId: result.uniA.id,
        entityBId: result.uniB.id,
      ),
    );
  }
}

// ─── Pro Notes Paywall Bottom Sheet ─────────────────────────────────

class _ProNotesPaywallSheet extends StatelessWidget {
  final bool isLoggedIn;
  final bool isDark;

  const _ProNotesPaywallSheet({
    required this.isLoggedIn,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Gold icon ───────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.tierProGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tierPro.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sticky_note_2_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),

            // ─── Title ───────────────────────────────────────
            ShaderMask(
              shaderCallback: (bounds) => AppColors.tierProGradient
                  .createShader(bounds),
              child: Text(
                'Karşılaştırma Notları',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ─── Subtitle ────────────────────────────────────
            Text(
              isLoggedIn
                  ? 'Pro üyelere özel premium bir deneyim seni bekliyor!'
                  : 'Giriş yap ve Pro üye olarak bu özelliğin kilidini aç!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryFor(context),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // ─── Feature Pills ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tierPro.withValues(alpha: isDark ? 0.08 : 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.tierPro.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  _FeatureRow(
                    icon: Icons.edit_note_rounded,
                    text: 'Her karşılaştırmaya kişisel not ekle',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    icon: Icons.thumb_up_alt_rounded,
                    text: 'Artılar ve eksiler ile detaylı analiz yap',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    icon: Icons.star_rounded,
                    text: '1-5 yıldız tercih puanı ile sırala',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    icon: Icons.cloud_done_rounded,
                    text: 'Notların bulutta güvende — asla kaybolmaz',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── CTA Button ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.tierProGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.tierPro.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (!isLoggedIn) {
                      context.push('/login');
                    } else {
                      context.push('/compare/paywall');
                    }
                  },
                  icon: Icon(
                    isLoggedIn
                        ? Icons.workspace_premium_rounded
                        : Icons.login_rounded,
                    size: 20,
                  ),
                  label: Text(
                    isLoggedIn
                        ? 'Pro Plana Yükselt'
                        : 'Giriş Yap ve Pro Ol',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ─── Dismiss link ────────────────────────────────
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Şimdilik geç',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textTertiaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _FeatureRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.tierPro.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.tierPro),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? Colors.white.withValues(alpha: 0.85) : AppColors.textPrimaryFor(context),
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Üçlü Karşılaştırma Sonuç Görünümü (Pro) ──────────────────────────
// Tasarım: Olimpiyat madalya podyumu — kazanan ortada büyük, diğerleri
// yanlarda küçük. Altında kategori sayım rozetleri ve animasyonlu barlar.

class _TripleResultView extends ConsumerWidget {
  const _TripleResultView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResult = ref.watch(tripleComparisonResultProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return asyncResult.when(
      loading: () => const ComparisonResultSkeleton(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Hata: $e', textAlign: TextAlign.center),
        ),
      ),
      data: (result) {
        if (result == null) return _EmptyState(isDark: isDark);
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(tripleComparisonResultProvider);
            await ref.read(tripleComparisonResultProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Podyum (kazanan ortada)
                _TriplePodium(result: result, isDark: isDark),
                const SizedBox(height: 4),

                // Kategori sayım rozetleri
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _TripleScoreChips(result: result, isDark: isDark),
                ),

                const SizedBox(height: 20),

                // Quick Stats — yorum, yıl, bölüm sayısı
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TripleQuickStats(result: result, isDark: isDark),
                ),
                const SizedBox(height: 24),

                // Kategoriler başlığı
                if (result.categoryComparisons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.equalizer_rounded,
                            size: 18, color: AppColors.tierPro),
                        const SizedBox(width: 8),
                        Text(
                          'Kategori Karşılaştırması',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (result.categoryComparisons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        for (final entry
                            in result.categoryComparisons.values.toList()
                              ..sort((a, b) =>
                                  b.maxValue.compareTo(a.maxValue)))
                          _AnimatedTripleCategoryBar(
                            comparison: entry,
                            result: result,
                            isDark: isDark,
                            delay: Duration(
                              milliseconds:
                                  result.categoryComparisons.keys.toList().indexOf(entry.categoryName) *
                                      80,
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── PODYUM ─────────────────────────────────────────────────────────

class _TriplePodium extends StatelessWidget {
  final TripleComparisonResult result;
  final bool isDark;
  const _TriplePodium({required this.result, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Üniversiteleri rating'e göre sırala (1., 2., 3.)
    final ranked = <_RankedUni>[
      _RankedUni(uni: result.uniA, color: AppColors.primary),
      _RankedUni(uni: result.uniB, color: AppColors.secondary),
      _RankedUni(uni: result.uniC, color: AppColors.accent),
    ]..sort((a, b) => b.uni.avgRating.compareTo(a.uni.avgRating));

    final first = ranked[0];
    final second = ranked[1];
    final third = ranked[2];

    // Eğer ilk ikisi çok yakınsa kazanan yok — tüm üçü eşit yükseklikte
    final hasTie = (first.uni.avgRating - second.uni.avgRating).abs() < 0.05;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkSurface, const Color(0xFF1A1A2E)]
              : [
                  AppColors.tierPro.withValues(alpha: 0.04),
                  AppColors.primary.withValues(alpha: 0.04),
                ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumSpot(
              rank: hasTie ? null : 2,
              ranked: second,
              isDark: isDark,
              heightFactor: hasTie ? 1.0 : 0.85,
            ),
          ),
          Expanded(
            child: _PodiumSpot(
              rank: hasTie ? null : 1,
              ranked: first,
              isDark: isDark,
              heightFactor: 1.0,
              isFirst: !hasTie,
            ),
          ),
          Expanded(
            child: _PodiumSpot(
              rank: hasTie ? null : 3,
              ranked: third,
              isDark: isDark,
              heightFactor: hasTie ? 1.0 : 0.75,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankedUni {
  final UniversityModel uni;
  final Color color;
  const _RankedUni({required this.uni, required this.color});
}

class _PodiumSpot extends StatelessWidget {
  final int? rank; // null = tie (rozet gizli)
  final _RankedUni ranked;
  final bool isDark;
  final double heightFactor;
  final bool isFirst;

  const _PodiumSpot({
    required this.rank,
    required this.ranked,
    required this.isDark,
    required this.heightFactor,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = 56.0 + (heightFactor * 16.0); // 1. uni daha büyük
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. olan için "👑 Lider" rozeti
        if (isFirst)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: AppColors.tierProGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.tierPro.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.emoji_events_rounded,
                    color: Colors.white, size: 12),
                SizedBox(width: 3),
                Text(
                  'LİDER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 18),

        const SizedBox(height: 8),

        // Logo (reusable widget) + sıra rozeti
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            UniversityLogoBox(
              universityId: ranked.uni.id,
              universityName: ranked.uni.name,
              accentColor: isFirst ? AppColors.tierPro : ranked.color,
              size: logoSize,
              isWinner: isFirst,
            ),
            // Sıra rozeti (sadece tie değilse)
            if (rank != null)
              Positioned(
                bottom: -6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirst
                        ? AppColors.tierPro
                        : (isDark ? AppColors.darkSurface : Colors.white),
                    border: Border.all(
                      color: isFirst ? Colors.transparent : ranked.color,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: isFirst ? Colors.white : ranked.color,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 14),

        // İsim
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            ranked.uni.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: isFirst ? FontWeight.w900 : FontWeight.w700,
              fontSize: isFirst ? 12 : 11,
              height: 1.2,
              color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Rating
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded,
                size: isFirst ? 18 : 15,
                color: isFirst ? AppColors.tierPro : ranked.color),
            const SizedBox(width: 3),
            Text(
              ranked.uni.avgRating > 0
                  ? ranked.uni.avgRating.toStringAsFixed(1)
                  : '—',
              style: TextStyle(
                color: isFirst ? AppColors.tierPro : ranked.color,
                fontWeight: FontWeight.w900,
                fontSize: isFirst ? 17 : 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${ranked.uni.reviewCount} yorum',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ─── KATEGORİ SAYIM ROZETLERİ ────────────────────────────────────────

class _TripleScoreChips extends StatelessWidget {
  final TripleComparisonResult result;
  final bool isDark;
  const _TripleScoreChips({required this.result, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final aWins = result.categoriesWonBy(result.uniA.id);
    final bWins = result.categoriesWonBy(result.uniB.id);
    final cWins = result.categoriesWonBy(result.uniC.id);
    final tied = result.categoriesTied;
    final total = result.categoryComparisons.length;

    if (total == 0) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ScoreChip(
          name: result.uniA.name,
          wins: aWins,
          color: AppColors.primary,
          isDark: isDark,
        ),
        _ScoreChip(
          name: result.uniB.name,
          wins: bWins,
          color: AppColors.secondary,
          isDark: isDark,
        ),
        _ScoreChip(
          name: result.uniC.name,
          wins: cWins,
          color: AppColors.accent,
          isDark: isDark,
        ),
        if (tied > 0)
          _ScoreChip(
            name: 'Berabere',
            wins: tied,
            color: AppColors.textTertiaryFor(context),
            isDark: isDark,
            icon: Icons.balance_rounded,
          ),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String name;
  final int wins;
  final Color color;
  final bool isDark;
  final IconData icon;

  const _ScoreChip({
    required this.name,
    required this.wins,
    required this.color,
    required this.isDark,
    this.icon = Icons.emoji_events_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            name,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$wins',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── QUICK STATS ─────────────────────────────────────────────────────

class _TripleQuickStats extends StatelessWidget {
  final TripleComparisonResult result;
  final bool isDark;
  const _TripleQuickStats({required this.result, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.borderLightFor(context),
        ),
      ),
      child: Column(
        children: [
          _StatRow(
            label: 'Toplam Yorum',
            valueA: '${result.uniA.reviewCount}',
            valueB: '${result.uniB.reviewCount}',
            valueC: '${result.uniC.reviewCount}',
            isDark: isDark,
            isFirst: true,
          ),
          _StatRow(
            label: 'Bölüm Sayısı',
            valueA: '${result.stats.totalDepartmentsA}',
            valueB: '${result.stats.totalDepartmentsB}',
            valueC: '${result.stats.totalDepartmentsC}',
            isDark: isDark,
          ),
          _StatRow(
            label: 'Mekan Sayısı',
            valueA: '${result.placeCountA}',
            valueB: '${result.placeCountB}',
            valueC: '${result.placeCountC}',
            isDark: isDark,
          ),
          _StatRow(
            label: 'Kuruluş',
            valueA: '${result.uniA.establishedYear}',
            valueB: '${result.uniB.establishedYear}',
            valueC: '${result.uniC.establishedYear}',
            isDark: isDark,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String valueA;
  final String valueB;
  final String valueC;
  final bool isDark;
  final bool isFirst;
  final bool isLast;

  const _StatRow({
    required this.label,
    required this.valueA,
    required this.valueB,
    required this.valueC,
    required this.isDark,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.borderLightFor(context),
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiaryFor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valueA,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valueB,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valueC,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ANİMASYONLU KATEGORİ BARI ───────────────────────────────────────

class _AnimatedTripleCategoryBar extends StatefulWidget {
  final TripleCategoryComparison comparison;
  final TripleComparisonResult result;
  final bool isDark;
  final Duration delay;

  const _AnimatedTripleCategoryBar({
    required this.comparison,
    required this.result,
    required this.isDark,
    this.delay = Duration.zero,
  });

  @override
  State<_AnimatedTripleCategoryBar> createState() =>
      _AnimatedTripleCategoryBarState();
}

class _AnimatedTripleCategoryBarState
    extends State<_AnimatedTripleCategoryBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comparison;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final progress = _anim.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.04)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.borderLightFor(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      c.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (c.winnerId != null) ...[
                    Icon(Icons.emoji_events_rounded,
                        size: 14, color: AppColors.tierPro),
                    const SizedBox(width: 3),
                    Text(
                      _winnerShortName(c.winnerId!),
                      style: TextStyle(
                        color: AppColors.tierPro,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            AppColors.textTertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'BERABERE',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiaryFor(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _CategoryBarLine(
                label: widget.result.uniA.name,
                value: c.valueA,
                normalized: c.normalizedFor(c.valueA) * progress,
                color: AppColors.primary,
                isWinner: c.winnerId == widget.result.uniA.id,
              ),
              const SizedBox(height: 8),
              _CategoryBarLine(
                label: widget.result.uniB.name,
                value: c.valueB,
                normalized: c.normalizedFor(c.valueB) * progress,
                color: AppColors.secondary,
                isWinner: c.winnerId == widget.result.uniB.id,
              ),
              const SizedBox(height: 8),
              _CategoryBarLine(
                label: widget.result.uniC.name,
                value: c.valueC,
                normalized: c.normalizedFor(c.valueC) * progress,
                color: AppColors.accent,
                isWinner: c.winnerId == widget.result.uniC.id,
              ),
            ],
          ),
        );
      },
    );
  }

  String _winnerShortName(String id) {
    final result = widget.result;
    final UniversityModel u;
    if (id == result.uniA.id) {
      u = result.uniA;
    } else if (id == result.uniB.id) {
      u = result.uniB;
    } else {
      u = result.uniC;
    }
    // Kısa isim: ilk kelimeler. Uzunsa kısalt.
    final parts = u.name.split(' ');
    if (parts.length > 2) return '${parts.first} ${parts[1]}';
    return u.name;
  }
}

class _CategoryBarLine extends StatelessWidget {
  final String label;
  final double value;
  final double normalized;
  final Color color;
  final bool isWinner;

  const _CategoryBarLine({
    required this.label,
    required this.value,
    required this.normalized,
    required this.color,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Row(
            children: [
              if (isWinner)
                Icon(Icons.check_circle_rounded, size: 13, color: color),
              if (isWinner) const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  color: color.withValues(alpha: 0.08),
                ),
                FractionallySizedBox(
                  widthFactor: normalized.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.6),
                          color,
                        ],
                      ),
                      boxShadow: isWinner
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text(
            value > 0 ? value.toStringAsFixed(1) : '—',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
