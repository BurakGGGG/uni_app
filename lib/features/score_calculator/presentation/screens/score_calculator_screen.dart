import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';

import '../providers/score_calculator_providers.dart';
import '../widgets/department_picker_sheet.dart';
import '../widgets/subject_score_input.dart';
import '../../domain/models/score_input.dart';

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
    if (input.selectedDepartment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen hedef bölümünüzü seçin')),
      );
      return;
    }
    if (input.scoreType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen puan türünü seçin')),
      );
      return;
    }

    final obp = double.tryParse(_obpController.text) ?? 80;
    ref.read(scoreInputProvider.notifier).state = input.copyWith(obpScore: obp);
    context.push('/score-result');
  }

  @override
  Widget build(BuildContext context) {
    final input = ref.watch(scoreInputProvider);
    final scoreTypesAsync = ref.watch(departmentScoreTypesProvider);
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: CustomScrollView(
        slivers: [
          // ─── Gradient Header ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Puan Hesapla',
                style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Icon(Icons.calculate_rounded,
                          size: 160,
                          color: Colors.white.withValues(alpha: 0.07)),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              tooltip: 'Geri',
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── 1. Hedef Bölüm ──────────────────────────────
                _SectionCard(
                  icon: Icons.school_rounded,
                  iconColor: AppColors.primary,
                  title: 'Hedef Bölüm',
                  child: InkWell(
                    onTap: () async {
                      final dept = await DepartmentPickerSheet.show(context);
                      if (dept != null) {
                        ref.read(scoreInputProvider.notifier).state =
                            input.copyWith(
                              selectedDepartment: dept,
                              scoreType: '', // Reset, otomatik belirlenecek
                            );
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: input.selectedDepartment.isNotEmpty
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : AppColors.borderLightFor(context),
                          width: input.selectedDepartment.isNotEmpty ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            input.selectedDepartment.isNotEmpty
                                ? Icons.check_circle_rounded
                                : Icons.search_rounded,
                            color: input.selectedDepartment.isNotEmpty
                                ? AppColors.primary
                                : AppColors.textTertiaryFor(context),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              input.selectedDepartment.isEmpty
                                  ? 'Bölüm ara ve seç…'
                                  : input.selectedDepartment,
                              style: input.selectedDepartment.isEmpty
                                  ? AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textTertiaryFor(context))
                                  : AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: AppColors.textTertiaryFor(context)),
                        ],
                      ),
                    ),
                  ),
                ),

                // Puan türü otomatik chip (bölüm seçildiyse)
                if (input.selectedDepartment.isNotEmpty)
                  scoreTypesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (types) {
                      if (types.isEmpty) return const SizedBox.shrink();
                      if (types.length == 1) {
                        // Tek tip — bilgilendirme
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded,
                                    color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Puan türü otomatik belirlendi: ${types.first}',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      // Birden fazla tip — kullanıcı seçmeli
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bu bölüm birden fazla puan türüyle alınabilir:',
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondaryFor(context)),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: types.map((type) {
                                final isSelected = input.scoreType == type;
                                return ChoiceChip(
                                  label: Text(type,
                                      style: AppTextStyles.labelLarge.copyWith(
                                          color: isSelected ? Colors.white : null)),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary,
                                  showCheckmark: false,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  onSelected: (selected) {
                                    if (selected) {
                                      ref.read(scoreInputProvider.notifier).state =
                                          input.copyWith(scoreType: type);
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 16),

                // ─── 2. Yıl Seçimi ──────────────────────────────
                _SectionCard(
                  icon: Icons.calendar_today_rounded,
                  iconColor: AppColors.accent,
                  title: 'Yıl Seçimi',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [2022, 2023, 2024, 2025].map((year) {
                          final isSelected = input.selectedYear == year;
                          return ChoiceChip(
                            label: Text(year.toString(),
                                style: AppTextStyles.labelLarge.copyWith(
                                    color: isSelected ? Colors.white : null)),
                            selected: isSelected,
                            selectedColor: AppColors.accent,
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onSelected: (selected) {
                              if (selected) {
                                ref.read(scoreInputProvider.notifier).state =
                                    input.copyWith(selectedYear: year);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      // 2025 uyarısı
                      if (input.selectedYear == 2025)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.warning.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    color: AppColors.warning, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '2025 yılı için sıralama verisi henüz mevcut değil. '
                                    'Sonuçlarda sıralama bilgisi gösterilmeyecektir.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.warning,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── 3. OBP ──────────────────────────────────────
                _SectionCard(
                  icon: Icons.workspace_premium_rounded,
                  iconColor: AppColors.gold,
                  title: 'Diploma Notu (OBP)',
                  child: TextFormField(
                    controller: _obpController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final text = newValue.text.replaceAll(',', '.');
                        if (text.isNotEmpty &&
                            !RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
                          return oldValue;
                        }
                        final parsed = double.tryParse(text);
                        if (parsed != null && parsed > 100) {
                          return const TextEditingValue(
                            text: '100',
                            selection: TextSelection.collapsed(offset: 3),
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
                      suffixStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiaryFor(context)),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: AppColors.borderLightFor(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ─── 4. Net Girişi ───────────────────────────────
                if (input.scoreType.isNotEmpty) ...[
                  _buildSectionHeader('TYT Testleri'),
                  SubjectScoreInput(
                    title: 'Türkçe', maxQuestions: 40,
                    correct: input.tytTurkceCorrect, wrong: input.tytTurkceWrong,
                    onCorrectChanged: (v) => _update(input.copyWith(tytTurkceCorrect: v)),
                    onWrongChanged: (v) => _update(input.copyWith(tytTurkceWrong: v)),
                  ),
                  SubjectScoreInput(
                    title: 'Sosyal Bilimler', maxQuestions: 20,
                    correct: input.tytSosyalCorrect, wrong: input.tytSosyalWrong,
                    onCorrectChanged: (v) => _update(input.copyWith(tytSosyalCorrect: v)),
                    onWrongChanged: (v) => _update(input.copyWith(tytSosyalWrong: v)),
                  ),
                  SubjectScoreInput(
                    title: 'Temel Matematik', maxQuestions: 40,
                    correct: input.tytMatCorrect, wrong: input.tytMatWrong,
                    onCorrectChanged: (v) => _update(input.copyWith(tytMatCorrect: v)),
                    onWrongChanged: (v) => _update(input.copyWith(tytMatWrong: v)),
                  ),
                  SubjectScoreInput(
                    title: 'Fen Bilimleri', maxQuestions: 20,
                    correct: input.tytFenCorrect, wrong: input.tytFenWrong,
                    onCorrectChanged: (v) => _update(input.copyWith(tytFenCorrect: v)),
                    onWrongChanged: (v) => _update(input.copyWith(tytFenWrong: v)),
                  ),

                  // AYT SAY
                  if (input.scoreType == 'SAY') ...[
                    _buildSectionHeader('AYT Sayısal'),
                    SubjectScoreInput(title: 'Matematik', maxQuestions: 40,
                      correct: input.aytMatCorrect, wrong: input.aytMatWrong,
                      onCorrectChanged: (v) => _update(input.copyWith(aytMatCorrect: v)),
                      onWrongChanged: (v) => _update(input.copyWith(aytMatWrong: v))),
                    SubjectScoreInput(title: 'Fizik', maxQuestions: 14,
                      correct: input.aytFizikCorrect, wrong: input.aytFizikWrong,
                      onCorrectChanged: (v) => _update(input.copyWith(aytFizikCorrect: v)),
                      onWrongChanged: (v) => _update(input.copyWith(aytFizikWrong: v))),
                    SubjectScoreInput(title: 'Kimya', maxQuestions: 13,
                      correct: input.aytKimyaCorrect, wrong: input.aytKimyaWrong,
                      onCorrectChanged: (v) => _update(input.copyWith(aytKimyaCorrect: v)),
                      onWrongChanged: (v) => _update(input.copyWith(aytKimyaWrong: v))),
                    SubjectScoreInput(title: 'Biyoloji', maxQuestions: 13,
                      correct: input.aytBiyoCorrect, wrong: input.aytBiyoWrong,
                      onCorrectChanged: (v) => _update(input.copyWith(aytBiyoCorrect: v)),
                      onWrongChanged: (v) => _update(input.copyWith(aytBiyoWrong: v))),
                  ],

                  // AYT EA
                  if (input.scoreType == 'EA') ...[
                    _buildSectionHeader('AYT Eşit Ağırlık'),
                    SubjectScoreInput(title: 'Matematik', maxQuestions: 40,
                      correct: input.aytMatCorrect, wrong: input.aytMatWrong,
                      onCorrectChanged: (v) => _update(input.copyWith(aytMatCorrect: v)),
                      onWrongChanged: (v) => _update(input.copyWith(aytMatWrong: v))),
                    SubjectScoreInput(title: 'Türk Dili ve Edebiyatı', maxQuestions: 24,
                      correct: input.aytEdebiyatCorrect, wrong: input.aytEdebiyatWrong,
                      onCorrectChanged: (v) => _update(input.copyWith(aytEdebiyatCorrect: v)),
                      onWrongChanged: (v) => _update(input.copyWith(aytEdebiyatWrong: v))),
                    SubjectScoreInput(title: 'Tarih-1', maxQuestions: 10,
                      correct: input.aytTarih1Correct, wrong: input.aytTarih1Wrong,
                      onCorrectChanged: (v) => _update(input.copyWith(aytTarih1Correct: v)),
                      onWrongChanged: (v) => _update(input.copyWith(aytTarih1Wrong: v))),
                    SubjectScoreInput(title: 'Coğrafya-1', maxQuestions: 6,
                      correct: input.aytCografya1Correct, wrong: input.aytCografya1Wrong,
                      onCorrectChanged: (v) => _update(input.copyWith(aytCografya1Correct: v)),
                      onWrongChanged: (v) => _update(input.copyWith(aytCografya1Wrong: v))),
                  ],

                  // AYT SÖZ
                  if (input.scoreType == 'SÖZ') ...[
                    _buildSectionHeader('AYT Sözel'),
                    SubjectScoreInput(title: 'Türk Dili ve Edebiyatı', maxQuestions: 24,
                      correct: input.aytEdebiyatCorrect, wrong: input.aytEdebiyatWrong,
                      onCorrectChanged: (v) => _update(input.copyWith(aytEdebiyatCorrect: v)),
                      onWrongChanged: (v) => _update(input.copyWith(aytEdebiyatWrong: v))),
                    SubjectScoreInput(title: 'Tarih-1', maxQuestions: 10,
                      correct: input.aytTarih1Correct, wrong: input.aytTarih1Wrong,
                      onCorrectChanged: (v) => _update(input.copyWith(aytTarih1Correct: v)),
                      onWrongChanged: (v) => _update(input.copyWith(aytTarih1Wrong: v))),
                    SubjectScoreInput(title: 'Coğrafya-1', maxQuestions: 6,
                      correct: input.aytCografya1Correct, wrong: input.aytCografya1Wrong,
                      onCorrectChanged: (v) => _update(input.copyWith(aytCografya1Correct: v)),
                      onWrongChanged: (v) => _update(input.copyWith(aytCografya1Wrong: v))),
                    SubjectScoreInput(title: 'Tarih-2', maxQuestions: 11,
                      correct: input.aytTarih2Correct, wrong: input.aytTarih2Wrong,
                      onCorrectChanged: (v) => _update(input.copyWith(aytTarih2Correct: v)),
                      onWrongChanged: (v) => _update(input.copyWith(aytTarih2Wrong: v))),
                    SubjectScoreInput(title: 'Coğrafya-2', maxQuestions: 11,
                      correct: input.aytCografya2Correct, wrong: input.aytCografya2Wrong,
                      onCorrectChanged: (v) => _update(input.copyWith(aytCografya2Correct: v)),
                      onWrongChanged: (v) => _update(input.copyWith(aytCografya2Wrong: v))),
                    SubjectScoreInput(title: 'Felsefe Grubu', maxQuestions: 12,
                      correct: input.aytFelsefeCorrect, wrong: input.aytFelsefeWrong,
                      onCorrectChanged: (v) => _update(input.copyWith(aytFelsefeCorrect: v)),
                      onWrongChanged: (v) => _update(input.copyWith(aytFelsefeWrong: v))),
                    SubjectScoreInput(title: 'DKAB', maxQuestions: 6,
                      correct: input.aytDkabCorrect, wrong: input.aytDkabWrong,
                      onCorrectChanged: (v) => _update(input.copyWith(aytDkabCorrect: v)),
                      onWrongChanged: (v) => _update(input.copyWith(aytDkabWrong: v))),
                  ],

                  // DİL
                  if (input.scoreType == 'DİL') ...[
                    _buildSectionHeader('Yabancı Dil Testi'),
                    SubjectScoreInput(title: 'Yabancı Dil', maxQuestions: 80,
                      correct: input.ydtCorrect, wrong: input.ydtWrong,
                      onCorrectChanged: (v) => _update(input.copyWith(ydtCorrect: v)),
                      onWrongChanged: (v) => _update(input.copyWith(ydtWrong: v))),
                  ],

                  const SizedBox(height: 32),
                  GradientButton(
                    text: 'Hesapla',
                    icon: Icons.calculate_rounded,
                    onPressed: _calculate,
                  ),
                  const SizedBox(height: 64),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _update(ScoreInput newInput) {
    ref.read(scoreInputProvider.notifier).state = newInput;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
      child: Row(
        children: [
          Container(
            width: 4, height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimaryFor(context), fontWeight: FontWeight.w700,
          )),
        ],
      ),
    );
  }
}

// ─── Section Card ───────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
