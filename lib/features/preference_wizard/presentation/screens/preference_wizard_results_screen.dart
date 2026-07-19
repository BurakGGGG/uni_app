import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../../assistant/domain/robot_mood.dart';
import '../../../assistant/domain/robot_scripts.dart';
import '../../../assistant/presentation/providers/assistant_providers.dart';
import '../../../assistant/presentation/widgets/robot_avatar.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import '../../domain/models/wizard_filter.dart';
import '../../domain/preference_match_engine.dart';
import '../providers/preference_wizard_providers.dart';
import '../widgets/auto_build_list_sheet.dart';
import '../widgets/compare_matches_sheet.dart';
import '../widgets/wizard_category_bar.dart';
import '../widgets/wizard_empty_state.dart';
import '../widgets/wizard_filter_sheet.dart';
import '../widgets/wizard_recommendation_card.dart';
import '../widgets/wizard_summary_header.dart';

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

  /// Karşılaştırma için uzun basışla seçilen program id'leri (en çok 3).
  final Set<String> _compareIds = {};

  late final TextEditingController _searchCtrl;

  void _toggleCompare(String deptId) {
    setState(() {
      if (!_compareIds.remove(deptId)) {
        if (_compareIds.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('En fazla 3 program karşılaştırılabilir')),
          );
          return;
        }
        _compareIds.add(deptId);
      }
    });
  }

  void _showCompare(PreferenceMatchResult result) {
    final all = [...result.guaranteed, ...result.target, ...result.dream];
    final picks =
        all.where((m) => _compareIds.contains(m.department.id)).toList();
    if (picks.length < 2) return;
    showCompareMatchesSheet(context, picks);
  }

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
      floatingActionButton: _compareIds.length >= 2 &&
              resultAsync.valueOrNull != null
          ? FloatingActionButton.extended(
              onPressed: () => _showCompare(resultAsync.value!),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.compare_arrows_rounded,
                  color: Colors.white),
              label: Text(
                'Karşılaştır (${_compareIds.length})',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
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
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const RobotAvatar(size: 72, mood: RobotMood.thinking),
              const SizedBox(height: 14),
              Text(
                kResultsLoadingText,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
        ),
        error: (e, _) => const WizardErrorState(),
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
                child: WizardSummaryHeader(
                  scoreType: profile.scoreType,
                  score: profile.placementScore,
                  rank: profile.hasRank ? profile.rank : null,
                  total: result.total,
                  message:
                      ref.watch(robotResultsMessageProvider).valueOrNull,
                ),
              ),
              SliverToBoxAdapter(child: _SearchField(controller: _searchCtrl)),
              if (result.total == 0)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: WizardEmptyResults(hasFilter: filter.hasAnyFilter),
                )
              else ...[
                SliverToBoxAdapter(
                  child: WizardCategoryBar(
                    result: result,
                    focus: _focus,
                    onChanged: (c) => setState(() => _focus = c),
                  ),
                ),
                if (_compareIds.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: Text(
                        'İpucu: iki programı karşılaştırmak için kartlara '
                        'uzun bas.',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiaryFor(context),
                          fontSize: 10.5,
                        ),
                      ),
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
          itemBuilder: (_, i) => WizardRecommendationCard(
            match: shown[i],
            selected: _compareIds.contains(shown[i].department.id),
            onLongPress: () => _toggleCompare(shown[i].department.id),
          ),
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

