import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'pro_chart_gate.dart';

class HeatMapWidget extends StatefulWidget {
  final String title;
  final List<String> categories; // length: 6
  final List<double> valuesA; // length: 6 (0..5)
  final List<double> valuesB; // length: 6 (0..5)
  final String labelA;
  final String labelB;

  const HeatMapWidget({
    super.key,
    this.title = 'Kategori Isı Haritası',
    required this.categories,
    required this.valuesA,
    required this.valuesB,
    required this.labelA,
    required this.labelB,
  });

  @override
  State<HeatMapWidget> createState() => _HeatMapWidgetState();
}

class _HeatMapWidgetState extends State<HeatMapWidget> {
  int? _row; // 0:A, 1:B
  int? _col; // 0..5

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cats = widget.categories.take(6).toList();
    final a = widget.valuesA.take(6).toList();
    final b = widget.valuesB.take(6).toList();

    return ProChartGate(
      title: widget.title,
      child: _card(
        isDark: isDark,
        title: widget.title,
        child: Column(
          children: [
            _gridHeader(isDark: isDark, categories: cats),
            const SizedBox(height: 10),
            _gridRow(
              isDark: isDark,
              rowIndex: 0,
              rowLabel: widget.labelA,
              values: a,
              categories: cats,
            ),
            const SizedBox(height: 8),
            _gridRow(
              isDark: isDark,
              rowIndex: 1,
              rowLabel: widget.labelB,
              values: b,
              categories: cats,
            ),
            if (_row != null && _col != null) ...[
              const SizedBox(height: 12),
              _selectedHint(isDark, cats, a, b),
            ],
          ],
        ),
        footer: Text(
          'Hücreye dokun: puanı gör',
          style: AppTextStyles.labelSmall.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondaryFor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _gridHeader({
    required bool isDark,
    required List<String> categories,
  }) {
    return Row(
      children: [
        const SizedBox(width: 86),
        Expanded(
          child: Row(
            children: List.generate(categories.length, (i) {
              final c = categories[i];
              final short = c.length > 8 ? '${c.substring(0, 7)}…' : c;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    short,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark ? Colors.white70 : AppColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _gridRow({
    required bool isDark,
    required int rowIndex,
    required String rowLabel,
    required List<double> values,
    required List<String> categories,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 86,
          child: Text(
            rowLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: List.generate(categories.length, (colIndex) {
              final v = colIndex < values.length ? values[colIndex] : 0.0;
              final selected = _row == rowIndex && _col == colIndex;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _row = null;
                          _col = null;
                        } else {
                          _row = rowIndex;
                          _col = colIndex;
                        }
                      });
                      final cat = categories[colIndex];
                      final who = rowIndex == 0 ? widget.labelA : widget.labelB;
                      final valText = v.toStringAsFixed(2);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$who • $cat: $valText'),
                          duration: const Duration(milliseconds: 900),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _colorForValue(v).withValues(alpha: isDark ? 0.55 : 0.70),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.20)
                              : (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.06),
                          width: selected ? 1.6 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          v.toStringAsFixed(1),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _selectedHint(
    bool isDark,
    List<String> cats,
    List<double> a,
    List<double> b,
  ) {
    final r = _row!;
    final c = _col!;
    final label = r == 0 ? widget.labelA : widget.labelB;
    final cat = cats[c];
    final v = r == 0 ? (c < a.length ? a[c] : 0.0) : (c < b.length ? b[c] : 0.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label • $cat: ${v.toStringAsFixed(2)}',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySmall.copyWith(
          color: isDark ? Colors.white70 : AppColors.textSecondaryFor(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _colorForValue(double v) {
    final t = (v / 5.0).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFFE74C3C), const Color(0xFF2ECC71), t)!;
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
              color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 12),
          child,
          if (footer != null) ...[
            const SizedBox(height: 12),
            Center(child: footer),
          ],
        ],
      ),
    );
  }
}

