import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/admin_stats_model.dart';

/// Son 7 günün yeni kullanıcı trend grafiği.
class StatsTrendChart extends StatelessWidget {
  final List<DailyTrendPoint> points;
  final PeriodComparisonModel? comparison;

  const StatsTrendChart({
    super.key,
    required this.points,
    this.comparison,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = points.isEmpty
        ? 10.0
        : points.map((p) => p.newUsers).reduce((a, b) => a > b ? a : b).toDouble();
    final chartMaxY = (maxY < 5 ? 5.0 : maxY * 1.2).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFF3B82F6),
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '7 Günlük Trend',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
          if (comparison != null) ...[
            const SizedBox(height: 10),
            _PeriodChangeRow(comparison: comparison!),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: points.every((p) => p.newUsers == 0)
                ? Center(
                    child: Text(
                      'Henüz yeterli günlük veri yok',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiaryFor(context),
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: chartMaxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: chartMaxY / 4,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.borderLightFor(context),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.max || value == 0) {
                                return Text(
                                  value.toInt().toString(),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontSize: 9,
                                    color: AppColors.textTertiaryFor(context),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= points.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  points[index].label,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontSize: 9,
                                    color: AppColors.textTertiaryFor(context),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(points.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: points[i].newUsers.toDouble(),
                              color: const Color(0xFF3B82F6),
                              width: 14,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChangeRow extends StatelessWidget {
  final PeriodComparisonModel comparison;

  const _PeriodChangeRow({required this.comparison});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ChangeChip(
          label: 'Yeni kayıt',
          changePercent: comparison.newUsersChangePercent,
          thisValue: comparison.thisPeriodNewUsers,
          lastValue: comparison.lastPeriodNewUsers,
        ),
        const SizedBox(width: 8),
        _ChangeChip(
          label: 'Giriş',
          changePercent: comparison.loginsChangePercent,
          thisValue: comparison.thisPeriodLogins,
          lastValue: comparison.lastPeriodLogins,
        ),
      ],
    );
  }
}

class _ChangeChip extends StatelessWidget {
  final String label;
  final double changePercent;
  final int thisValue;
  final int lastValue;

  const _ChangeChip({
    required this.label,
    required this.changePercent,
    required this.thisValue,
    required this.lastValue,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = changePercent >= 0;
    final color = isUp ? AppColors.success : AppColors.error;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 10,
                color: AppColors.textTertiaryFor(context),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(0)}%',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            Text(
              '$thisValue / $lastValue',
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 9,
                color: AppColors.textTertiaryFor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
