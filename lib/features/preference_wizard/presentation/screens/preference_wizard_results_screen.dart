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

  /// Seçili kategori sekmesi (null = tümü görünür).
  MatchCategory? _focus;

  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl =
        TextEditingController(text: ref.read(wizardFilterProvider).deptQuery);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filtreler dışarıdan sıfırlanırsa (sheet'teki "Temizle" / boş-durum
    // butonu) arama kutusunu da temizle.
    ref.listen<WizardFilter>(wizardFilterProvider, (_, next) {
      if (next.deptQuery.isEmpty && _searchCtrl.text.isNotEmpty) {
        _searchCtrl.clear();
      }
    });

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
              SliverToBoxAdapter(child: _SearchField(controller: _searchCtrl)),
              if (result.total == 0)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyResults(hasFilter: filter.hasAnyFilter),
                )
              else ...[
                SliverToBoxAdapter(
                  child: _CategoryBar(
                    result: result,
                    focus: _focus,
                    onChanged: (c) => setState(() => _focus = c),
                  ),
                ),
                if (_focus == null || _focus == MatchCategory.guaranteed)
                  ..._categorySlivers(
                    context,
                    result,
                    MatchCategory.guaranteed,
                    hasPlus,
                  ),
                if (_focus == null || _focus == MatchCategory.target)
                  ..._categorySlivers(
                    context,
                    result,
                    MatchCategory.target,
                    hasPlus,
                  ),
                if (_focus == null || _focus == MatchCategory.dream)
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
        return const _CategoryMeta('🟢 Yüksek şans', AppColors.success);
      case MatchCategory.target:
        return const _CategoryMeta('🟡 Ulaşılabilir', AppColors.warning);
      case MatchCategory.dream:
        return const _CategoryMeta('🔴 Zorlayıcı', AppColors.error);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradientFor(context),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              _Pill(
                  label: 'Puan',
                  value: '${score.toStringAsFixed(1)} $scoreType'),
              const SizedBox(width: 10),
              if (rank != null)
                _Pill(label: 'Sıralama', value: _fmt(rank!))
              else
                _Pill(label: 'Eşleşen', value: '$total program'),
              const Spacer(),
              const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 30),
            ],
          ),
        ),
        // Kesinlik iddiası yok — öneriler geçmiş yıl verisine dayalı tahmin.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 13, color: AppColors.textTertiaryFor(context)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Öneriler geçmiş yıl verilerine dayalı tahmindir, '
                  'yerleşme garantisi vermez.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryFor(context),
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

/// Sonuç içinde bölüm/fakülte araması — binlerce kayıt elle gezilmesin.
/// `wizardFilterProvider.deptQuery`'yi günceller (motor zaten filtreliyor).
class _SearchField extends ConsumerWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void setQuery(String value) {
      final notifier = ref.read(wizardFilterProvider.notifier);
      notifier.state = notifier.state.copyWith(deptQuery: value);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: TextField(
        controller: controller,
        onChanged: setQuery,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Bölüm veya fakülte ara (örn. Bilgisayar)',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiaryFor(context),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.textTertiaryFor(context),
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Temizle',
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textTertiaryFor(context),
                  ),
                  onPressed: () {
                    controller.clear();
                    setQuery('');
                  },
                ),
          isDense: true,
          filled: true,
          fillColor:
              AppColors.surfaceVariantFor(context).withValues(alpha: 0.7),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.borderLightFor(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Kategorilere hızlı odaklanma sekmeleri: Yüksek şans / Ulaşılabilir /
/// Zorlayıcı. Seçiliye tekrar dokununca tümü görünür.
class _CategoryBar extends StatelessWidget {
  final PreferenceMatchResult result;
  final MatchCategory? focus;
  final ValueChanged<MatchCategory?> onChanged;

  const _CategoryBar({
    required this.result,
    required this.focus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, MatchCategory category, Color color) {
      final selected = focus == category;
      final count = result.forCategory(category).length;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(selected ? null : category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? color : Colors.transparent,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: selected
                          ? color
                          : AppColors.textSecondaryFor(context),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$count',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: selected
                          ? color
                          : AppColors.textTertiaryFor(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Row(
        children: [
          chip('Yüksek şans', MatchCategory.guaranteed, AppColors.success),
          const SizedBox(width: 4),
          chip('Ulaşılabilir', MatchCategory.target, AppColors.warning),
          const SizedBox(width: 4),
          chip('Zorlayıcı', MatchCategory.dream, AppColors.error),
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
