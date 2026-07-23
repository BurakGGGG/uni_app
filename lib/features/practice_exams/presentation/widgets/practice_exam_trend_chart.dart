import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../score_calculator/domain/osym_score_distribution.dart';
import '../../../score_calculator/presentation/widgets/score_type_card.dart';
import '../../domain/models/exam_target.dart';
import '../../domain/practice_exam_analytics.dart';

enum TrendMetric { score, rank, net }

/// Denemeler arası gelişim grafiği.
///
/// [ScoreTrendChart] deseninin kardeşi; tek yapısal farkı sıra ekseninin
/// **ters** olması — başarı sırasında küçük değer daha iyidir, bu yüzden
/// yukarıda durmalı.
class PracticeExamTrendChart extends StatefulWidget {
  final List<ExamTrendPoint> points;
  final String scoreType;
  final ExamTarget? target;

  /// Serinin dayandığı ÖSYM veri yılı — puan ve sıra buna göre hesaplanır.
  final int year;
  final ValueChanged<int> onYearChanged;

  const PracticeExamTrendChart({
    super.key,
    required this.points,
    required this.scoreType,
    required this.year,
    required this.onYearChanged,
    this.target,
  });

  @override
  State<PracticeExamTrendChart> createState() =>
      _PracticeExamTrendChartState();
}

class _PracticeExamTrendChartState extends State<PracticeExamTrendChart> {
  TrendMetric _metric = TrendMetric.rank;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    // Sıra serisi yoksa puana düş.
    if (_valuesFor(TrendMetric.rank).length < 2) {
      _metric = TrendMetric.score;
    }
  }

  /// Seçilen ölçüt için (nokta indeksi, değer) çiftleri.
  List<MapEntry<int, double>> _valuesFor(TrendMetric metric) {
    final result = <MapEntry<int, double>>[];
    for (var i = 0; i < widget.points.length; i++) {
      final p = widget.points[i];
      switch (metric) {
        case TrendMetric.score:
          if (p.placementScore != null) {
            result.add(MapEntry(i, p.placementScore!));
          }
          break;
        case TrendMetric.rank:
          if (p.rank != null) result.add(MapEntry(i, p.rank!.toDouble()));
          break;
        case TrendMetric.net:
          if (p.hasNets) result.add(MapEntry(i, p.totalNet));
          break;
      }
    }
    return result;
  }

  bool _available(TrendMetric metric) => _valuesFor(metric).length >= 2;

  /// Sırada küçük değer iyidir → eksen ters çevrilir (değerler negatiflenir,
  /// etiketler mutlak değerle basılır).
  bool get _inverted => _metric == TrendMetric.rank;

  Color get _color {
    switch (_metric) {
      case TrendMetric.score:
        return AppColors.primary;
      case TrendMetric.rank:
        return AppColors.warning;
      case TrendMetric.net:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final series = _valuesFor(_metric);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 18, color: _color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gelişimin${widget.scoreType.isEmpty ? '' : ' (${widget.scoreType})'}',
                  style: AppTextStyles.titleSmall
                      .copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildYearButton(context),
            ],
          ),
          const SizedBox(height: 8),
          _buildToggle(),
          _buildDataYearNote(context),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: series.length < 2
                ? _emptyState(context)
                : _buildChart(context, series),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _metric == TrendMetric.net
              ? 'Grafik için en az iki netli deneme gerekiyor.'
              : 'Grafik için en az iki deneme gerekiyor.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondaryFor(context)),
        ),
      ),
    );
  }

  Widget _buildChart(
      BuildContext context, List<MapEntry<int, double>> series) {
    final spots = [
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), _inverted ? -series[i].value : series[i].value),
    ];

    final ys = spots.map((s) => s.y).toList();
    var minY = ys.reduce((a, b) => a < b ? a : b);
    var maxY = ys.reduce((a, b) => a > b ? a : b);

    // Hedef çizgisi de eksene sığmalı, yoksa görünmez kalır.
    final targetY = _targetValue();
    if (targetY != null) {
      final plotted = _inverted ? -targetY : targetY;
      if (plotted < minY) minY = plotted;
      if (plotted > maxY) maxY = plotted;
    }
    final pad = (maxY - minY) * 0.2 + 1;

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.borderLightFor(context),
            strokeWidth: 1,
            dashArray: const [4, 4],
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
                final idx = value.toInt();
                if (idx < 0 || idx >= series.length) return const SizedBox();
                // Kalabalık listede her etiketi basmak okunmaz hâle getirir.
                final step = (series.length / 5).ceil();
                if (idx % step != 0 && idx != series.length - 1) {
                  return const SizedBox();
                }
                final point = widget.points[series[idx].key];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _shortDate(point.takenAt),
                    style: AppTextStyles.labelSmall,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                final real = _inverted ? -value : value;
                return Text(
                  _metric == TrendMetric.rank
                      ? formatRank(real.round())
                      : real.toStringAsFixed(_metric == TrendMetric.net ? 0 : 0),
                  style: AppTextStyles.labelSmall,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: targetY == null
            ? const ExtraLinesData()
            : ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: _inverted ? -targetY : targetY,
                  color: AppColors.success,
                  strokeWidth: 2,
                  dashArray: const [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.success),
                    labelResolver: (_) => 'Hedef',
                  ),
                ),
              ]),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: _color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, bar, idx) {
                final selected = _touchedIndex == spot.x.toInt();
                return FlDotCirclePainter(
                  radius: selected ? 7 : 4,
                  color: selected ? _color : AppColors.surfaceFor(context),
                  strokeWidth: 2.5,
                  strokeColor: _color,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _color.withValues(alpha: 0.2),
                  _color.withValues(alpha: 0),
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
            if (event is! FlTapUpEvent) return;
            final spot = response?.lineBarSpots?.firstOrNull;
            setState(() {
              final tapped = spot?.x.toInt();
              _touchedIndex = _touchedIndex == tapped ? null : tapped;
            });
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimaryFor(context),
            tooltipRoundedRadius: 8,
            showOnTopOfTheChartBoxArea: true,
            getTooltipItems: (touched) => touched.map((s) {
              final point = widget.points[series[s.x.toInt()].key];
              final real = _inverted ? -s.y : s.y;
              final label = switch (_metric) {
                TrendMetric.rank => '${formatRank(real.round())}. sıra',
                TrendMetric.score => '${real.toStringAsFixed(1)} puan',
                TrendMetric.net => '${real.toStringAsFixed(2)} net',
              };
              return LineTooltipItem(
                '${point.name}\n$label',
                AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          getTouchedSpotIndicator: (barData, indexes) => indexes
              .map((_) => TouchedSpotIndicatorData(
                    FlLine(color: Colors.transparent),
                    const FlDotData(show: false),
                  ))
              .toList(),
        ),
        showingTooltipIndicators: _touchedIndex != null &&
                _touchedIndex! < spots.length
            ? [
                ShowingTooltipIndicators([
                  LineBarSpot(
                    LineChartBarData(spots: spots),
                    0,
                    spots[_touchedIndex!],
                  ),
                ])
              ]
            : const [],
      ),
      duration: const Duration(milliseconds: 300),
    );
  }

  double? _targetValue() {
    final target = widget.target;
    if (target == null) return null;
    // Hedef yalnız kendi türünün grafiğinde anlamlıdır.
    if (widget.scoreType.isNotEmpty &&
        target.scoreType.toUpperCase() != widget.scoreType.toUpperCase()) {
      return null;
    }
    switch (_metric) {
      case TrendMetric.rank:
        return target.targetRank?.toDouble();
      case TrendMetric.score:
        return target.targetScore;
      case TrendMetric.net:
        return null;
    }
  }

  /// Serinin hangi yılın verisiyle çizildiği + yılı değiştirme.
  /// Net serisi yıldan bağımsızdır; orada gizlenir.
  Widget _buildYearButton(BuildContext context) {
    if (_metric == TrendMetric.net) return const SizedBox.shrink();

    return PopupMenuButton<int>(
      tooltip: 'Veri yılı',
      initialValue: widget.year,
      onSelected: widget.onYearChanged,
      itemBuilder: (_) => [
        for (final year in OsymScoreDistribution.selectableYears)
          PopupMenuItem(value: year, child: Text('$year verisi')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariantFor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLightFor(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.year}',
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryFor(context),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded,
                size: 16, color: AppColors.textTertiaryFor(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildDataYearNote(BuildContext context) {
    if (_metric == TrendMetric.net || widget.scoreType.isEmpty) {
      return const SizedBox.shrink();
    }
    final resolved =
        OsymScoreDistribution.tableYearFor(widget.scoreType, widget.year);
    if (resolved == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        resolved == widget.year
            ? 'Puan ve sıralar $resolved yerleştirme verisine göre.'
            : '${widget.year} tablosu henüz yayımlanmadı — puan ve sıralar '
                '$resolved yerleştirme verisine göre.',
        style: AppTextStyles.bodySmall
            .copyWith(color: AppColors.textTertiaryFor(context)),
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
          _toggleButton('Sıra', TrendMetric.rank),
          _toggleButton('Puan', TrendMetric.score),
          _toggleButton('Net', TrendMetric.net),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, TrendMetric metric) {
    final selected = _metric == metric;
    final enabled = _available(metric);
    return GestureDetector(
      onTap: enabled
          ? () => setState(() {
                _metric = metric;
                _touchedIndex = null;
              })
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected
                ? Colors.white
                : enabled
                    ? AppColors.textSecondaryFor(context)
                    : AppColors.textTertiaryFor(context),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static String _shortDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}';
  }
}
