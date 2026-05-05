import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/rating_display.dart';

/// Sprint 3 — Kişi B (Task B5)
/// Üniversite ve bölümlerin kategori bazlı puanlarını gösteren chart widget'ı.
class CategoryRatingsChart extends StatelessWidget {
  final Map<String, double> ratings;
  final int reviewCount;
  
  const CategoryRatingsChart({
    super.key,
    required this.ratings,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    // Hiç yorum yoksa empty state göster
    if (reviewCount == 0) {
      return _buildEmptyState();
    }

    // Yorum var ama kategori puanları henüz hesaplanmamışsa, bölümü gizle
    if (ratings.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Kategori Puanları', style: AppTextStyles.titleMedium),
              const Spacer(),
              Text(
                '$reviewCount değerlendirme',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...ratings.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RatingDisplay(
              label: e.key,
              value: e.value,
              compact: false, // compact mode hides the bar, we want the bar here
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.insights_outlined, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text('Henüz yeterli değerlendirme yok', 
            style: AppTextStyles.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text('İlk değerlendiren siz olun!', 
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
