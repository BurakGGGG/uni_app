import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/comparison_result.dart';
import '../providers/comparison_providers.dart';
import '../widgets/comparison_radar_chart.dart';
import '../widgets/pro_chart_widgets/heat_map_widget.dart';
import '../widgets/pro_chart_widgets/scatter_plot_chart.dart';
import '../widgets/pro_chart_widgets/trend_line_chart.dart';

/// Karşılaştırma grafikleri — kendi ekranında (kullanıcı kararı).
///
/// Eskiden sonuç ekranının 5 sekmesinden biriydi. Ana akış sadeleşsin diye
/// dışarı alındı: grafik isteyen tek dokunuşla geliyor, istemeyen hiç
/// görmüyor. Pro kilidi de tek yerde toplanıyor.
///
/// Sonucu parametre olarak ALMIYOR: seçim zaten `comparisonSelectionProvider`
/// içinde; parametre geçseydi derin bağlantıyla açılan ekran boş kalırdı.
class ComparisonChartsScreen extends ConsumerWidget {
  const ComparisonChartsScreen({super.key});

  static const _monthAbbr = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final resultAsync = ref.watch(comparisonResultProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          loc.cmpChartsTitle,
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: resultAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text(loc.errorGeneral(e.toString()))),
        data: (result) {
          if (result == null || result.categoryComparisons.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 16,
                ),
                child: EmptyStateWidget(
                  illustration: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      size: 32,
                      color: AppColors.secondary,
                    ),
                  ),
                  title: loc.comparisonChartEmptyTitle,
                  description: loc.comparisonChartEmptyDesc,
                ),
              ),
            );
          }
          return _Charts(result: result);
        },
      ),
    );
  }
}

class _Charts extends ConsumerWidget {
  final ComparisonResult result;
  const _Charts({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final pair = ComparisonPair(idA: result.uniA.id, idB: result.uniB.id);
    final labelA = result.uniA.name;
    final labelB = result.uniB.name;
    final cats = result.categoryComparisons.values.toList();

    final trendState = ref.watch(ratingTrendProvider(pair)).valueOrNull;
    final scatter = ref.watch(departmentScatterProvider(pair)).valueOrNull;

    const hPad = EdgeInsets.symmetric(horizontal: 16);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
      child: Column(
        children: [
          ComparisonRadarChart(result: result)
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
          const SizedBox(height: 16),
          Padding(
            padding: hPad,
            child: HeatMapWidget(
              title: loc.chartHeatmapTitle,
              categories: cats.map((c) => c.categoryName).toList(),
              valuesA: cats.map((c) => c.valueA).toList(),
              valuesB: cats.map((c) => c.valueB).toList(),
              labelA: labelA,
              labelB: labelB,
            ),
          ).animate().fadeIn(delay: 90.ms, duration: 350.ms),
          const SizedBox(height: 16),
          Padding(
            padding: hPad,
            child: TrendLineChart(
              title: loc.chartTrendTitle,
              monthLabels: _trendLabels(trendState),
              seriesA: _trendSeries(trendState, (p) => p.avgRatingA),
              seriesB: _trendSeries(trendState, (p) => p.avgRatingB),
              labelA: labelA,
              labelB: labelB,
            ),
          ).animate().fadeIn(delay: 180.ms, duration: 350.ms),
          const SizedBox(height: 16),
          Padding(
            padding: hPad,
            child: ScatterPlotChart(
              title: loc.chartScatterTitle,
              pointsA: _scatterPoints(scatter?.pointsA),
              pointsB: _scatterPoints(scatter?.pointsB),
              labelA: labelA,
              labelB: labelB,
            ),
          ).animate().fadeIn(delay: 270.ms, duration: 350.ms),
        ],
      ),
    );
  }

  List<String> _trendLabels(TrendDataState? s) => s is TrendDataSuccess
      ? s.points
          .map((p) =>
              ComparisonChartsScreen._monthAbbr[(p.month.month - 1) % 12])
          .toList()
      : const [];

  List<double> _trendSeries(
    TrendDataState? s,
    double Function(RatingTrendPoint) sel,
  ) =>
      s is TrendDataSuccess ? s.points.map(sel).toList() : const [];

  List<ScatterPoint> _scatterPoints(List<DepartmentScatterPoint>? pts) =>
      pts == null
          ? const []
          : pts
              .map((p) => ScatterPoint(
                    x: p.baseScore,
                    y: p.ranking.toDouble(),
                    label: p.departmentName,
                  ))
              .toList();
}
