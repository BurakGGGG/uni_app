import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/comparison_result.dart';

/// 6 kategorili radar chart — iki üniversiteyi yarı-şeffaf alanlarla gösterir.
class ComparisonRadarChart extends StatefulWidget {
  final ComparisonResult result;
  const ComparisonRadarChart({super.key, required this.result});

  @override
  State<ComparisonRadarChart> createState() => _ComparisonRadarChartState();
}

class _ComparisonRadarChartState extends State<ComparisonRadarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _morph;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _morph = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final cats = result.categoryComparisons.values.toList();
    if (cats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: AnimatedBuilder(
              animation: _morph,
              builder: (context, _) {
                final t = _morph.value;
                final morphEntries = cats.map((c) {
                  final value = c.valueA + (c.valueB - c.valueA) * t;
                  return RadarEntry(value: value);
                }).toList();
                return RadarChart(
                  RadarChartData(
                    dataSets: [
                      RadarDataSet(
                        dataEntries:
                            cats.map((c) => RadarEntry(value: c.valueA)).toList(),
                        borderColor: AppColors.primary,
                        fillColor: AppColors.primary.withValues(alpha: 0.14),
                        borderWidth: 1.8,
                        entryRadius: 2.5,
                      ),
                      RadarDataSet(
                        dataEntries:
                            cats.map((c) => RadarEntry(value: c.valueB)).toList(),
                        borderColor: AppColors.secondary,
                        fillColor: AppColors.secondary.withValues(alpha: 0.14),
                        borderWidth: 1.8,
                        entryRadius: 2.5,
                      ),
                      RadarDataSet(
                        dataEntries: morphEntries,
                        borderColor: Color.lerp(
                            AppColors.primary, AppColors.secondary, t)!,
                        fillColor: Color.lerp(
                                AppColors.primary.withValues(alpha: 0.22),
                                AppColors.secondary.withValues(alpha: 0.22),
                                t)!
                            .withValues(alpha: 0.18),
                        borderWidth: 2.4,
                        entryRadius: 3.2,
                      ),
                    ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData:
                    const BorderSide(color: AppColors.borderLight, width: 1),
                gridBorderData:
                    const BorderSide(color: AppColors.borderLight, width: 0.5),
                tickCount: 4,
                ticksTextStyle: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 9,
                ),
                tickBorderData:
                    const BorderSide(color: AppColors.borderLight, width: 0.5),
                getTitle: (index, angle) {
                  final name = cats[index].categoryName;
                  // Uzun isimleri kısalt
                  final short =
                      name.length > 10 ? '${name.substring(0, 9)}…' : name;
                  return RadarChartTitle(
                    text: short,
                    angle: angle,
                    positionPercentageOffset: 0.15,
                  );
                },
                titleTextStyle: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                titlePositionPercentageOffset: 0.2,
                  ),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutQuart,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                  color: AppColors.primary,
                  label: result.uniA.name.split(' ').first),
              const SizedBox(width: 24),
              _LegendDot(
                  color: AppColors.secondary,
                  label: result.uniB.name.split(' ').first),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
