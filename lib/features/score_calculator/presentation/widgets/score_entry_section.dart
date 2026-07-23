import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/score_input.dart';
import '../../domain/osym_score_distribution.dart';
import '../../domain/score_calculator_engine.dart';
import 'data_year_selector.dart';
import 'score_type_card.dart';

/// Puan girişi: yıl + puan türü seçimi + yerleştirme puanı alanı + canlı
/// sıra/dilim önizlemesi. [RankInputSection]'ın aynadaki eşi — orada sıra
/// girilip puan türetilir, burada puan girilip sıra tahmin edilir.
class ScoreEntrySection extends StatelessWidget {
  final TextEditingController controller;
  final ScoreInput input;
  final ValueChanged<String> onScoreTypeChanged;
  final ValueChanged<double?> onScoreChanged;
  final ValueChanged<int> onYearChanged;

  const ScoreEntrySection({
    super.key,
    required this.controller,
    required this.input,
    required this.onScoreTypeChanged,
    required this.onScoreChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final selected = input.scoreType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DataYearSelector(
          label: 'Hangi yılın puanı?',
          selected: input.selectedYear,
          onChanged: onYearChanged,
          scoreType: selected,
        ),
        const SizedBox(height: 16),
        Text(
          'Hangi türün puanı?',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in ScoreCalculatorEngine.allScoreTypes)
              ChoiceChip(
                label: Text(type),
                selected: selected == type,
                showCheckmark: false,
                onSelected: (_) => onScoreTypeChanged(type),
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: selected == type
                      ? scoreTypeColor(type)
                      : AppColors.textSecondaryFor(context),
                  fontWeight:
                      selected == type ? FontWeight.w700 : FontWeight.w500,
                ),
                selectedColor: scoreTypeColor(type).withValues(alpha: 0.12),
                side: BorderSide(
                  color: selected == type
                      ? scoreTypeColor(type).withValues(alpha: 0.45)
                      : AppColors.borderLightFor(context),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              if (newValue.text.isEmpty) return newValue;
              final parsed = _parse(newValue.text);
              if (parsed == null) return oldValue;
              if (parsed > ScoreInput.maxEnterableScore) return oldValue;
              return newValue;
            }),
          ],
          style: AppTextStyles.titleMedium,
          decoration: InputDecoration(
            hintText: 'Ör: 451,1',
            prefixIcon:
                const Icon(Icons.workspace_premium_rounded, size: 20),
            suffixText: 'puan',
            suffixStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiaryFor(context),
            ),
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
              borderSide: BorderSide(color: AppColors.borderLightFor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: (val) => onScoreChanged(_parse(val)),
        ),
        const SizedBox(height: 10),
        _preview(context),
      ],
    );
  }

  /// Türkçe klavyede ondalık ayracı virgül gelir.
  static double? _parse(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  Widget _preview(BuildContext context) {
    if (!input.hasValidScore) {
      final entered = input.enteredScore;
      final tooLow =
          entered != null && entered < ScoreInput.minEnterableScore;
      return Text(
        input.scoreType.isEmpty
            ? 'Önce puan türünü seç, sonra yerleştirme puanını yaz.'
            : tooLow
                ? 'Yerleştirme puanı en az '
                    '${ScoreInput.minEnterableScore.toStringAsFixed(0)} olabilir.'
                : 'Yerleştirme puanını yaz — sıranı ve dilimini hesaplayalım.',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondaryFor(context),
        ),
      );
    }

    final score = input.enteredScore!;
    final estimate = OsymScoreDistribution.estimateRank(
      score,
      input.scoreType,
      input.selectedYear,
    );
    if (estimate == null) {
      return Text(
        'Bu tür için resmî dağılım verisi yok.',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondaryFor(context),
        ),
      );
    }

    final total = OsymScoreDistribution.totalCandidates(
      input.scoreType,
      input.selectedYear,
    );
    final percentile = (total != null && total.count > 0)
        ? (estimate.rank / total.count * 100).clamp(0.01, 100.0)
        : null;
    final color = scoreTypeColor(input.scoreType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${input.scoreType} ≈ ${formatRank(estimate.rank)}. sıra'
                  '${percentile != null ? ' · ${formatPercentile(percentile)}' : ''}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${estimate.year} yerleştirme verisine göre.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}
