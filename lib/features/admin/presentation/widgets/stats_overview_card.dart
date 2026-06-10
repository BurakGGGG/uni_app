import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// İstatistik ekranı üstünde gösterilen dönem özeti kartı.
class StatsOverviewCard extends StatelessWidget {
  final String periodLabel;
  final int userCount;
  final String userLabel;
  final int loginCount;
  final int reviewCount;
  final int comparisonCount;

  const StatsOverviewCard({
    super.key,
    required this.periodLabel,
    required this.userCount,
    required this.userLabel,
    required this.loginCount,
    required this.reviewCount,
    required this.comparisonCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dönem Özeti',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      periodLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  label: userLabel,
                  value: userCount,
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _OverviewMetric(
                  label: 'Giriş',
                  value: loginCount,
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _OverviewMetric(
                  label: 'Yorum',
                  value: reviewCount,
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _OverviewMetric(
                  label: 'Karşılaştırma',
                  value: comparisonCount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String label;
  final int value;

  const _OverviewMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _formatNumber(value),
          style: AppTextStyles.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n < 1000) return n.toString();
    if (n < 1000000) {
      final k = n / 1000;
      return k >= 10 ? '${k.toStringAsFixed(0)}K' : '${k.toStringAsFixed(1)}K';
    }
    final m = n / 1000000;
    return m >= 10 ? '${m.toStringAsFixed(0)}M' : '${m.toStringAsFixed(1)}M';
  }
}
