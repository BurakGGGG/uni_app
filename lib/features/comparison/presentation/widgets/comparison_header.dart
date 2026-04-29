import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/comparison_result.dart';

class ComparisonHeader extends StatelessWidget {
  final ComparisonResult result;

  const ComparisonHeader({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.secondary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _ScoreCard(
                score: result.uniA.avgRating,
                label: result.uniA.name,
                isWinner: result.overallWinnerId == result.uniA.id,
                color: AppColors.primary,
              )),
              const SizedBox(width: 12),
              _Delta(delta: result.overallScoreDelta),
              const SizedBox(width: 12),
              Expanded(child: _ScoreCard(
                score: result.uniB.avgRating,
                label: result.uniB.name,
                isWinner: result.overallWinnerId == result.uniB.id,
                color: AppColors.secondary,
              )),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            result.summaryText,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniStat(
                label: 'A önde',
                value: result.categoriesAWins.toString(),
                color: AppColors.primary,
              ),
              _MiniStat(
                label: 'Berabere',
                value: result.categoriesTied.toString(),
                color: AppColors.textTertiary,
              ),
              _MiniStat(
                label: 'B önde',
                value: result.categoriesBWins.toString(),
                color: AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final double score;
  final String label;
  final bool isWinner;
  final Color color;

  const _ScoreCard({
    required this.score,
    required this.label,
    required this.isWinner,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: isWinner ? color : AppColors.borderLight,
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isWinner)
            Icon(Icons.emoji_events_rounded, size: 18, color: color),
          if (isWinner) const SizedBox(height: 4),
          Text(
            score > 0 ? score.toStringAsFixed(1) : '-',
            style: AppTextStyles.headlineLarge.copyWith(
              color: color, fontWeight: FontWeight.w800, fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Delta extends StatelessWidget {
  final double delta;
  const _Delta({required this.delta});

  @override
  Widget build(BuildContext context) {
    final absDelta = delta.abs();
    final color = delta > 0.05
        ? AppColors.primary
        : (delta < -0.05 ? AppColors.secondary : AppColors.textTertiary);
    final text = absDelta < 0.05
        ? '='
        : (delta > 0
            ? '◀ ${absDelta.toStringAsFixed(1)}'
            : '${absDelta.toStringAsFixed(1)} ▶');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(
        color: color, fontWeight: FontWeight.w800, fontSize: 12,
      )),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.titleLarge.copyWith(
          color: color, fontWeight: FontWeight.w800)),
        Text(label, style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary)),
      ],
    );
  }
}
