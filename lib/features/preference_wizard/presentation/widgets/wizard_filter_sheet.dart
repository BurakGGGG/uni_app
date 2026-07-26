import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/turkish_compare.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../domain/models/wizard_filter.dart';
import '../providers/preference_wizard_providers.dart';
import 'wizard_select_chip.dart';

/// Tercih robotu filtre bottom sheet'i (Plus özelliği). `wizardFilterProvider`'ı
/// düzenler.
class WizardFilterSheet {
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
    final filter = ref.watch(wizardFilterProvider);
    final notifier = ref.read(wizardFilterProvider.notifier);
    final citiesAsync = ref.watch(citiesProvider);

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
              if (filter.hasAnyFilter)
                TextButton(
                  onPressed: () =>
                      notifier.state = const WizardFilter(),
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
              _SectionTitle('Sıralama'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  WizardSelectChip(
                    label: 'Uygunluğa göre',
                    selected: filter.sort == WizardSort.fit,
                    onTap: () =>
                        notifier.state = filter.copyWith(sort: WizardSort.fit),
                  ),
                  WizardSelectChip(
                    label: 'Taban puanı',
                    selected: filter.sort == WizardSort.baseDesc,
                    onTap: () => notifier.state =
                        filter.copyWith(sort: WizardSort.baseDesc),
                  ),
                  WizardSelectChip(
                    label: 'Başarı sıralaması',
                    selected: filter.sort == WizardSort.rankAsc,
                    onTap: () => notifier.state =
                        filter.copyWith(sort: WizardSort.rankAsc),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionTitle('Üniversite tipi'),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in const ['Devlet', 'Vakıf'])
                    WizardSelectChip(
                      label: t,
                      selected: filter.uniTypes.contains(t),
                      onTap: () => notifier.state = filter.copyWith(
                        uniTypes: _toggle(filter.uniTypes, t),
                      ),
                    ),
                  WizardSelectChip(
                    label: 'Sadece burslu',
                    selected: filter.onlyScholarship,
                    onTap: () => notifier.state = filter.copyWith(
                      onlyScholarship: !filter.onlyScholarship,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionTitle('Program tipi'),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in const ['Lisans', 'Önlisans'])
                    WizardSelectChip(
                      label: t,
                      selected: filter.programTypes.contains(t),
                      onTap: () => notifier.state = filter.copyWith(
                        programTypes: _toggle(filter.programTypes, t),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionTitle('Öğretim dili'),
              Wrap(
                spacing: 8,
                children: [
                  for (final l in const ['Türkçe', 'İngilizce'])
                    WizardSelectChip(
                      label: l,
                      selected: filter.languages.contains(l),
                      onTap: () => notifier.state = filter.copyWith(
                        languages: _toggle(filter.languages, l),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionTitle('Şehir'),
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
                        WizardSelectChip(
                          label: c.name,
                          selected: filter.cityIds.contains(c.id),
                          onTap: () => notifier.state = filter.copyWith(
                            cityIds: _toggle(filter.cityIds, c.id),
                          ),
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
                  filter.activeFilterCount > 0
                      ? 'Sonuçları göster (${filter.activeFilterCount} filtre)'
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

