import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/comparison_result.dart';

class ComparisonCategoryRow extends StatelessWidget {
  final CategoryComparison comparison;
  final String uniAId;
  final String uniBId;

  const ComparisonCategoryRow({
    super.key,
    required this.comparison,
    required this.uniAId,
    required this.uniBId,
  });

  @override
  Widget build(BuildContext context) {
    final aWins = comparison.winnerId == uniAId;
    final bWins = comparison.winnerId == uniBId;
    final aHasData = comparison.valueA > 0;
    final bHasData = comparison.valueB > 0;

    // Her iki taraf da boş
    if (!aHasData && !bHasData) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariantFor(context),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        child: Row(children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.textTertiaryFor(context)),
          const SizedBox(width: 8),
          Text('${comparison.categoryName}: Henüz yeterli yorum yok',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryFor(context))),
        ]),
      );
    }

    if (comparison.valueA == 0 && comparison.valueB == 0) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariantFor(context),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        child: Row(children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.textTertiaryFor(context)),
          const SizedBox(width: 8),
          Text('${comparison.categoryName}: Henüz yeterli yorum yok',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryFor(context))),
        ]),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comparison.categoryName,
                style: AppTextStyles.titleSmall,
              ),
              const Spacer(),
              if (comparison.absDelta > 0.05)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${comparison.absDelta.toStringAsFixed(1)} fark',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: aHasData
                    ? _Bar(
                        value: comparison.valueA,
                        color: AppColors.primary,
                        isWinner: aWins,
                        alignment: TextAlign.right,
                      )
                    : _NoDataLabel(alignment: TextAlign.right),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: bHasData
                    ? _Bar(
                        value: comparison.valueB,
                        color: AppColors.secondary,
                        isWinner: bWins,
                        alignment: TextAlign.left,
                      )
                    : _NoDataLabel(alignment: TextAlign.left),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  final Color color;
  final bool isWinner;
  final TextAlign alignment;

  const _Bar({
    required this.value,
    required this.color,
    required this.isWinner,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final widthFraction = (value / 5.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: alignment == TextAlign.right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: alignment == TextAlign.right
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (isWinner) ...[
              Icon(Icons.check_circle_rounded, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              value > 0 ? value.toStringAsFixed(1) : '-',
              style: AppTextStyles.labelMedium.copyWith(
                color: color,
                fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantFor(context),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Align(
              alignment: alignment == TextAlign.right
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutQuart,
                height: 6,
                width: MediaQuery.of(context).size.width * 0.4 * widthFraction,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NoDataLabel extends StatelessWidget {
  final TextAlign alignment;
  const _NoDataLabel({required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment == TextAlign.right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          'Yorum yok',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariantFor(context),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}
