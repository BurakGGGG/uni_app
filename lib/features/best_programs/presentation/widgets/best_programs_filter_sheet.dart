import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/turkish_compare.dart';
import '../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../domain/models/best_programs_query.dart';
import '../providers/best_programs_providers.dart';

/// "En iyi bölümler" filtre sheet'i — `WizardFilterSheet`'in kardeşi, aynı
/// görsel dil. Kapsam (alan/bölüm/arama) burada değişmez, yalnız filtreler.
class BestProgramsFilterSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => _Body(scrollController: controller),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final ScrollController scrollController;
  const _Body({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(bestProgramsQueryProvider);
    final notifier = ref.read(bestProgramsQueryProvider.notifier);
    final citiesAsync = ref.watch(citiesProvider);
    final hasProfile = ref.watch(studentScoreProfileProvider) != null;

    void update(BestProgramsQuery next) => notifier.state = next;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 4),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderLightFor(context),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Filtreler',
                  style: AppTextStyles.titleLarge
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (query.activeFilterCount > 0)
                TextButton(
                  // Kapsam korunur, yalnız filtreler sıfırlanır.
                  onPressed: () => update(BestProgramsQuery(
                    categoryKey: query.categoryKey,
                    departmentName: query.departmentName,
                    search: query.search,
                    sort: query.sort,
                  )),
                  child: const Text('Temizle'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const _SectionTitle('Sıralama'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Choice(
                    label: 'Başarı sıralaması',
                    selected: query.sort == BestProgramsSort.rankAsc,
                    onTap: () => update(
                        query.copyWith(sort: BestProgramsSort.rankAsc)),
                  ),
                  _Choice(
                    label: 'Taban puanı',
                    selected: query.sort == BestProgramsSort.scoreDesc,
                    onTap: () => update(
                        query.copyWith(sort: BestProgramsSort.scoreDesc)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const _SectionTitle('Üniversite tipi'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in const ['Devlet', 'Vakıf'])
                    _Choice(
                      label: t,
                      selected: query.uniTypes.contains(t),
                      onTap: () => update(query.copyWith(
                          uniTypes: _toggle(query.uniTypes, t))),
                    ),
                  _Choice(
                    label: 'Sadece burslu',
                    selected: query.onlyScholarship,
                    onTap: () => update(query.copyWith(
                        onlyScholarship: !query.onlyScholarship)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Vakıf programlarında gösterilen taban genelde burslu '
                'kontenjana aittir.',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textTertiaryFor(context)),
              ),
              const SizedBox(height: 20),

              const _SectionTitle('Program tipi'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in const ['Lisans', 'Önlisans'])
                    _Choice(
                      label: t,
                      selected: query.programTypes.contains(t),
                      onTap: () {
                        final next = _toggle(query.programTypes, t);
                        // Hiçbiri seçili değilken liste boşalmasın.
                        update(query.copyWith(
                            programTypes: next.isEmpty ? {t} : next));
                      },
                    ),
                  _Choice(
                    label: 'Açıköğretim / uzaktan',
                    selected: query.includeDistance,
                    onTap: () => update(query.copyWith(
                        includeDistance: !query.includeDistance)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const _SectionTitle('Öğretim dili'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final l in const ['Türkçe', 'İngilizce'])
                    _Choice(
                      label: l,
                      selected: query.languages.contains(l),
                      onTap: () => update(query.copyWith(
                          languages: _toggle(query.languages, l))),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              const _SectionTitle('Bana uygunluk'),
              _Choice(
                label: 'Sadece girebileceklerim',
                selected: query.onlyEligible,
                onTap: hasProfile
                    ? () => update(
                        query.copyWith(onlyEligible: !query.onlyEligible))
                    : null,
              ),
              if (!hasProfile) ...[
                const SizedBox(height: 6),
                Text(
                  'Bunun için önce puanını hesapla ya da sıranı gir.',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textTertiaryFor(context)),
                ),
              ],
              const SizedBox(height: 20),

              const _SectionTitle('Şehir'),
              citiesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (e, _) => Text('Şehirler yüklenemedi: $e'),
                data: (cities) {
                  final sorted = [...cities]
                    ..sort((a, b) => turkishCompare(a.name, b.name));
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in sorted)
                        _Choice(
                          label: c.name,
                          selected: query.cityIds.contains(c.id),
                          onTap: () => update(query.copyWith(
                              cityIds: _toggle(query.cityIds, c.id))),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  query.activeFilterCount > 0
                      ? 'Sonuçları göster (${query.activeFilterCount} filtre)'
                      : 'Sonuçları göster',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Set<String> _toggle(Set<String> set, String value) {
    final next = {...set};
    if (!next.add(value)) next.remove(value);
    return next;
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: AppTextStyles.labelMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondaryFor(context),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceVariantFor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.borderLightFor(context),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: selected
                  ? AppColors.primary
                  : AppColors.textPrimaryFor(context),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
