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
            Text('1. Yıl Seçimi', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [2022, 2023, 2024, 2025].map((year) {
                final isSelected = input.selectedYear == year;
                return ChoiceChip(
                  label: Text(year.toString()),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(scoreInputProvider.notifier).state = 
                          input.copyWith(selectedYear: year);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Puan Türü Seçimi
            Text('2. Puan Türü', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['TYT', 'SAY', 'EA', 'SÖZ', 'DİL'].map((type) {
                final isSelected = input.scoreType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
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
            const SizedBox(height: 24),

            // Bölüm Seçimi
            Text('3. Hedef Bölüm', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            InkWell(
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
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLightFor(context)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      input.selectedDepartment.isEmpty 
                          ? 'Bölüm ara...' 
                          : input.selectedDepartment,
                      style: input.selectedDepartment.isEmpty
                          ? AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiaryFor(context))
                          : AppTextStyles.bodyLarge,
                    ),
                    Icon(Icons.search_rounded, color: AppColors.textTertiaryFor(context)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // OBP
            Text('4. Diploma Notu (OBP)', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
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
              decoration: InputDecoration(
                hintText: 'Ör: 85.5',
                suffixText: '/ 100',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 32),

            // Net Girişi
            if (input.scoreType.isNotEmpty) ...[
              Text('5. Net Girişi', style: AppTextStyles.titleLarge),
              const SizedBox(height: 16),

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
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
      ),
    );
  }
}
