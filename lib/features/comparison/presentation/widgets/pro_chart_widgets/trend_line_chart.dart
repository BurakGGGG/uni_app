import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import 'pro_chart_gate.dart';

class TrendLineChart extends StatefulWidget {
  final String title;
  final List<String> monthLabels; // length: 6 (örn: Oca, Şub...)
  final List<double> seriesA; // length: 6
  final List<double> seriesB; // length: 6
  final String labelA;
  final String labelB;

  const TrendLineChart({
    super.key,
    this.title = '6 Aylık Rating Trendi',
    required this.monthLabels,
    required this.seriesA,
    required this.seriesB,
    required this.labelA,
    required this.labelB,
  });

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final safeMonths = widget.monthLabels.take(6).toList();
    final a = widget.seriesA.take(6).toList();
    final b = widget.seriesB.take(6).toList();
    if (safeMonths.length < 2 || a.length < 2 || b.length < 2) {
      final loc = AppLocalizations.of(context);
      return _cardShell(
        isDark: isDark,
        title: widget.title,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(loc.trendNoData, style: AppTextStyles.bodySmall),
          ),
        ),
      );
    }

    final spotsA = List.generate(
      safeMonths.length,
      (i) => FlSpot(i.toDouble(), a[i]),
    );
    final spotsB = List.generate(
      safeMonths.length,
      (i) => FlSpot(i.toDouble(), b[i]),
    );

    final values = [...a, ...b];
    final minVal = values.reduce((x, y) => x < y ? x : y);
    final maxVal = values.reduce((x, y) => x > y ? x : y);
    final pad = ((maxVal - minVal) * 0.25 + 0.2).clamp(0.2, 2.0);

    return ProChartGate(
      title: widget.title,
      child: _cardShell(
        isDark: isDark,
        title: widget.title,
        child: SizedBox(
          height: 240,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: LineChart(
              LineChartData(
                minY: minVal - pad,
                maxY: maxVal + pad,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.08),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= safeMonths.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            safeMonths[i],
                            style: AppTextStyles.labelSmall.copyWith(
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
                      reservedSize: 40,
                      getTitlesWidget: (value, _) => Text(
                        value.toStringAsFixed(1),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? Colors.white70
                              : AppColors.textSecondaryFor(context),
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _line(
                    spots: spotsA,
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                  _line(
                    spots: spotsB,
                    color: AppColors.secondary,
                    isDark: isDark,
                  ),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: false,
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent) {
                      final spot = response?.lineBarSpots?.firstOrNull;
                      if (spot != null) {
                        final tappedIdx = spot.x.toInt();
                        setState(() {
                          _touchedIndex =
                              _touchedIndex == tappedIdx ? null : tappedIdx;
                        });
                      } else {
                        setState(() => _touchedIndex = null);
                      }
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimaryFor(context),
                    tooltipRoundedRadius: 10,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    showOnTopOfTheChartBoxArea: true,
                    getTooltipItems: (spots) {
                      if (spots.isEmpty) return const [];
                      final i = spots.first.x.toInt();
                      if (i < 0 || i >= safeMonths.length) return const [];

                      return [
                        LineTooltipItem(
                          '${safeMonths[i]}\n'
                          '${widget.labelA}: ${a[i].toStringAsFixed(2)}\n'
                          '${widget.labelB}: ${b[i].toStringAsFixed(2)}',
                          AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ];
                    },
                  ),
                ),
                showingTooltipIndicators: _touchedIndex != null
                    ? [
                        ShowingTooltipIndicators([
                          LineBarSpot(
                            LineChartBarData(spots: spotsA),
                            0,
                            spotsA[_touchedIndex!],
                          ),
                          LineBarSpot(
                            LineChartBarData(spots: spotsB),
                            0,
                            spotsB[_touchedIndex!],
                          ),
                        ])
                      ]
                    : const [],
              ),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutQuart,
            ),
          ),
        ),
        footer: _legend(isDark),
      ),
    );
  }

  LineChartBarData _line({
    required List<FlSpot> spots,
    required Color color,
    required bool isDark,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          final selected = _touchedIndex == spot.x.toInt();
          return FlDotCirclePainter(
            radius: selected ? 6.5 : 4.8,
            color: selected ? color : (isDark ? AppColors.darkSurfaceVariant : Colors.white),
            strokeWidth: 2.5,
            strokeColor: color,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _legend(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: AppColors.primary, label: widget.labelA, isDark: isDark),
        const SizedBox(width: 18),
        _LegendDot(
            color: AppColors.secondary, label: widget.labelB, isDark: isDark),
      ],
    );
  }

  Widget _cardShell({
    required bool isDark,
    required String title,
    required Widget child,
    Widget? footer,
  }) {
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
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 12),
          child,
          if (footer != null) ...[
            const SizedBox(height: 12),
            footer,
          ],
        ],
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
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white70 : AppColors.textSecondaryFor(context),
          ),
        ),
      ],
    );
  }
}

