import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/review_model.dart';
import '../providers/review_providers.dart';

/// Sprint 3 — Like butonu
/// Optimistic UI: pending varsa pending göster, yoksa server'ı göster.
/// .select() ile sadece kendi review'ı değişince rebuild olur.
class LikeButton extends ConsumerWidget {
  final ReviewModel review;
  const LikeButton({super.key, required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    // Server'dan gelen gerçek durum — .select ile sadece bu review için rebuild
    final isLikedFromServer = ref.watch(
      userLikedReviewsProvider.select(
        (async) => async.value?.contains(review.id) ?? false,
      ),
    );

    // Pending varsa onun "desired" durumunu göster
    final pendingDesired = ref.watch(
      likeControllerProvider.select((m) => m[review.id]?.desiredLiked),
    );

    // Pending varsa pending göster, yoksa server'ı göster
    final isLiked = pendingDesired ?? isLikedFromServer;

    return InkWell(
      onTap: user == null
          ? null
          : () {
              ref.read(likeControllerProvider.notifier).toggleLike(
                    reviewId: review.id,
                    userId: user.uid,
                    currentlyLiked: isLiked,
                  );
            },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 16,
              color: isLiked ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              '${review.likes}',
              style: AppTextStyles.labelMedium.copyWith(
                color: isLiked ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
