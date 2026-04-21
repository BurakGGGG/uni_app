import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/review_model.dart';
import '../providers/review_providers.dart';
import 'review_card.dart';

/// Sprint 3 — Kişi B (Task B2 İskeleti)
/// Üniversite ve bölüm detay sayfalarında kullanılacak yorum listesi.
/// Şimdilik mevcut getUniversityReviews stream'ini kullanır, sort eklenmedi.
class ReviewList extends ConsumerWidget {
  final String targetId;
  final ReviewType type;
  final bool showSortOptions;

  const ReviewList({
    super.key,
    required this.targetId,
    required this.type,
    this.showSortOptions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Şimdilik sadece mevcut provider'ları kullan (sort Gün 5'te eklenecek)
    final reviewsAsync = type == ReviewType.university
        ? ref.watch(universityReviewsProvider(targetId))
        : ref.watch(departmentReviewsProvider(targetId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TODO(B2-Gün5): Sort bar eklenecek (En Yeni / En Beğenilen)

        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) return _buildEmptyState();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (_, i) => ReviewCard(review: reviews[i]),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(20),
            child: Center(child: Text('Yorumlar yüklenemedi: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz yorum yapılmamış',
              style: AppTextStyles.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'İlk değerlendiren siz olun!',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
