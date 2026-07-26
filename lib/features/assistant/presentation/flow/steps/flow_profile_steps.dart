import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/turkish_compare.dart';
import '../../../../preference_wizard/domain/similar_programs.dart';
import '../../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../../../../preference_wizard/presentation/widgets/wizard_select_chip.dart';
import '../../../../score_calculator/presentation/providers/score_calculator_providers.dart';
import '../../../../score_calculator/presentation/widgets/department_picker_sheet.dart';
import '../../../../university/presentation/providers/university_providers.dart';
import '../../../domain/robot_mood.dart';
import '../../../domain/robot_scripts.dart';
import '../uni_flow_step_spec.dart';

// ═══════════════════════════════════════════════════════════════
//  "Sen" adımları — hedef bölüm, ilgi alanları, şehirler
//
//  İkisi de YUMUŞAK sinyal ([WizardPrefs]): sıralamada öne çeker, hiçbir
//  programı elemez. Eskiden bunlar "Üni seni tanısın" adlı ayrı bir formda
//  alt alta soruluyordu; form kalktı, sorular akışın iki adımı oldu.
// ═══════════════════════════════════════════════════════════════

/// ⑥ Aklında bir bölüm var mı?
UniFlowStepSpec targetDeptStepSpec(BuildContext context, WidgetRef ref) {
  final en = RobotScripts.isEn;
  final input = ref.watch(scoreInputProvider);
  final verdict = ref.watch(targetDepartmentVerdictProvider).valueOrNull;

  return UniFlowStepSpec(
    title: en ? 'Any department in mind?' : 'Aklında bir bölüm var mı?',
    subtitle: en
        ? 'I will tell you where you stand for it right away.'
        : 'Varsa o bölümdeki şansını hemen söyleyeyim.',
    mood: RobotMood.thinking,
    body: [
      _TargetTile(
        selected: input.selectedDepartment,
        onPick: () async {
          final dept = await DepartmentPickerSheet.show(
            context,
            // Sıra/puan modunda tür belli: yalnız o türün bölümleri.
            scoreType: input.isDirectMode ? input.scoreType : '',
          );
          if (dept == null) return;
          ref.read(scoreInputProvider.notifier).state =
              ref.read(scoreInputProvider).copyWith(selectedDepartment: dept);
        },
        onClear: () => ref.read(scoreInputProvider.notifier).state =
            ref.read(scoreInputProvider).copyWith(selectedDepartment: ''),
      ),
      if (verdict != null) ...[
        const SizedBox(height: 16),
        _VerdictLine(
          total: verdict.total,
          guaranteed: verdict.guaranteed,
          target: verdict.target,
          dream: verdict.dream,
        ),
      ],
    ],
  );
}

/// ⑦ Neye ilgin var?
UniFlowStepSpec interestsStepSpec(BuildContext context, WidgetRef ref) {
  final en = RobotScripts.isEn;
  final prefs = ref.watch(wizardPrefsProvider);

  return UniFlowStepSpec(
    title: en ? 'What interests you?' : 'Neye ilgin var?',
    subtitle: en
        ? 'Programs in these areas rank higher — nothing gets filtered out.'
        : 'Bu alanlar listede yukarı çıkar; hiçbir program elenmez.',
    mood: RobotMood.happy,
    body: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final area in interestAreas)
            WizardSelectChip(
              label: RobotScripts.interestLabel(area.key, area.label),
              selected: prefs.interestKeys.contains(area.key),
              onTap: () => _saveInterests(ref, area.key),
            ),
        ],
      ),
    ],
  );
}

/// ⑧ Hangi şehirler?
UniFlowStepSpec citiesStepSpec(BuildContext context, WidgetRef ref) {
  final en = RobotScripts.isEn;
  final prefs = ref.watch(wizardPrefsProvider);
  final citiesAsync = ref.watch(citiesProvider);

  return UniFlowStepSpec(
    title: en ? 'Which cities?' : 'Hangi şehirler?',
    subtitle: en
        ? 'Leave it empty for "anywhere".'
        : 'Boş bırakırsan "fark etmez" demektir.',
    mood: RobotMood.happy,
    body: [
      citiesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
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
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in sorted)
                WizardSelectChip(
                  label: c.name,
                  selected: prefs.cityIds.contains(c.id),
                  onTap: () => _saveCities(ref, c.id),
                ),
            ],
          );
        },
      ),
    ],
  );
}

/// Seçim ANINDA kaydedilir: akış yarıda bırakılsa da cevap kaybolmasın.
/// `copyWith` şart — form artık sormadığı yumuşak sinyalleri (üniversite
/// türü, dil) silmemeli (`PreferenceMatchEngine._prefBoostFor` onları hâlâ
/// okuyor).
void _saveInterests(WidgetRef ref, String key) {
  final prefs = ref.read(wizardPrefsProvider);
  final next = {...prefs.interestKeys};
  if (!next.remove(key)) next.add(key);
  ref.read(wizardPrefsProvider.notifier).save(prefs.copyWith(interestKeys: next));
}

void _saveCities(WidgetRef ref, String cityId) {
  final prefs = ref.read(wizardPrefsProvider);
  final next = {...prefs.cityIds};
  if (!next.remove(cityId)) next.add(cityId);
  ref.read(wizardPrefsProvider.notifier).save(prefs.copyWith(cityIds: next));
}

class _TargetTile extends StatelessWidget {
  final String selected;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _TargetTile({
    required this.selected,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final en = RobotScripts.isEn;
    final empty = selected.isEmpty;

    return Material(
      color: empty
          ? AppColors.surfaceFor(context)
          : AppColors.primary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: empty
                  ? AppColors.borderLightFor(context)
                  : AppColors.primary,
              width: empty ? 1 : 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.school_rounded,
                color: empty
                    ? AppColors.textTertiaryFor(context)
                    : AppColors.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  empty
                      ? (en ? 'Pick a department' : 'Bölüm seç')
                      : selected,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: empty
                        ? AppColors.textSecondaryFor(context)
                        : AppColors.primary,
                  ),
                ),
              ),
              if (!empty)
                IconButton(
                  tooltip: en ? 'Clear' : 'Temizle',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: onClear,
                )
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

/// "340 programdan 🟢5 · 🟡8 · 🔴12" — hedef bölümün şans dağılımı.
class _VerdictLine extends StatelessWidget {
  final int total;
  final int guaranteed;
  final int target;
  final int dream;

  const _VerdictLine({
    required this.total,
    required this.guaranteed,
    required this.target,
    required this.dream,
  });

  @override
  Widget build(BuildContext context) {
    final en = RobotScripts.isEn;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        en
            ? '$total programs · 🟢$guaranteed · 🟡$target · 🔴$dream'
            : '$total programdan 🟢$guaranteed yüksek şans · '
                '🟡$target ulaşılabilir · 🔴$dream zorlayıcı',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondaryFor(context),
          height: 1.4,
        ),
      ),
    );
  }
}
