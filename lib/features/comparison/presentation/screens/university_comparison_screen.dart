import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptic.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../data/ai_comparison_summary_service.dart';
import '../../domain/compare_note.dart';
import '../../domain/compare_view_builders.dart';
import '../../domain/models/comparison_result.dart';
import '../providers/comparison_providers.dart';
import '../widgets/compare/compare_bridge_card.dart';
import '../widgets/compare/compare_layout.dart';
import '../widgets/compare/compare_personal_card.dart';
import '../widgets/comparison_ai_summary_card.dart';
import '../widgets/comparison_empty_state.dart';
import '../widgets/comparison_notes_section.dart';
import '../widgets/comparison_result_skeleton.dart';
import '../widgets/comparison_share_card.dart';
import '../widgets/comparison_uni_picker.dart';
import '../widgets/offline_banner.dart';
import '../widgets/triple_third_uni_picker.dart';

/// Üniversite karşılaştırma.
///
/// **Sekmeler kaldırıldı** (kullanıcı kararı): Genel/Kategoriler/Grafik/
/// İstatistik/Notlarım beşlisi tek soruyu — hangisi, neden — beş parçaya
/// bölüyordu. Şimdi tek akış: taraf şeridi → fark özeti → senin için →
/// ölçütler → köprüler. Ortak iskelet `CompareLayout`'ta; bölüm ve şehir
/// ekranları da aynısını kullanıyor.
class UniversityComparisonScreen extends ConsumerStatefulWidget {
  /// Deep-link veya geçmişten gelen önceden seçili üniversite ID'leri.
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
      if (previous is AsyncLoading) AppHaptic.compareSuccess();
    });
    ref.listen(comparisonGateDecisionProvider, (previous, next) {
      next.whenData((decision) {
        if (decision != null && !decision.isAllowed) AppHaptic.limitReached();
      });
    });

    final selection = ref.watch(comparisonSelectionProvider);
    final resultAsync = ref.watch(comparisonResultProvider);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          loc.comparisonUniversity,
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          // Yer değiştirme ve taraf değiştirme artık şeritte; üst çubukta
          // yalnız paylaş + taşma menüsü kaldı (dört ikon fazlaydı).
          if (selection.bothSelected)
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
          if (selection.uniIdA != null || selection.uniIdB != null)
            _OverflowMenu(selection: selection),
        ],
      ),
      body: Column(
        children: [
          if (!ref.watch(isOnlineProvider)) const OfflineBanner(),
          Expanded(child: _body(context, selection, resultAsync)),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    ComparisonSelection selection,
    AsyncValue<ComparisonResult?> resultAsync,
  ) {
    if (selection.allThreeSelected) return const _TripleResult();

    if (!selection.bothSelected) {
      return SingleChildScrollView(
        child: Column(
          children: [
            const ComparisonUniPicker(),
            const SizedBox(height: 8),
            ComparisonEmptyState(
              title: AppLocalizations.of(context).comparisonEmptyUniversityTitle,
              subtitle:
                  AppLocalizations.of(context).comparisonEmptyUniversityDesc,
            ),
          ],
        ),
      );
    }

    return resultAsync.when(
      loading: () => const ComparisonResultSkeleton(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            AppLocalizations.of(context).errorGeneral(e.toString()),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (result) {
        if (result == null) {
          return ComparisonEmptyState(
            title: AppLocalizations.of(context).comparisonEmptyUniversityTitle,
            subtitle: AppLocalizations.of(context).comparisonEmptyUniversityDesc,
          );
        }
        return _PairResult(result: result);
      },
    );
  }
}

// ─── İkili sonuç ───────────────────────────────────────────────────

class _PairResult extends ConsumerWidget {
  final ComparisonResult result;
  const _PairResult({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final view = universityCompareView(result, loc);

    return CompareLayout(
      view: view,
      onChangeSide: (index) =>
          showComparisonUniPicker(context, ref, isA: index == 0),
      onSwap: () {
        AppHaptic.swap();
        ref.read(comparisonSelectionProvider.notifier).swap();
      },
      personal: ComparePersonalCard(sides: view.sides),
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
      extras: [
        CompareBridgeCard(
          icon: Icons.insights_rounded,
          color: AppColors.secondary,
          title: loc.cmpChartsTitle,
          subtitle: loc.cmpChartsDesc,
          onTap: () => context.push('/compare/university/charts'),
        ),
        _AiSummarySection(result: result),
        ComparisonNotesSection(
          comparisonType: 'university',
          entityAId: result.uniA.id,
          entityBId: result.uniB.id,
        ),
      ],
    );
  }
}

// ─── Üçlü sonuç ────────────────────────────────────────────────────

/// Podyum KALKTI (kullanıcı kararı): ekran kazanan ilan etmiyorken üçlü
/// modun kupalı podyumu tek başına bağırıyordu. Aynı fark satırları, iki
/// yerine üç sütun.
class _TripleResult extends ConsumerWidget {
  const _TripleResult();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final asyncResult = ref.watch(tripleComparisonResultProvider);

    return asyncResult.when(
      loading: () => const ComparisonResultSkeleton(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            loc.errorGeneral(e.toString()),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (result) {
        if (result == null) {
          return ComparisonEmptyState(
            title: loc.comparisonEmptyUniversityTitle,
            subtitle: loc.comparisonEmptyUniversityDesc,
          );
        }
        final view = tripleCompareView(result, loc);
        return CompareLayout(
          view: view,
          personal: ComparePersonalCard(sides: view.sides),
          onRefresh: () async {
            ref.invalidate(tripleComparisonResultProvider);
            await ref.read(tripleComparisonResultProvider.future);
          },
        );
      },
    );
  }
}

// ─── Üst çubuk taşma menüsü ────────────────────────────────────────

class _OverflowMenu extends ConsumerWidget {
  final ComparisonSelection selection;
  const _OverflowMenu({required this.selection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final canTriple = selection.bothSelected;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (value) async {
        switch (value) {
          case 'reset':
            _confirmReset(context, ref);
          case 'third':
            await _addThird(context, ref);
          case 'removeThird':
            AppHaptic.reset();
            ref.read(comparisonSelectionProvider.notifier).removeC();
        }
      },
      itemBuilder: (context) => [
        if (canTriple && !selection.allThreeSelected)
          PopupMenuItem(
            value: 'third',
            child: _MenuRow(
              icon: Icons.group_add_rounded,
              label: loc.comparisonAddThirdTooltip,
            ),
          ),
        if (selection.allThreeSelected)
          PopupMenuItem(
            value: 'removeThird',
            child: _MenuRow(
              icon: Icons.person_remove_rounded,
              label: loc.comparisonRemoveThirdTooltip,
            ),
          ),
        PopupMenuItem(
          value: 'reset',
          child: _MenuRow(
            icon: Icons.refresh_rounded,
            label: loc.reset,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Future<void> _addThird(BuildContext context, WidgetRef ref) async {
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
    if (selectedId == null || !context.mounted) return;
    ref.read(comparisonSelectionProvider.notifier).selectC(selectedId);
  }

  static void _confirmReset(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          loc.comparisonResetTitle,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          loc.comparisonResetConfirm,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              AppHaptic.reset();
              Navigator.pop(ctx);
              ref.read(comparisonSelectionProvider.notifier).reset();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(loc.reset),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

// ─── Pro yapay zekâ özeti ──────────────────────────────────────────
//
// Üni'nin kural tabanlı tek cümlesi fark özetinin içinde; bu ise uzun
// biçimli Pro analizi. İkisi ayrı işler — biri her zaman dolu ve
// ücretsiz, öteki derinlik satıyor.

class _AiSummarySection extends ConsumerWidget {
  final ComparisonResult result;
  const _AiSummarySection({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(aiComparisonSummaryProvider, (previous, next) {
      if (next is! AsyncData<AiComparisonSummaryResult?>) return;
      final summary = next.value;
      if (summary == null || summary.summary.trim().isEmpty) return;
      if (previous is AsyncLoading) AppHaptic.aiSummaryReceived();
    });

    ref.listen<RegenerateFeedback?>(regenerateFeedbackProvider, (prev, next) {
      if (next == null) return;
      if (prev?.tag == next.tag) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: next.isError ? AppColors.error : AppColors.success,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ));
      Future.microtask(
        () => ref.read(regenerateFeedbackProvider.notifier).state = null,
      );
    });

    final canUseAi = ref.watch(canUseAiComparisonProvider);
    final usage = ref.watch(usageStatsProvider);
    final tier =
        ref.watch(subscriptionTierProvider).valueOrNull ?? SubscriptionTier.free;
    final aiSummaryAsync = ref.watch(aiComparisonSummaryProvider);

    final bool aiLoading = usage.isLoading || aiSummaryAsync.isLoading;
    final String aiSummaryText = aiSummaryAsync.valueOrNull?.summary ?? '';
    final bool aiLimitReached = tier == SubscriptionTier.pro && !canUseAi;
    String? aiErrorMessage;
    if (aiSummaryAsync.hasError) {
      final err = aiSummaryAsync.error;
      aiErrorMessage = err is AiSummaryFailure
          ? err.userMessage
          : AppLocalizations.of(context).commonError;
    }

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
      // Yedek metin Üni'nin fark cümlesi — model üzerindeki eski
      // `summaryText` "X öne çıkıyor" diyordu ve ekranın kazanan ilan
      // etmeme kararıyla çelişiyordu.
      summaryText: aiSummaryText.isNotEmpty
          ? aiSummaryText
          : compareNoteFor(
              universityCompareView(result, AppLocalizations.of(context)),
            ).text,
      errorMessage: aiErrorMessage,
      onRetry: aiErrorMessage != null
          ? () => ref.invalidate(aiComparisonSummaryProvider)
          : null,
      regenerateAllowed: regenerateAllowed,
      onRegenerate: regenerateAllowed ? () => triggerAiRegenerate(ref) : null,
    );
  }
}
