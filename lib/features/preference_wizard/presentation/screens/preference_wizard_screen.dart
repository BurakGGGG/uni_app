import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/turkish_compare.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../domain/models/student_score_profile.dart';
import '../../domain/models/wizard_prefs.dart';
import '../../domain/similar_programs.dart';
import '../providers/preference_wizard_providers.dart';

/// Tercih Robotu giriş ekranı — hızlı puan/sıralama girişi veya netlerden
/// hesaplama köprüsü. Profil kayıtlıysa özet + "önerileri gör" gösterir.
class PreferenceWizardScreen extends ConsumerStatefulWidget {
  const PreferenceWizardScreen({super.key});

  @override
  ConsumerState<PreferenceWizardScreen> createState() =>
      _PreferenceWizardScreenState();
}

class _PreferenceWizardScreenState
    extends ConsumerState<PreferenceWizardScreen> {
  static const _scoreTypes = ['SAY', 'EA', 'SÖZ', 'DİL', 'TYT'];

  final _scoreCtrl = TextEditingController();
  final _rankCtrl = TextEditingController();
  String _scoreType = '';
  String? _error;
  late WizardPrefs _prefs;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance
        .trackEvent(AnalyticsEvent.preferenceWizardOpened);
    // Kayıtlı profili ve tercihleri forma önyükle.
    final existing = ref.read(studentScoreProfileProvider);
    if (existing != null) {
      _scoreType = existing.scoreType;
      if (existing.hasScore) {
        _scoreCtrl.text = existing.placementScore.toStringAsFixed(2);
      }
      if (existing.hasRank) _rankCtrl.text = existing.rank.toString();
    }
    _prefs = ref.read(wizardPrefsProvider);
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _rankCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndSeeResults() async {
    final scoreText = _scoreCtrl.text.trim();
    final score = double.tryParse(scoreText.replaceAll(',', '.'));
    final rank = int.tryParse(_rankCtrl.text.trim().replaceAll('.', ''));
    final hasRank = rank != null && rank > 0;

    if (_scoreType.isEmpty) {
      setState(() => _error = 'Puan türünü seç');
      return;
    }
    if (scoreText.isNotEmpty && (score == null || score <= 0)) {
      setState(() => _error = 'Geçerli bir yerleştirme puanı gir');
      return;
    }
    if ((score == null || score <= 0) && !hasRank) {
      setState(() => _error = 'Puan veya sıralamadan en az birini gir');
      return;
    }

    final profile = StudentScoreProfile(
      scoreType: _scoreType,
      placementScore: (score != null && score > 0) ? score : 0,
      rank: hasRank ? rank : null,
      year: DateTime.now().year,
      updatedAt: DateTime.now(),
    );
    await ref.read(studentScoreProfileProvider.notifier).save(profile);
    await ref.read(wizardPrefsProvider.notifier).save(_prefs);
    if (!mounted) return;
    context.push('/preference-wizard/results');
  }

  @override
  Widget build(BuildContext context) {
    final hasProfile = ref.watch(studentScoreProfileProvider) != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundFor(context),
        elevation: 0,
        title: const Text('Tercih Robotu'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(),
              const SizedBox(height: 20),

              // Puan türü
              Text(
                'Puan türün',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in _scoreTypes)
                    ChoiceChip(
                      label: Text(t),
                      selected: _scoreType == t,
                      onSelected: (_) => setState(() {
                        _scoreType = t;
                        _error = null;
                      }),
                      backgroundColor: AppColors.surfaceVariantFor(context),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      side: BorderSide(
                        color: _scoreType == t
                            ? AppColors.primary
                            : AppColors.borderLightFor(context),
                      ),
                      labelStyle: TextStyle(
                        color: _scoreType == t
                            ? AppColors.primary
                            : AppColors.textPrimaryFor(context),
                        fontWeight: _scoreType == t
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // Sıralama birincil alan: en isabetli eşleştirme gerçek sırayla
              // yapılır; puan girilirse sıra tahmin edilir.
              _NumberField(
                controller: _rankCtrl,
                label: 'Başarı sıralaman (önerilen)',
                hint: 'Örn. 45000',
                allowDecimal: false,
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 14),
              _NumberField(
                controller: _scoreCtrl,
                label: 'Yerleştirme puanın (opsiyonel)',
                hint: 'Örn. 480.5',
                allowDecimal: true,
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 6),
              Text(
                'Birini girmen yeterli. En isabetli eşleştirme gerçek '
                'sıralamanla yapılır; yalnız puan girersen sıran tahmin '
                'edilir.',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiaryFor(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              _PrefsSection(
                prefs: _prefs,
                onChanged: (p) => setState(() => _prefs = p),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _error!,
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.error),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saveAndSeeResults,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(hasProfile
                      ? 'Güncelle ve önerileri gör'
                      : 'Önerileri gör'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    textStyle: AppTextStyles.titleSmall
                        .copyWith(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => context.push('/score-calculator'),
                  icon: const Icon(Icons.calculate_rounded, size: 18),
                  label: const Text('Puanımı bilmiyorum, netlerden hesapla'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opsiyonel "Tercihlerin" bölümü — şehir / üniversite tipi / ilgi alanı.
/// Yumuşak sinyaldir: sonuçları ELEMEZ, uygunluk sıralamasında öne çeker
/// (sert filtreler Plus'taki filtre sheet'inde kalır). Atlanabilir.
class _PrefsSection extends ConsumerWidget {
  final WizardPrefs prefs;
  final ValueChanged<WizardPrefs> onChanged;
  const _PrefsSection({required this.prefs, required this.onChanged});

  static Set<String> _toggle(Set<String> set, String value) {
    final next = {...set};
    if (!next.add(value)) next.remove(value);
    return next;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(citiesProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: const Icon(Icons.tune_rounded,
              size: 20, color: AppColors.primary),
          title: Row(
            children: [
              Text(
                'Tercihlerin',
                style: AppTextStyles.titleSmall
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Text(
                prefs.isEmpty ? '(opsiyonel)' : '(${prefs.activeCount} seçim)',
                style: AppTextStyles.labelSmall.copyWith(
                  color: prefs.isEmpty
                      ? AppColors.textTertiaryFor(context)
                      : AppColors.primary,
                ),
              ),
            ],
          ),
          subtitle: Text(
            'Şehir ve ilgi alanı seçersen uygun programlar öne gelir — '
            'hiçbir sonuç elenmez.',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiaryFor(context),
              height: 1.3,
            ),
          ),
          children: [
            _PrefLabel('Üniversite tipi'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in const ['Devlet', 'Vakıf'])
                  _PrefChip(
                    label: t,
                    selected: prefs.uniTypes.contains(t),
                    onTap: () => onChanged(
                      prefs.copyWith(uniTypes: _toggle(prefs.uniTypes, t)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _PrefLabel('İlgi alanların'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final area in interestAreas)
                  _PrefChip(
                    label: area.label,
                    selected: prefs.interestKeys.contains(area.key),
                    onTap: () => onChanged(
                      prefs.copyWith(
                        interestKeys: _toggle(prefs.interestKeys, area.key),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _PrefLabel('Şehirler'),
            citiesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (cities) {
                final sorted = [...cities]
                  ..sort((a, b) => turkishCompare(a.name, b.name));
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in sorted)
                      _PrefChip(
                        label: c.name,
                        selected: prefs.cityIds.contains(c.id),
                        onTap: () => onChanged(
                          prefs.copyWith(
                            cityIds: _toggle(prefs.cityIds, c.id),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PrefLabel extends StatelessWidget {
  final String text;
  const _PrefLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondaryFor(context),
          ),
        ),
      ),
    );
  }
}

class _PrefChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PrefChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.borderLightFor(context),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected
                ? AppColors.primary
                : AppColors.textPrimaryFor(context),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradientFor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puanına uygun tercihleri bul',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Puanını gir, sana uygun programları şans durumuna göre '
                  'gruplu gör ve tek dokunuşla listene ekle.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool allowDecimal;
  final ValueChanged<String>? onChanged;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.allowDecimal,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              allowDecimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
            ),
          ],
          onChanged: onChanged,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor:
                AppColors.surfaceVariantFor(context).withValues(alpha: 0.7),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderLightFor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
