import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_constants.dart';

/// Rating gösterim widget'ı — yatay bar + sayısal değer
class RatingDisplay extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final bool showLabel;
  final bool compact;

  const RatingDisplay({
    super.key,
    required this.label,
    required this.value,
    this.maxValue = 5.0,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);
    final color = AppColors.ratingColor(value);

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: AppColors.ratingStar),
          const SizedBox(width: 2),
          Text(
            value.toStringAsFixed(1),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: AppTextStyles.bodySmall),
                Text(
                  value.toStringAsFixed(1),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}

/// Rating kartı — birden fazla kategoriyi gösteren kart
class RatingCard extends StatelessWidget {
  final String title;
  final Map<String, double> ratings;
  final double? overallRating;

  const RatingCard({
    super.key,
    required this.title,
    required this.ratings,
    this.overallRating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve genel puan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.titleLarge),
              if (overallRating != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        AppColors.ratingColor(overallRating!).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: AppColors.ratingColor(overallRating!),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        overallRating!.toStringAsFixed(1),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.ratingColor(overallRating!),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingLg),
          // Kategori puanları
          ...ratings.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
              child: RatingDisplay(
                label: entry.key,
                value: entry.value,
              ),
            );
          }),
        ],
      ),
    );
  }
}
