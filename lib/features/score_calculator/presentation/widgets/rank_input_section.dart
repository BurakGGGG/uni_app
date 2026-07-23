import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/score_input.dart';
import '../../domain/osym_score_distribution.dart';
import '../../domain/score_calculator_engine.dart';
import 'data_year_selector.dart';
import 'score_type_card.dart';

/// Sıra girişi: yıl + puan türü seçimi + başarı sırası alanı + canlı puan/dilim
/// önizlemesi. Puan ÖSYM'nin resmî yığınsal dağılım tablosunun tersinden
/// gelir, bu yüzden hep "≈" ve veri yılı etiketiyle gösterilir.
class RankInputSection extends StatelessWidget {
  final TextEditingController controller;
  final ScoreInput input;
  final ValueChanged<String> onScoreTypeChanged;
  final ValueChanged<int?> onRankChanged;
  final ValueChanged<int> onYearChanged;

  const RankInputSection({
    super.key,
    required this.controller,
    required this.input,
    required this.onScoreTypeChanged,
    required this.onRankChanged,
    required this.onYearChanged,
  });

  /// Girilebilecek en büyük sıra — en kalabalık türün aday sayısının üstü.
  static const int maxRank = 3000000;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final selected = input.scoreType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DataYearSelector(
          label: 'Hangi yılın sıralaması?',
          selected: input.selectedYear,
          onChanged: onYearChanged,
          scoreType: selected,
        ),
        const SizedBox(height: 16),
        Text(
          'Hangi türün sırası?',
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
                // Tik işareti çipi genişletip satır kaydırıyordu.
                showCheckmark: false,
                onSelected: (_) => onScoreTypeChanged(type),
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: selected == type
                      ? scoreTypeColor(type)
                      : AppColors.textSecondaryFor(context),
                  fontWeight: selected == type
                      ? FontWeight.w700
                      : FontWeight.w500,
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
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            TextInputFormatter.withFunction((oldValue, newValue) {
              final parsed = int.tryParse(newValue.text);
              if (parsed != null && parsed > maxRank) return oldValue;
              return newValue;
            }),
          ],
          style: AppTextStyles.titleMedium,
          decoration: InputDecoration(
            hintText: 'Ör: 45000',
            prefixIcon: const Icon(Icons.leaderboard_rounded, size: 20),
            suffixText: '. sıra',
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
          onChanged: (val) => onRankChanged(int.tryParse(val)),
        ),
        const SizedBox(height: 10),
        _preview(context),
      ],
    );
  }

  Widget _preview(BuildContext context) {
    if (!input.hasValidRank) {
      return Text(
        input.scoreType.isEmpty
            ? 'Önce puan türünü seç, sonra sıranı yaz.'
            : 'Başarı sıranı yaz — puanını ve dilimini hesaplayalım.',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondaryFor(context),
        ),
      );
    }

    final rank = input.enteredRank!;
    final derived = OsymScoreDistribution.estimateScore(
      rank,
      input.scoreType,
      input.selectedYear,
    );
    if (derived == null) {
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
        ? (rank / total.count * 100).clamp(0.01, 100.0)
        : null;
    final color = scoreTypeColor(input.scoreType);

    final scoreText = derived.clamped
        ? '${derived.score.toStringAsFixed(0)} puan bandı'
        : '≈ ${derived.score.toStringAsFixed(1)} puan';

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
              Icon(Icons.trending_up_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${input.scoreType} $scoreText'
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
            derived.clamped
                ? '${derived.year} verisinde bu sıra tek bir puana denk '
                      'gelmiyor — en uç değeri gösteriyoruz.'
                : '${derived.year} yerleştirme verisine göre.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}
