import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import '../providers/score_calculator_providers.dart';
import '../widgets/department_picker_sheet.dart';
import '../widgets/subject_score_input.dart';

class ScoreCalculatorScreen extends ConsumerStatefulWidget {
  const ScoreCalculatorScreen({super.key});

  @override
  ConsumerState<ScoreCalculatorScreen> createState() => _ScoreCalculatorScreenState();
}

class _ScoreCalculatorScreenState extends ConsumerState<ScoreCalculatorScreen> {
  final _obpController = TextEditingController(text: '80');
  
  @override
  void dispose() {
    _obpController.dispose();
    super.dispose();
  }

  void _calculate() {
    final input = ref.read(scoreInputProvider);
    if (input.scoreType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir puan türü seçin')),
      );
      return;
    }
    if (input.selectedDepartment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen hedef bölümünüzü seçin')),
      );
      return;
    }
    
    // OBP güncelle
    final obp = double.tryParse(_obpController.text) ?? 80;
    ref.read(scoreInputProvider.notifier).state = input.copyWith(obpScore: obp);

    context.push('/score-result');
  }

  @override
  Widget build(BuildContext context) {
    final input = ref.watch(scoreInputProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        title: const Text('Puan Hesapla'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Yıl Seçimi
            _buildSectionCard(
              context,
              title: 'Yıl Seçimi',
              icon: Icons.calendar_today_rounded,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [2022, 2023, 2024, 2025].map((year) {
                  final isSelected = input.selectedYear == year;
                  return ChoiceChip(
                    label: Text(year.toString(), style: AppTextStyles.labelLarge.copyWith(color: isSelected ? Colors.white : null)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(scoreInputProvider.notifier).state = 
                            input.copyWith(selectedYear: year);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Puan Türü Seçimi
            _buildSectionCard(
              context,
              title: 'Puan Türü',
              icon: Icons.category_rounded,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['TYT', 'SAY', 'EA', 'SÖZ', 'DİL'].map((type) {
                  final isSelected = input.scoreType == type;
                  return ChoiceChip(
                    label: Text(type, style: AppTextStyles.labelLarge.copyWith(color: isSelected ? Colors.white : null)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(scoreInputProvider.notifier).state = 
                            input.copyWith(
                              scoreType: type,
                              selectedDepartment: '', // Puan türü değiştiğinde bölümü temizle
                            );
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Bölüm Seçimi
            _buildSectionCard(
              context,
              title: 'Hedef Bölüm',
              icon: Icons.school_rounded,
              child: InkWell(
                onTap: () async {
                  if (input.scoreType.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Önce puan türünü seçmelisiniz')),
                    );
                    return;
                  }
                  final dept = await DepartmentPickerSheet.show(context);
                  if (dept != null) {
                    ref.read(scoreInputProvider.notifier).state = 
                        input.copyWith(selectedDepartment: dept);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundFor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLightFor(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          input.selectedDepartment.isEmpty 
                              ? 'Bölüm ara...' 
                              : input.selectedDepartment,
                          style: input.selectedDepartment.isEmpty
                              ? AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiaryFor(context))
                              : AppTextStyles.bodyLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.search_rounded, color: AppColors.textTertiaryFor(context)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // OBP
            _buildSectionCard(
              context,
              title: 'Diploma Notu (OBP)',
              icon: Icons.workspace_premium_rounded,
              child: TextFormField(
                controller: _obpController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    // Virgülü noktaya çevir
                    final text = newValue.text.replaceAll(',', '.');
                    // Sadece sayı ve noktaya izin ver
                    if (text.isNotEmpty && !RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
                      return oldValue;
                    }
                    // 100'den büyük olamaz
                    final parsed = double.tryParse(text);
                    if (parsed != null && parsed > 100) {
                      return TextEditingValue(
                        text: '100',
                        selection: const TextSelection.collapsed(offset: 3),
                      );
                    }
                    return TextEditingValue(
                      text: text,
                      selection: newValue.selection,
                    );
                  }),
                ],
                style: AppTextStyles.titleMedium,
                decoration: InputDecoration(
                  hintText: 'Ör: 85.5',
                  suffixText: '/ 100',
                  suffixStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiaryFor(context)),
                  filled: true,
                  fillColor: AppColors.backgroundFor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.borderLightFor(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.borderLightFor(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Net Girişi
            if (input.scoreType.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 16),
                child: Text('Net Girişi', style: AppTextStyles.headlineSmall),
              ),

              // TYT Ortak
              _buildSectionHeader('TYT Testleri'),
              SubjectScoreInput(
                title: 'Türkçe',
                maxQuestions: 40,
                correct: input.tytTurkceCorrect,
                wrong: input.tytTurkceWrong,
                onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(tytTurkceCorrect: v),
                onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(tytTurkceWrong: v),
              ),
              SubjectScoreInput(
                title: 'Sosyal Bilimler',
                maxQuestions: 20,
                correct: input.tytSosyalCorrect,
                wrong: input.tytSosyalWrong,
                onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(tytSosyalCorrect: v),
                onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(tytSosyalWrong: v),
              ),
              SubjectScoreInput(
                title: 'Temel Matematik',
                maxQuestions: 40,
                correct: input.tytMatCorrect,
                wrong: input.tytMatWrong,
                onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(tytMatCorrect: v),
                onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(tytMatWrong: v),
              ),
              SubjectScoreInput(
                title: 'Fen Bilimleri',
                maxQuestions: 20,
                correct: input.tytFenCorrect,
                wrong: input.tytFenWrong,
                onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(tytFenCorrect: v),
                onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(tytFenWrong: v),
              ),

              // AYT SAY
              if (input.scoreType == 'SAY') ...[
                _buildSectionHeader('AYT Sayısal'),
                SubjectScoreInput(
                  title: 'Matematik',
                  maxQuestions: 40,
                  correct: input.aytMatCorrect,
                  wrong: input.aytMatWrong,
                  onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytMatCorrect: v),
                  onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytMatWrong: v),
                ),
                SubjectScoreInput(
                  title: 'Fizik',
                  maxQuestions: 14,
                  correct: input.aytFizikCorrect,
                  wrong: input.aytFizikWrong,
                  onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytFizikCorrect: v),
                  onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytFizikWrong: v),
                ),
                SubjectScoreInput(
                  title: 'Kimya',
                  maxQuestions: 13,
                  correct: input.aytKimyaCorrect,
                  wrong: input.aytKimyaWrong,
                  onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytKimyaCorrect: v),
                  onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytKimyaWrong: v),
                ),
                SubjectScoreInput(
                  title: 'Biyoloji',
                  maxQuestions: 13,
                  correct: input.aytBiyoCorrect,
                  wrong: input.aytBiyoWrong,
                  onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytBiyoCorrect: v),
                  onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytBiyoWrong: v),
                ),
              ],

              // AYT EA
              if (input.scoreType == 'EA') ...[
                _buildSectionHeader('AYT Eşit Ağırlık'),
                SubjectScoreInput(
                  title: 'Matematik',
                  maxQuestions: 40,
                  correct: input.aytMatCorrect,
                  wrong: input.aytMatWrong,
                  onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytMatCorrect: v),
                  onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytMatWrong: v),
                ),
                SubjectScoreInput(
                  title: 'Türk Dili ve Edebiyatı',
                  maxQuestions: 24,
                  correct: input.aytEdebiyatCorrect,
                  wrong: input.aytEdebiyatWrong,
                  onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytEdebiyatCorrect: v),
                  onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytEdebiyatWrong: v),
                ),
                SubjectScoreInput(
                  title: 'Tarih-1',
                  maxQuestions: 10,
                  correct: input.aytTarih1Correct,
                  wrong: input.aytTarih1Wrong,
                  onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytTarih1Correct: v),
                  onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytTarih1Wrong: v),
                ),
                SubjectScoreInput(
                  title: 'Coğrafya-1',
                  maxQuestions: 6,
                  correct: input.aytCografya1Correct,
                  wrong: input.aytCografya1Wrong,
                  onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytCografya1Correct: v),
                  onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytCografya1Wrong: v),
                ),
              ],

              // AYT SÖZ
              if (input.scoreType == 'SÖZ') ...[
                _buildSectionHeader('AYT Sözel'),
                SubjectScoreInput(
                  title: 'Türk Dili ve Edebiyatı',
                  maxQuestions: 24,
                  correct: input.aytEdebiyatCorrect,
                  wrong: input.aytEdebiyatWrong,
                  onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytEdebiyatCorrect: v),
                  onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytEdebiyatWrong: v),
                ),
                SubjectScoreInput(
                  title: 'Tarih-1',
                  maxQuestions: 10,
                  correct: input.aytTarih1Correct,
                  wrong: input.aytTarih1Wrong,
                  onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytTarih1Correct: v),
                  onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytTarih1Wrong: v),
                ),
                SubjectScoreInput(
                  title: 'Coğrafya-1',
                  maxQuestions: 6,
                  correct: input.aytCografya1Correct,
                  wrong: input.aytCografya1Wrong,
                  onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytCografya1Correct: v),
                  onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytCografya1Wrong: v),
                ),
                SubjectScoreInput(
                  title: 'Tarih-2',
                  maxQuestions: 11,
                  correct: input.aytTarih2Correct,
                  wrong: input.aytTarih2Wrong,
                  onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytTarih2Correct: v),
                  onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytTarih2Wrong: v),
                ),
                SubjectScoreInput(
                  title: 'Coğrafya-2',
                  maxQuestions: 11,
                  correct: input.aytCografya2Correct,
                  wrong: input.aytCografya2Wrong,
                  onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytCografya2Correct: v),
                  onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytCografya2Wrong: v),
                ),
                SubjectScoreInput(
                  title: 'Felsefe Grubu',
                  maxQuestions: 12,
                  correct: input.aytFelsefeCorrect,
                  wrong: input.aytFelsefeWrong,
                  onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytFelsefeCorrect: v),
                  onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytFelsefeWrong: v),
                ),
                SubjectScoreInput(
                  title: 'DKAB',
                  maxQuestions: 6,
                  correct: input.aytDkabCorrect,
                  wrong: input.aytDkabWrong,
                  onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytDkabCorrect: v),
                  onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(aytDkabWrong: v),
                ),
              ],

              // DİL
              if (input.scoreType == 'DİL') ...[
                _buildSectionHeader('Yabancı Dil Testi'),
                SubjectScoreInput(
                  title: 'Yabancı Dil',
                  maxQuestions: 80,
                  correct: input.ydtCorrect,
                  wrong: input.ydtWrong,
                  onCorrectChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(ydtCorrect: v),
                  onWrongChanged: (v) => ref.read(scoreInputProvider.notifier).state = input.copyWith(ydtWrong: v),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate_rounded),
                  label: const Text('Hesapla'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 64),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: AppColors.softShadowFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
