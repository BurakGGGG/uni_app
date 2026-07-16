import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import '../../domain/models/wizard_filter.dart';
import '../../domain/preference_match_engine.dart';
import '../providers/preference_wizard_providers.dart';
import '../widgets/auto_build_list_sheet.dart';
import '../widgets/wizard_filter_sheet.dart';
import '../widgets/wizard_recommendation_card.dart';

/// Ücretsiz kullanıcıya kategori başına gösterilen sonuç sayısı.
const int _kFreePerCategory = 3;

class PreferenceWizardResultsScreen extends ConsumerStatefulWidget {
  const PreferenceWizardResultsScreen({super.key});

  @override
  ConsumerState<PreferenceWizardResultsScreen> createState() =>
      _PreferenceWizardResultsScreenState();
}

class _PreferenceWizardResultsScreenState
    extends ConsumerState<PreferenceWizardResultsScreen> {
  bool _trackedMatch = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(studentScoreProfileProvider);
    final resultAsync = ref.watch(preferenceMatchResultProvider);
    final tier = ref.watch(subscriptionTierProvider).valueOrNull;
    final hasPlus = tier != null && tier.satisfies(SubscriptionTier.plus);
    final filter = ref.watch(wizardFilterProvider);

    if (profile == null) {
      // Profil temizlenmiş — girişe dön.
      return Scaffold(
        backgroundColor: AppColors.backgroundFor(context),
        appBar: AppBar(title: const Text('Tercih Robotu')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/preference-wizard'),
            child: const Text('Puanını gir'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundFor(context),
        elevation: 0,
        title: const Text('Önerilerin'),
        actions: [
          _FilterAction(
            activeCount: filter.activeFilterCount,
            onTap: () {
              if (!hasPlus) {
                context.push('/compare/paywall');
                return;
              }
              WizardFilterSheet.show(context);
            },
          ),
          IconButton(
            tooltip: 'Puanı düzenle',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push('/preference-wizard'),
          ),
        ],
      ),
      body: resultAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Bir hata oluştu: $e')),
        data: (result) {
          if (result == null) {
            return Center(
              child: FilledButton(
                onPressed: () => context.go('/preference-wizard'),
                child: const Text('Puanını gir'),
              ),
            );
          }

          if (!_trackedMatch) {
            _trackedMatch = true;
            AnalyticsService.instance
                .trackEvent(AnalyticsEvent.preferenceWizardMatched);
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _SummaryHeader(
                  scoreType: profile.scoreType,
                  score: profile.placementScore,
                  rank: profile.hasRank ? profile.rank : null,
                  total: result.total,
                ),
              ),
              if (result.total == 0)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyResults(hasFilter: filter.hasAnyFilter),
                )
              else ...[
                ..._categorySlivers(
                  context,
                  result,
                  MatchCategory.guaranteed,
                  hasPlus,
                ),
                ..._categorySlivers(
                  context,
                  result,
                  MatchCategory.target,
                  hasPlus,
                ),
                ..._categorySlivers(
                  context,
                  result,
                  MatchCategory.dream,
                  hasPlus,
                ),
                SliverToBoxAdapter(
                  child: _AutoBuildCta(hasPlus: hasPlus, result: result),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          );
        },
      ),
    );
  }

  List<Widget> _categorySlivers(
    BuildContext context,
    PreferenceMatchResult result,
    MatchCategory category,
    bool hasPlus,
  ) {
    final all = result.forCategory(category);
    if (all.isEmpty) return const [];

    final shown = hasPlus ? all : all.take(_kFreePerCategory).toList();
    final hiddenCount = all.length - shown.length;
    final meta = _categoryMeta(category);

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: meta.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                meta.title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: meta.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${all.length})',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textTertiaryFor(context),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.builder(
          itemCount: shown.length,
          itemBuilder: (_, i) => WizardRecommendationCard(match: shown[i]),
        ),
      ),
      if (hiddenCount > 0)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: _LockedMore(count: hiddenCount),
          ),
        ),
    ];
  }

  static _CategoryMeta _categoryMeta(MatchCategory c) {
    switch (c) {
      case MatchCategory.guaranteed:
        return const _CategoryMeta('🟢 Garanti', AppColors.success);
      case MatchCategory.target:
        return const _CategoryMeta('🟡 Hedef', AppColors.warning);
      case MatchCategory.dream:
        return const _CategoryMeta('🔴 Riskli / Şansını dene', AppColors.error);
    }
  }
}

class _CategoryMeta {
  final String title;
  final Color color;
  const _CategoryMeta(this.title, this.color);
}

class _SummaryHeader extends StatelessWidget {
  final String scoreType;
  final double score;
  final int? rank;
  final int total;

  const _SummaryHeader({
    required this.scoreType,
    required this.score,
    required this.rank,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _Pill(label: 'Puan', value: '${score.toStringAsFixed(1)} $scoreType'),
          const SizedBox(width: 10),
          if (rank != null)
            _Pill(label: 'Sıralama', value: _fmt(rank!))
          else
            _Pill(label: 'Eşleşen', value: '$total program'),
          const Spacer(),
          const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 30),
        ],
      ),
    );
  }

  static String _fmt(int rank) {
    final s = rank.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  const _Pill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall
                .copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
          Text(
            value,
            style: AppTextStyles.titleSmall
                .copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _FilterAction extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;
  const _FilterAction({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Filtrele',
          icon: const Icon(Icons.tune_rounded),
          onPressed: onTap,
        ),
        if (activeCount > 0)
          Positioned(
            right: 6,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$activeCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LockedMore extends StatelessWidget {
  final int count;
  const _LockedMore({required this.count});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/compare/paywall'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.tierPlus.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.tierPlus.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, color: AppColors.tierPlus, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '+$count sonuç daha — Plus ile tümünü aç',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.tierPlus,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.tierPlus),
          ],
        ),
      ),
    );
  }
}

class _AutoBuildCta extends ConsumerWidget {
  final bool hasPlus;
  final PreferenceMatchResult result;
  const _AutoBuildCta({required this.hasPlus, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: SizedBox(
        height: 54,
        child: FilledButton.icon(
          onPressed: () {
            if (!hasPlus) {
              context.push('/compare/paywall');
              return;
            }
            showAutoBuildListSheet(context, ref, result);
          },
          icon: Icon(hasPlus ? Icons.auto_awesome_rounded : Icons.lock_rounded),
          label: Text(
            hasPlus
                ? '24\'lük dengeli liste oluştur'
                : 'Plus: 24\'lük otomatik liste',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: hasPlus ? AppColors.primary : AppColors.tierPlus,
            textStyle:
                AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyResults extends ConsumerWidget {
  final bool hasFilter;
  const _EmptyResults({required this.hasFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: AppColors.textTertiaryFor(context)),
            const SizedBox(height: 16),
            Text(
              hasFilter ? 'Filtrelere uyan program yok' : 'Eşleşen program yok',
              style:
                  AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Filtreleri gevşetmeyi dene.'
                  : 'Puan türünü ve puanını kontrol et.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondaryFor(context)),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.read(wizardFilterProvider.notifier).state =
                    const WizardFilter(),
                child: const Text('Filtreleri temizle'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
