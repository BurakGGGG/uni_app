import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/comparison_result.dart';

class ComparisonStatsTable extends StatelessWidget {
  final ComparisonResult result;

  const ComparisonStatsTable({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _StatRow(
        label: 'Tür',
        valueA: result.uniA.type,
        valueB: result.uniB.type,
      ),
      _StatRow(
        label: 'Kuruluş',
        valueA: result.uniA.establishedYear.toString(),
        valueB: result.uniB.establishedYear.toString(),
      ),
      _StatRow(
        label: 'Yerleşim',
        valueA: result.uniA.campusLayout.label,
        valueB: result.uniB.campusLayout.label,
      ),
      _StatRow(
        label: 'Yorum Sayısı',
        valueA: result.uniA.reviewCount.toString(),
        valueB: result.uniB.reviewCount.toString(),
      ),
      _StatRow(
        label: 'Mekan Sayısı',
        valueA: result.placeCountA.toString(),
        valueB: result.placeCountB.toString(),
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final r = rows[i];
          final isLast = i == rows.length - 1;
          return Container(
            decoration: BoxDecoration(
              border: !isLast
                  ? const Border(
                      bottom: BorderSide(color: AppColors.borderLight))
                  : null,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      r.valueA,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      r.valueB,
                      textAlign: TextAlign.left,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StatRow {
  final String label;
  final String valueA;
  final String valueB;
  const _StatRow(
      {required this.label, required this.valueA, required this.valueB});
}
