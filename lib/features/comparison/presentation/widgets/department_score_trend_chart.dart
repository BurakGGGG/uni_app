import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../university/domain/models/department_model.dart';

/// İki bölümün 2022–2025 puan trendini karşılaştıran çizgi grafik.
class DepartmentScoreTrendChart extends StatefulWidget {
  final DepartmentModel deptA;
  final DepartmentModel deptB;
  final String labelA;
  final String labelB;

  const DepartmentScoreTrendChart({
    super.key,
    required this.deptA,
    required this.deptB,
    required this.labelA,
    required this.labelB,
  });

  @override
  State<DepartmentScoreTrendChart> createState() =>
      _DepartmentScoreTrendChartState();
}

class _DepartmentScoreTrendChartState extends State<DepartmentScoreTrendChart> {
  int? _touchedIndex;

  /// scoreData'dan yıl bazlı puanları çıkar (2022, 2023, 2024, 2025)
  List<MapEntry<int, double>> _getYearlyScores(DepartmentModel dept) {
    final scores = <int, double>{};
    final sd = dept.scoreData;
    if (sd != null) {
      // Geçmiş yıllar
      for (final entry in sd.previousYears.entries) {
        if (entry.value.baseScore > 0) {
          scores[entry.key] = entry.value.baseScore;
        }
      }
      // Güncel yıl
      if (sd.baseScore > 0) {
        scores[sd.year] = sd.baseScore;
      }
    }
    // scoreData yoksa legacy alanlardan
    if (scores.isEmpty && (dept.baseScore ?? 0) > 0) {
      scores[2025] = dept.baseScore!;
    }
    final sorted = scores.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final yearsA = _getYearlyScores(widget.deptA);
    final yearsB = _getYearlyScores(widget.deptB);

    // Ortak yıllar
    final allYearSet = <int>{};
    for (final e in yearsA) {
      allYearSet.add(e.key);
    }
    for (final e in yearsB) {
      allYearSet.add(e.key);
    }
    final allYears = allYearSet.toList()..sort();

    if (allYears.length < 2) {
      return _buildEmpty(isDark);
    }

    final mapA = {for (final e in yearsA) e.key: e.value};
    final mapB = {for (final e in yearsB) e.key: e.value};

    final spotsA = <FlSpot>[];
    final spotsB = <FlSpot>[];
    for (var i = 0; i < allYears.length; i++) {
      final year = allYears[i];
      if (mapA.containsKey(year)) {
        spotsA.add(FlSpot(i.toDouble(), mapA[year]!));
      }
      if (mapB.containsKey(year)) {
        spotsB.add(FlSpot(i.toDouble(), mapB[year]!));
      }
    }

    final allVals = [...spotsA.map((s) => s.y), ...spotsB.map((s) => s.y)];
    final minVal = allVals.reduce((a, b) => a < b ? a : b);
    final maxVal = allVals.reduce((a, b) => a > b ? a : b);
    final pad = ((maxVal - minVal) * 0.20 + 5).clamp(5.0, 40.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.18),
                      AppColors.secondary.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Puan Trendi',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? Colors.white
                        : AppColors.textPrimaryFor(context),
                  ),
                ),
              ),
              // Yıl aralığı badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${allYears.first}–${allYears.last}',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minVal - pad,
                maxY: maxVal + pad,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.06,
                    ),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= allYears.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            allYears[i].toString(),
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondaryFor(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toStringAsFixed(0),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark
                                ? Colors.white54
                                : AppColors.textTertiaryFor(context),
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _buildLine(spotsA, AppColors.primary, isDark),
                  _buildLine(spotsB, AppColors.secondary, isDark),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: false,
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent) {
                      final spot = response?.lineBarSpots?.firstOrNull;
                      if (spot != null) {
                        final idx = spot.x.toInt();
                        setState(() {
                          _touchedIndex = _touchedIndex == idx ? null : idx;
                        });
                      } else {
                        setState(() => _touchedIndex = null);
                      }
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFF1A1A2E),
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    showOnTopOfTheChartBoxArea: true,
                    getTooltipItems: (spots) {
                      if (spots.isEmpty || _touchedIndex == null) {
                        return const [];
                      }
                      final i = _touchedIndex!;
                      if (i < 0 || i >= allYears.length) return const [];

                      final year = allYears[i];
                      final valA = mapA[year];
                      final valB = mapB[year];

                      return [
                        LineTooltipItem(
                          '$year\n'
                          '${widget.labelA}: ${valA?.toStringAsFixed(2) ?? "-"}\n'
                          '${widget.labelB}: ${valB?.toStringAsFixed(2) ?? "-"}',
                          AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                      ];
                    },
                  ),
                ),
                showingTooltipIndicators:
                    _touchedIndex != null && _touchedIndex! < spotsA.length
                    ? [
                        ShowingTooltipIndicators([
                          LineBarSpot(
                            LineChartBarData(spots: spotsA),
                            0,
                            spotsA[_touchedIndex!.clamp(
                              0,
                              spotsA.length - 1,
                            )],
                          ),
                        ]),
                      ]
                    : const [],
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutQuart,
            ),
          ),
          const SizedBox(height: 14),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                color: AppColors.primary,
                label: widget.labelA,
                isDark: isDark,
              ),
              const SizedBox(width: 20),
              _LegendDot(
                color: AppColors.secondary,
                label: widget.labelB,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color, bool isDark) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          final selected = _touchedIndex == spot.x.toInt();
          return FlDotCirclePainter(
            radius: selected ? 7 : 4.5,
            color: selected
                ? color
                : (isDark ? AppColors.darkSurface : Colors.white),
            strokeWidth: 2.5,
            strokeColor: color,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 32,
              color: AppColors.textTertiaryFor(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Trend verisi henüz yok',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiaryFor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;
  const _LegendDot({
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark
                ? Colors.white70
                : AppColors.textSecondaryFor(context),
          ),
        ),
      ],
    );
  }
}
