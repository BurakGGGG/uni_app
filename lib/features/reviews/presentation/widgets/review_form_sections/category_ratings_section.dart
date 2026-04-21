import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../domain/models/review_model.dart';

/// Yorum formunda kategori bazlı yıldız puanlaması bölümü.
///
/// [type] parametresine göre üniversite veya bölüm kategorilerini gösterir.
/// Her kategori için 1-5 arası yıldız puanlaması yapılır.
class CategoryRatingsSection extends StatelessWidget {
  final ReviewType type;
  final Map<String, double> ratings;
  final void Function(String category, double rating) onChanged;

  const CategoryRatingsSection({
    super.key,
    required this.type,
    required this.ratings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categories = type == ReviewType.university
        ? AppConstants.uniRatingCategories
        : AppConstants.deptRatingCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Kategori Puanları', style: AppTextStyles.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Her kategori için 1-5 arası puan verin',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        ...categories.map((category) => _buildCategoryRow(category)),
      ],
    );
  }

  Widget _buildCategoryRow(String category) {
    final rating = ratings[category] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              category,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: rating > 0 ? FontWeight.w600 : FontWeight.w400,
                color: rating > 0 ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                final isFilled = starIndex <= rating;
                return GestureDetector(
                  onTap: () => onChanged(category, starIndex.toDouble()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: isFilled ? AppColors.warning : AppColors.textTertiary,
                      size: 28,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
