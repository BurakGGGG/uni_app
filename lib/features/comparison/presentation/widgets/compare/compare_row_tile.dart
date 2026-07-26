import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../domain/compare_view.dart';
import 'compare_theme.dart';

/// Tek ölçüt satırı: ortadan bölünmüş çubuk (kullanıcı kararı).
///
/// Çubuk merkezden iki yana büyür; bir bakışta hem kimin önde olduğu hem
/// farkın büyüklüğü okunur. Üç taraflı karşılaştırmada ortadan bölmek
/// anlamını yitirdiği için alt alta ince çubuklara düşer.
class CompareRowTile extends StatelessWidget {
  final CompareRow row;

  /// Girişte çubukların dolma animasyonu için gecikme.
  final Duration delay;

  const CompareRowTile({super.key, required this.row, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    final leader = row.leader;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.label,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
              if (row.hint != null)
                Text(
                  row.hint!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryFor(context),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (row.values.length == 2)
            _TwoSided(row: row, leader: leader, delay: delay)
          else
            _MultiSided(row: row, leader: leader, delay: delay),
        ],
      ),
    );
  }
}

/// İki taraf: değerler üstte karşılıklı, çubuk ortadan bölünmüş.
class _TwoSided extends StatelessWidget {
  final CompareRow row;
  final int? leader;
  final Duration delay;

  const _TwoSided({required this.row, required this.leader, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Value(
                text: row.display[0],
                color: compareSideColor(0),
                dim: row.comparable && leader != null && leader != 0,
                align: TextAlign.start,
              ),
            ),
            Expanded(
              child: _Value(
                text: row.display[1],
                color: compareSideColor(1),
                dim: row.comparable && leader != null && leader != 1,
                align: TextAlign.end,
              ),
            ),
          ],
        ),
        if (row.comparable) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  child: _HalfBar(
                    fraction: row.fraction(0),
                    color: compareSideColor(0),
                    dim: leader != null && leader != 0,
                    fromEnd: true,
                    delay: delay,
                  ),
                ),
                // Orta çizgi: gözün fark ölçtüğü referans nokta.
                Container(
                  width: 2,
                  height: 12,
                  color: AppColors.borderLightFor(context),
                ),
                Expanded(
                  child: _HalfBar(
                    fraction: row.fraction(1),
                    color: compareSideColor(1),
                    dim: leader != null && leader != 1,
                    fromEnd: false,
                    delay: delay,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Üç ve daha fazla taraf: alt alta ince çubuklar.
class _MultiSided extends StatelessWidget {
  final CompareRow row;
  final int? leader;
  final Duration delay;

  const _MultiSided({
    required this.row,
    required this.leader,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < row.values.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          Row(
            children: [
              if (row.comparable)
                Expanded(
                  child: SizedBox(
                    height: 8,
                    child: _HalfBar(
                      fraction: row.fraction(i),
                      color: compareSideColor(i),
                      dim: leader != null && leader != i,
                      fromEnd: false,
                      delay: delay,
                    ),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 10),
              SizedBox(
                width: 64,
                child: _Value(
                  text: row.display[i],
                  color: compareSideColor(i),
                  dim: row.comparable && leader != null && leader != i,
                  align: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Value extends StatelessWidget {
  final String text;
  final Color color;
  final bool dim;
  final TextAlign align;

  const _Value({
    required this.text,
    required this.color,
    required this.dim,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodyMedium.copyWith(
        fontWeight: dim ? FontWeight.w600 : FontWeight.w800,
        color: dim ? AppColors.textSecondaryFor(context) : color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _HalfBar extends StatelessWidget {
  final double fraction;
  final Color color;
  final bool dim;

  /// Sol taraf sağdan (merkezden) dolar.
  final bool fromEnd;
  final Duration delay;

  const _HalfBar({
    required this.fraction,
    required this.color,
    required this.dim,
    required this.fromEnd,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => FractionallySizedBox(
          widthFactor: value == 0 ? 0.0001 : value,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: dim ? color.withValues(alpha: 0.30) : color,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(fromEnd ? 4 : 0),
                right: Radius.circular(fromEnd ? 0 : 4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
