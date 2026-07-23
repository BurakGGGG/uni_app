import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/turkish_compare.dart';
import '../../../../router/app_router.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../../assistant/domain/robot_mood.dart';
import '../../../assistant/domain/robot_scripts.dart';
import '../../../assistant/presentation/widgets/robot_avatar.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../domain/models/wizard_filter.dart';
import '../../domain/models/wizard_prefs.dart';
import '../../domain/similar_programs.dart';
import '../providers/preference_wizard_providers.dart';

/// "Üni seni tanısın" — `/preference-wizard` rotasının yeni sahibi.
///
/// Burası eskiden Üni ile sohbetti: kullanıcı derdini yazacaktı, robot
/// anlayacaktı. Serbest yazı hiç açılmadı (çubuk blurluydu, "yakında"
/// diyordu) ve puan/sıra toplama işi Puan Hesaplayıcı'ya geçtiği için geriye
/// sohbetten yalnız tören kalmıştı. Onun yerine tek ekranlık, yazısız bir
/// seçim formu var — motorun ihtiyacı olan sinyaller üç dokunuşta toplanıyor.
///
/// İki katman bilinçli olarak ayrı:
/// - **Yumuşak** (ilgi, şehir, üniversite türü, dil) → [WizardPrefs].
///   Sıralamada öne çeker, hiçbir programı elemez. "Ankara isterim" diyen
///   biri İzmir'deki mükemmel programı görmemeli demek değildir.
/// - **Sert** (program türü, sadece burslu) → [WizardFilter]. Gerçekten
///   eler: burssuz bir vakıf programı çoğu öğrenci için seçenek değildir.
class UniProfileFormScreen extends ConsumerStatefulWidget {
  const UniProfileFormScreen({super.key});

  @override
  ConsumerState<UniProfileFormScreen> createState() =>
      _UniProfileFormScreenState();
}

class _UniProfileFormScreenState
    extends ConsumerState<UniProfileFormScreen> {
  late Set<String> _interests;
  late Set<String> _cityIds;
  late Set<String> _uniTypes;
  late Set<String> _languages;
  late Set<String> _programTypes;
  late bool _onlyScholarship;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance
        .trackEvent(AnalyticsEvent.preferenceWizardOpened);
    final prefs = ref.read(wizardPrefsProvider);
    final filter = ref.read(wizardFilterProvider);
    _interests = {...prefs.interestKeys};
    _cityIds = {...prefs.cityIds};
    _uniTypes = {...prefs.uniTypes};
    _languages = {...prefs.languages};
    _programTypes = {...filter.programTypes};
    _onlyScholarship = filter.onlyScholarship;
  }

  Future<void> _apply() async {
    await ref.read(wizardPrefsProvider.notifier).save(WizardPrefs(
          interestKeys: _interests,
          cityIds: _cityIds,
          uniTypes: _uniTypes,
          languages: _languages,
        ));
    final notifier = ref.read(wizardFilterProvider.notifier);
    notifier.state = notifier.state.copyWith(
      programTypes: _programTypes,
      onlyScholarship: _onlyScholarship,
    );
    if (mounted) context.push(AppRoutes.preferenceWizardResults);
  }

  @override
  Widget build(BuildContext context) {
    final en = RobotScripts.isEn;
    final citiesAsync = ref.watch(citiesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundFor(context),
        elevation: 0,
        title: Row(
          children: [
            const RobotAvatar(size: 32, mood: RobotMood.happy),
            const SizedBox(width: 10),
            Text(en ? 'Let me get to know you' : 'Üni seni tanısın'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            en
                ? "Nothing here is required — each answer just pulls the "
                    'programs that suit you higher up the list.'
                : 'Hiçbiri zorunlu değil — her cevap sana uyan programları '
                    'listede yukarı çeker.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          _Section(
            title: en ? 'What interests you?' : 'Neye ilgin var?',
            hint: en
                ? 'Programs in these areas rank higher.'
                : 'Bu alanlardaki programlar üst sıralara çıkar.',
            child: _ChipGrid(
              options: [
                for (final area in interestAreas)
                  (
                    area.key,
                    RobotScripts.interestLabel(area.key, area.label),
                  ),
              ],
              selected: _interests,
              onToggle: (key) => setState(() => _toggle(_interests, key)),
            ),
          ),

          _Section(
            title: en ? 'Which cities?' : 'Hangi şehirler?',
            hint: en
                ? 'Leave empty for "anywhere".'
                : 'Boş bırakırsan "fark etmez" demektir.',
            child: citiesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
              error: (_, _) => Text(
                en ? 'Cities could not be loaded.' : 'Şehirler yüklenemedi.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textTertiaryFor(context)),
              ),
              data: (cities) {
                final sorted = [...cities]
                  ..sort((a, b) => turkishCompare(a.name, b.name));
                return _ChipGrid(
                  options: [for (final c in sorted) (c.id, c.name)],
                  selected: _cityIds,
                  onToggle: (id) => setState(() => _toggle(_cityIds, id)),
                );
              },
            ),
          ),

          _Section(
            title: en ? 'University type' : 'Üniversite türü',
            child: _ChipGrid(
              options: [
                for (final type in const ['Devlet', 'Vakıf'])
                  (type, RobotScripts.filterLabel(type)),
              ],
              selected: _uniTypes,
              onToggle: (type) => setState(() => _toggle(_uniTypes, type)),
            ),
          ),

          _Section(
            title: en ? 'Language of instruction' : 'Öğretim dili',
            child: _ChipGrid(
              options: [
                for (final lang in const ['Türkçe', 'İngilizce'])
                  (lang, RobotScripts.filterLabel(lang)),
              ],
              selected: _languages,
              onToggle: (lang) => setState(() => _toggle(_languages, lang)),
            ),
          ),

          const SizedBox(height: 4),
          _HardDivider(
            text: en
                ? 'The two below actually filter — programs outside them are '
                    'removed from the results.'
                : 'Aşağıdaki ikisi gerçekten eler — dışında kalan programlar '
                    'sonuçlardan çıkar.',
          ),

          _Section(
            title: en ? 'Program length' : 'Program türü',
            child: _ChipGrid(
              options: [
                for (final type in const ['Lisans', 'Önlisans'])
                  (type, RobotScripts.filterLabel(type)),
              ],
              selected: _programTypes,
              onToggle: (type) => setState(() => _toggle(_programTypes, type)),
            ),
          ),

          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _onlyScholarship,
            onChanged: (v) => setState(() => _onlyScholarship = v),
            title: Text(
              en ? 'Scholarship programs only' : 'Sadece burslu programlar',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              en
                  ? 'Foundation universities without a scholarship are hidden.'
                  : 'Burssuz vakıf programları gizlenir.',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textTertiaryFor(context)),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _apply,
              icon: const Icon(Icons.school_rounded, size: 18),
              label: Text(en ? 'Show my matches' : 'Önerilerimi göster'),
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(Set<String> set, String value) {
    if (!set.remove(value)) set.add(value);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? hint;
  final Widget child;
  const _Section({required this.title, this.hint, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textTertiaryFor(context)),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// (değer, etiket) çiftlerinden çoktan seçmeli çip ızgarası.
class _ChipGrid extends StatelessWidget {
  final List<(String, String)> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _ChipGrid({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, label) in options)
          FilterChip(
            label: Text(label),
            selected: selected.contains(value),
            showCheckmark: false,
            labelStyle: AppTextStyles.chip.copyWith(
              color: selected.contains(value) ? AppColors.primary : null,
              fontWeight:
                  selected.contains(value) ? FontWeight.w700 : FontWeight.w500,
            ),
            selectedColor: AppColors.primary.withValues(alpha: 0.12),
            onSelected: (_) => onToggle(value),
          ),
      ],
    );
  }
}

/// Yumuşak sinyallerle sert filtreleri ayıran açıklama şeridi. Kullanıcı
/// hangi seçimin sonucu daralttığını bilmeli.
class _HardDivider extends StatelessWidget {
  final String text;
  const _HardDivider({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.filter_alt_rounded,
              size: 16, color: AppColors.textTertiaryFor(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiaryFor(context),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
