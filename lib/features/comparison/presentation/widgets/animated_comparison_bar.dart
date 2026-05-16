import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/comparison_result.dart';

/// Animasyonlu karşılaştırma barı — her kategori için
/// Sol (A) ve sağ (B) barlar ortadan büyüyerek animasyonla dolar.
class AnimatedComparisonBar extends StatefulWidget {
  final CategoryComparison comparison;
  final String uniAId;
  final String uniBId;
  final Duration delay;

  const AnimatedComparisonBar({
    super.key,
    required this.comparison,
    required this.uniAId,
    required this.uniBId,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedComparisonBar> createState() => _AnimatedComparisonBarState();
}

class _AnimatedComparisonBarState extends State<AnimatedComparisonBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _barAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comparison;
    final aWins = c.winnerId == widget.uniAId;
    final bWins = c.winnerId == widget.uniBId;
    final aHasData = c.valueA > 0;
    final bHasData = c.valueB > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!aHasData && !bHasData) {
      return _NoDataRow(categoryName: c.categoryName, isDark: isDark);
    }

    return AnimatedBuilder(
      animation: _barAnim,
      builder: (context, _) {
        final progress = _barAnim.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: [
              // Başlık satırı
              Row(
                children: [
                  // A puanı — Flexible ile sub-pixel taşmaları engellenir
                  Flexible(
                    child: _ScoreBadge(
                      score: c.valueA,
                      color: AppColors.primary,
                      isWinner: aWins,
                      hasData: aHasData,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          c.categoryName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
                          ),
                        ),
                        if (c.absDelta > 0.05)
                          Text(
                            '${c.absDelta.toStringAsFixed(1)} fark',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiaryFor(context),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // B puanı
                  Flexible(
                    child: _ScoreBadge(
                      score: c.valueB,
                      color: AppColors.secondary,
                      isWinner: bWins,
                      hasData: bHasData,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Çift yönlü bar
              SizedBox(
                height: 8,
                child: Row(
                  children: [
                    // A barı (sağdan sola dolar)
                    Expanded(
                      child: _DirectionalBar(
                        value: aHasData ? c.valueA : 0,
                        color: AppColors.primary,
                        isWinner: aWins,
                        progress: progress,
                        fromRight: true,
                        isDark: isDark,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 12,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppColors.border,
                    ),
                    // B barı (soldan sağa dolar)
                    Expanded(
                      child: _DirectionalBar(
                        value: bHasData ? c.valueB : 0,
                        color: AppColors.secondary,
                        isWinner: bWins,
                        progress: progress,
                        fromRight: false,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;
  final Color color;
  final bool isWinner;
  final bool hasData;

  const _ScoreBadge({
    required this.score,
    required this.color,
    required this.isWinner,
    required this.hasData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isWinner
            ? color.withValues(alpha: 0.12)
            : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: isWinner
            ? Border.all(color: color.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWinner) ...[
            Icon(Icons.check_circle_rounded, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            hasData ? score.toStringAsFixed(1) : '-',
            style: TextStyle(
              color: color,
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionalBar extends StatelessWidget {
  final double value;
  final Color color;
  final bool isWinner;
  final double progress;
  final bool fromRight;
  final bool isDark;

  const _DirectionalBar({
    required this.value,
    required this.color,
    required this.isWinner,
    required this.progress,
    required this.fromRight,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = (value / 5.0).clamp(0.0, 1.0) * progress;
    return Stack(
      children: [
        // Arka plan
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        // Dolan bar
        Align(
          alignment: fromRight ? Alignment.centerRight : Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: fromRight
                      ? [color.withValues(alpha: 0.5), color]
                      : [color, color.withValues(alpha: 0.5)],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: isWinner
                    ? [BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 6,
                      )]
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoDataRow extends StatelessWidget {
  final String categoryName;
  final bool isDark;
  const _NoDataRow({required this.categoryName, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.textTertiaryFor(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$categoryName: Henüz yeterli yorum yok',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryFor(context)),
            ),
          ),
        ],
      ),
    );
  }
}
