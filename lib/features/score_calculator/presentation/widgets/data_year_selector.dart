import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/osym_score_distribution.dart';

/// "Hangi yılın sırası/puanı?" — girilen değerin hangi yılın ÖSYM verisiyle
/// yorumlanacağını seçtirir.
///
/// Sıra ve puan yıldan yıla aynı şeyi ifade etmez: 2022'de 45.000. sıra ile
/// 2025'te 45.000. sıra farklı puanlara denk gelir. Bu yüzden yıl, girilen
/// değerin ayrılmaz parçasıdır.
class DataYearSelector extends StatelessWidget {
  final String label;
  final int selected;
  final ValueChanged<int> onChanged;

  /// Seçilen yılın tablosu yoksa hangi yıla düşüldüğünü söyleyen alt satır.
  /// Tür seçilmemişse (boş) not basılmaz.
  final String scoreType;

  const DataYearSelector({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.scoreType = '',
  });

  @override
  Widget build(BuildContext context) {
    final resolved = scoreType.isEmpty
        ? null
        : OsymScoreDistribution.tableYearFor(scoreType, selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final year in OsymScoreDistribution.selectableYears)
              ChoiceChip(
                label: Text('$year'),
                selected: selected == year,
                showCheckmark: false,
                onSelected: (_) => onChanged(year),
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: selected == year
                      ? AppColors.primary
                      : AppColors.textSecondaryFor(context),
                  fontWeight:
                      selected == year ? FontWeight.w700 : FontWeight.w500,
                ),
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                side: BorderSide(
                  color: selected == year
                      ? AppColors.primary.withValues(alpha: 0.45)
                      : AppColors.borderLightFor(context),
                ),
              ),
          ],
        ),
        if (resolved != null && resolved != selected) ...[
          const SizedBox(height: 6),
          Text(
            '$selected tablosu henüz yayımlanmadı — hesap $resolved '
            'yerleştirme verisiyle yapılıyor.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiaryFor(context),
            ),
          ),
        ],
      ],
    );
  }
}
