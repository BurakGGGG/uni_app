import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import 'pro_chart_gate.dart';

/// Kategori karşılaştırma ısı haritası.
///
/// Her kategori bir satır; iki üniversitenin değeri renkli hücrelerde yan yana.
/// Satır bazında daha yüksek değer (kazanan) vurgulanır. Bu yerleşim, kategori
/// adlarına tam genişlik verdiği için 6 sütuna sıkıştırılmış eski tabloya göre
/// çok daha okunaklı.
class HeatMapWidget extends StatelessWidget {
  final String title;
  final List<String> categories; // length: 6
  final List<double> valuesA; // length: 6 (0..5)
  final List<double> valuesB; // length: 6 (0..5)
  final String labelA;
  final String labelB;

  const HeatMapWidget({
    super.key,
    required this.title,
    required this.categories,
    required this.valuesA,
    required this.valuesB,
    required this.labelA,
    required this.labelB,
  });

  static const double _cellWidth = 58;
  static const double _cellGap = 8;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final cats = categories.take(6).toList();
    final a = valuesA.take(6).toList();
    final b = valuesB.take(6).toList();

    return ProChartGate(
      title: title,
      child: _card(
        context: context,
        isDark: isDark,
        title: title,
        child: Column(
          children: [
            _columnHeaders(context, isDark),
            const SizedBox(height: 8),
            for (var i = 0; i < cats.length; i++) ...[
              _categoryRow(
                context: context,
                isDark: isDark,
                category: cats[i],
                valueA: i < a.length ? a[i] : 0,
                valueB: i < b.length ? b[i] : 0,
              ),
              if (i != cats.length - 1) const SizedBox(height: 8),
            ],
            const SizedBox(height: 14),
            _scaleLegend(context, isDark, loc),
          ],
        ),
      ),
    );
  }

  // ─── Sütun başlıkları (üniversite kısa adları + renk noktaları) ──────
  Widget _columnHeaders(BuildContext context, bool isDark) {
    return Row(
      children: [
        const Expanded(child: SizedBox.shrink()),
        _headerCell(context, isDark, labelA, AppColors.primary),
        const SizedBox(width: _cellGap),
        _headerCell(context, isDark, labelB, AppColors.secondary),
      ],
    );
  }

  Widget _headerCell(
    BuildContext context,
    bool isDark,
    String label,
    Color color,
  ) {
    final short = _shortName(label);
    return SizedBox(
      width: _cellWidth,
      child: Column(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 4),
          Text(
            short,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : AppColors.textSecondaryFor(context),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Kategori satırı (ad + iki değer hücresi) ────────────────────────
  Widget _categoryRow({
    required BuildContext context,
    required bool isDark,
    required String category,
    required double valueA,
    required double valueB,
  }) {
    final aWins = valueA > valueB + 0.001;
    final bWins = valueB > valueA + 0.001;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              category,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
              ),
            ),
          ),
        ),
        _valueCell(isDark, valueA, isWinner: aWins),
        const SizedBox(width: _cellGap),
        _valueCell(isDark, valueB, isWinner: bWins),
      ],
    );
  }

  Widget _valueCell(bool isDark, double v, {required bool isWinner}) {
    final base = _colorForValue(v);
    return Container(
      width: _cellWidth,
      height: 42,
      decoration: BoxDecoration(
        color: base.withValues(alpha: isDark ? 0.55 : 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner
              ? Colors.white.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.0),
          width: isWinner ? 2 : 0,
        ),
        boxShadow: isWinner
            ? [
                BoxShadow(
                  color: base.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          v.toStringAsFixed(1),
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // ─── Renk skalası açıklaması (düşük → yüksek) ────────────────────────
  Widget _scaleLegend(
    BuildContext context,
    bool isDark,
    AppLocalizations loc,
  ) {
    final labelStyle = AppTextStyles.labelSmall.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: isDark ? Colors.white70 : AppColors.textSecondaryFor(context),
    );
    return Row(
      children: [
        Text(loc.chartScaleLow, style: labelStyle),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [Color(0xFFE74C3C), Color(0xFFF1C40F), Color(0xFF2ECC71)],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(loc.chartScaleHigh, style: labelStyle),
      ],
    );
  }

  Color _colorForValue(double v) {
    final t = (v / 5.0).clamp(0.0, 1.0);
    // Kırmızı → sarı → yeşil (iki kademeli lerp, daha okunaklı orta ton).
    if (t < 0.5) {
      return Color.lerp(
          const Color(0xFFE74C3C), const Color(0xFFF1C40F), t / 0.5)!;
    }
    return Color.lerp(
        const Color(0xFFF1C40F), const Color(0xFF2ECC71), (t - 0.5) / 0.5)!;
  }

  String _shortName(String name) {
    final trimmed = name.trim();
    if (trimmed.length <= 10) return trimmed;
    final first = trimmed.split(' ').first;
    return first.length <= 12 ? first : '${first.substring(0, 11)}…';
  }

  Widget _card({
    required BuildContext context,
    required bool isDark,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
