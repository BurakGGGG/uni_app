import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'pro_chart_gate.dart';

class ScatterPoint {
  final double x;
  final double y;
  final String label;
  const ScatterPoint({required this.x, required this.y, required this.label});
}

class ScatterPlotChart extends StatefulWidget {
  final String title;
  final List<ScatterPoint> pointsA;
  final List<ScatterPoint> pointsB;
  final String labelA;
  final String labelB;

  const ScatterPlotChart({
    super.key,
    this.title = 'Taban Puan × Sıralama',
    required this.pointsA,
    required this.pointsB,
    required this.labelA,
    required this.labelB,
  });

  @override
  State<ScatterPlotChart> createState() => _ScatterPlotChartState();
}

class _ScatterPlotChartState extends State<ScatterPlotChart> {
  String? _touchedLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final spotsA = widget.pointsA
        .map((p) => ScatterSpot(p.x, p.y,
            dotPainter: FlDotCirclePainter(
              radius: 4.2,
              color: AppColors.primary.withValues(alpha: 0.9),
              strokeWidth: 1.2,
              strokeColor: AppColors.primary,
            )))
        .toList();
    final spotsB = widget.pointsB
        .map((p) => ScatterSpot(p.x, p.y,
            dotPainter: FlDotCirclePainter(
              radius: 4.2,
              color: AppColors.secondary.withValues(alpha: 0.9),
              strokeWidth: 1.2,
              strokeColor: AppColors.secondary,
            )))
        .toList();

    final allX = [...widget.pointsA.map((e) => e.x), ...widget.pointsB.map((e) => e.x)];
    final allY = [...widget.pointsA.map((e) => e.y), ...widget.pointsB.map((e) => e.y)];

    final hasData = allX.isNotEmpty && allY.isNotEmpty;
    final minX = hasData ? allX.reduce((a, b) => a < b ? a : b) : 0;
    final maxX = hasData ? allX.reduce((a, b) => a > b ? a : b) : 1;
    final minY = hasData ? allY.reduce((a, b) => a < b ? a : b) : 0;
    final maxY = hasData ? allY.reduce((a, b) => a > b ? a : b) : 1;

    final padX = ((maxX - minX) * 0.12).clamp(1.0, 50.0);
    final padY = ((maxY - minY) * 0.12).clamp(1.0, 200.0);

    return ProChartGate(
      title: widget.title,
      child: _card(
        isDark: isDark,
        title: widget.title,
        child: SizedBox(
          height: 280,
          child: hasData
              ? ScatterChart(
                  ScatterChartData(
                    minX: minX - padX,
                    maxX: maxX + padX,
                    minY: minY - padY,
                    maxY: maxY + padY,
                    gridData: FlGridData(
                      show: true,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.08),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                      getDrawingVerticalLine: (_) => FlLine(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.06),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        axisNameWidget: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Taban puan',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          getTitlesWidget: (value, _) => Text(
                            value.toStringAsFixed(0),
                            style: AppTextStyles.labelSmall.copyWith(
                              color:
                                  isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'Sıralama',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, _) => Text(
                            _formatRank(value),
                            style: AppTextStyles.labelSmall.copyWith(
                              color:
                                  isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    scatterSpots: [...spotsA, ...spotsB],
                    scatterTouchData: ScatterTouchData(
                      enabled: true,
                      handleBuiltInTouches: false,
                      touchCallback: (event, response) {
                        if (event is FlTapUpEvent) {
                          final spot = response?.touchedSpot?.spot;
                          if (spot == null) {
                            setState(() {
                              _touchedLabel = null;
                            });
                            return;
                          }
                          final label = _lookupLabel(spot);
                          setState(() {
                            _touchedLabel = label;
                          });
                        }
                      },
                      touchTooltipData: ScatterTouchTooltipData(
                        getTooltipColor: (_) => AppColors.textPrimary,
                        getTooltipItems: (spot) {
                          final label = _lookupLabel(spot);
                          return ScatterTooltipItem(
                            '${label ?? 'Bölüm'}\n'
                            'Puan: ${spot.x.toStringAsFixed(2)}\n'
                            'Sıra: ${spot.y.toStringAsFixed(0)}',
                            textStyle: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutQuart,
                )
              : Center(
                  child: Text(
                    'Veri yok',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ),
        ),
        footer: Column(
          children: [
            _legend(isDark),
            if (_touchedLabel != null) ...[
              const SizedBox(height: 10),
              Text(
                _touchedLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatRank(double value) {
    final v = value.toInt();
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}B';
    return '$v';
  }

  String? _lookupLabel(ScatterSpot spot) {
    for (final p in widget.pointsA) {
      if ((p.x - spot.x).abs() < 0.0001 && (p.y - spot.y).abs() < 0.0001) {
        return '${widget.labelA}: ${p.label}';
      }
    }
    for (final p in widget.pointsB) {
      if ((p.x - spot.x).abs() < 0.0001 && (p.y - spot.y).abs() < 0.0001) {
        return '${widget.labelB}: ${p.label}';
      }
    }
    return null;
  }

  Widget _legend(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: AppColors.primary, label: widget.labelA, isDark: isDark),
        const SizedBox(width: 18),
        _LegendDot(
          color: AppColors.secondary,
          label: widget.labelB,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _card({
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
              color: isDark ? Colors.white : AppColors.textPrimary,
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
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

