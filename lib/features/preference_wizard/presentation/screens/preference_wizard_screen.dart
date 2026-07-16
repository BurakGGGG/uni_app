import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../domain/models/student_score_profile.dart';
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

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance
        .trackEvent(AnalyticsEvent.preferenceWizardOpened);
    // Kayıtlı profili forma önyükle.
    final existing = ref.read(studentScoreProfileProvider);
    if (existing != null) {
      _scoreType = existing.scoreType;
      _scoreCtrl.text = existing.placementScore.toStringAsFixed(2);
      if (existing.hasRank) _rankCtrl.text = existing.rank.toString();
    }
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _rankCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndSeeResults() async {
    final score =
        double.tryParse(_scoreCtrl.text.trim().replaceAll(',', '.'));
    if (_scoreType.isEmpty) {
      setState(() => _error = 'Puan türünü seç');
      return;
    }
    if (score == null || score <= 0) {
      setState(() => _error = 'Geçerli bir yerleştirme puanı gir');
      return;
    }
    final rank = int.tryParse(_rankCtrl.text.trim().replaceAll('.', ''));

    final profile = StudentScoreProfile(
      scoreType: _scoreType,
      placementScore: score,
      rank: (rank != null && rank > 0) ? rank : null,
      year: 2025,
      updatedAt: DateTime.now(),
    );
    await ref.read(studentScoreProfileProvider.notifier).save(profile);
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
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
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

              _NumberField(
                controller: _scoreCtrl,
                label: 'Yerleştirme puanın',
                hint: 'Örn. 480.5',
                allowDecimal: true,
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 14),
              _NumberField(
                controller: _rankCtrl,
                label: 'Başarı sıralaman (opsiyonel)',
                hint: 'Örn. 45000',
                allowDecimal: false,
              ),
              const SizedBox(height: 6),
              Text(
                'Sıralama girersen eşleştirme sıralama-öncelikli yapılır; boş '
                'bırakırsan yalnızca puanla eşleştirilir.',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiaryFor(context),
                  height: 1.4,
                ),
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

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
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
                  'Puanını gir, tüm alanlarda Garanti / Hedef / Riskli '
                  'programları gör ve tek dokunuşla listene ekle.',
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
