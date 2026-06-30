import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';

class CityComparPieChart extends StatelessWidget {
  final int stateCount;
  final int foundationCount;

  const CityComparPieChart({
    super.key,
    required this.stateCount,
    required this.foundationCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = stateCount + foundationCount;
    final loc = AppLocalizations.of(context);
    if (total <= 0) {
      return Center(
        child: Text(loc.comparisonNoData, style: AppTextStyles.bodySmall),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 110,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 24,
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(
                  color: AppColors.info,
                  value: stateCount.toDouble(),
                  title: '$stateCount',
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  radius: 32,
                ),
                PieChartSectionData(
                  color: AppColors.tierPlus,
                  value: foundationCount.toDouble(),
                  title: '$foundationCount',
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  radius: 32,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            _LegendDot(label: loc.universityTypeState, value: stateCount, color: AppColors.info),
            _LegendDot(
              label: loc.universityTypeFoundation,
              value: foundationCount,
              color: AppColors.tierPlus,
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _LegendDot({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label • $value',
            style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

