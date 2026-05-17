import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/department_model.dart';

enum _ChartMode { puan, siralama }

class ScoreTrendChart extends StatefulWidget {
  final DepartmentScoreData scoreData;
  const ScoreTrendChart({super.key, required this.scoreData});

  @override
  State<ScoreTrendChart> createState() => _ScoreTrendChartState();
}

class _ScoreTrendChartState extends State<ScoreTrendChart> {
  _ChartMode _mode = _ChartMode.puan;
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final allYears = widget.scoreData.allYearsAscending;
    if (allYears.length < 2) {
      return _buildEmptyState();
    }

    final isPuan = _mode == _ChartMode.puan;

    // Sıralama modunda ranking=0 olan yılları filtrele
    final years = isPuan
        ? allYears
        : allYears.where((e) => e.value.ranking > 0).toList();

    // Sıralama modunda yeterli veri yoksa boş durum göster
    if (!isPuan && years.length < 2) {
      return _buildEmptyState();
    }

    // Veri noktaları
    final spots = <FlSpot>[];
    for (var i = 0; i < years.length; i++) {
      final val = isPuan ? years[i].value.baseScore : years[i].value.ranking.toDouble();
      spots.add(FlSpot(i.toDouble(), val));
    }

    final values = spots.map((s) => s.y).toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxVal - minVal) * 0.2 + 2;

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık + Toggle
          Row(
            children: [
              Icon(
                isPuan ? Icons.show_chart_rounded : Icons.format_list_numbered_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                isPuan ? 'Taban Puan Trendi' : 'Sıralama Trendi',
                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              _buildToggle(),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minVal - padding,
                maxY: maxVal + padding,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxVal - minVal) / 3,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.borderLightFor(context),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= years.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(years[idx].key.toString(),
                              style: AppTextStyles.labelSmall),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isPuan ? 44 : 52,
                      getTitlesWidget: (value, _) {
                        final text = isPuan
                            ? value.toStringAsFixed(0)
                            : _formatRanking(value.toInt());
                        return Text(text, style: AppTextStyles.labelSmall);
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: isPuan ? AppColors.primary : AppColors.warning,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, bar, idx) {
                        final isSelected = _touchedIndex == spot.x.toInt();
                        return FlDotCirclePainter(
                          radius: isSelected ? 7 : 5,
                          color: isSelected
                              ? (isPuan ? AppColors.primary : AppColors.warning)
                              : AppColors.surface,
                          strokeWidth: 2.5,
                          strokeColor: isPuan ? AppColors.primary : AppColors.warning,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          (isPuan ? AppColors.primary : AppColors.warning).withValues(alpha: 0.2),
                          (isPuan ? AppColors.primary : AppColors.warning).withValues(alpha: 0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
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
                          // Aynı noktaya tekrar dokununca kapat
                          _touchedIndex = _touchedIndex == tappedIdx ? null : tappedIdx;
                        });
                      } else {
                        // Boş alana dokununca kapat
                        setState(() => _touchedIndex = null);
                      }
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimaryFor(context),
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    showOnTopOfTheChartBoxArea: true,
                    getTooltipItems: (spots) => spots.map((s) {
                      final idx = s.x.toInt();
                      final entry = years[idx];
                      final label = isPuan
                          ? entry.value.baseScore.toStringAsFixed(2)
                          : '${entry.value.ranking}. sıra';
                      return LineTooltipItem(
                        '${entry.key}\n$label',
                        AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((_) {
                      return TouchedSpotIndicatorData(
                        FlLine(color: Colors.transparent),
                        FlDotData(show: false),
                      );
                    }).toList();
                  },
                ),
                showingTooltipIndicators: _touchedIndex != null
                    ? [
                        ShowingTooltipIndicators([
                          LineBarSpot(
                            LineChartBarData(spots: spots),
                            0,
                            spots[_touchedIndex!],
                          ),
                        ])
                      ]
                    : [],
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton('Puan', _ChartMode.puan, enabled: true),
          _toggleButton('Sıralama', _ChartMode.siralama,
              enabled: widget.scoreData.allYearsAscending
                  .where((e) => e.value.ranking > 0)
                  .length >= 2),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, _ChartMode mode, {required bool enabled}) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: enabled
          ? () => setState(() {
                _mode = mode;
                _touchedIndex = null; // toggle'da tooltip'i sıfırla
              })
          : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: selected ? Colors.white : AppColors.textTertiaryFor(context),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  String _formatRanking(int rank) {
    if (rank >= 1000) {
      return '${(rank / 1000).toStringAsFixed(0)}B';
    }
    return rank.toString();
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.show_chart_rounded, size: 32, color: AppColors.textTertiaryFor(context)),
            const SizedBox(height: 8),
            Text('Trend verisi henüz yok',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryFor(context))),
          ],
        ),
      ),
    );
  }
}
