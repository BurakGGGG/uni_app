import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../assistant/domain/robot_scripts.dart';
import '../../../assistant/presentation/widgets/uni_empty_state.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/review_model.dart';
import '../providers/review_providers.dart';
import 'review_card.dart';

/// Sprint 3 — Kişi B (Task B2)
/// Üniversite ve bölüm detay sayfalarında kullanılacak yorum listesi.
/// Sort bar ile "En Yeni" / "En Beğenilen" sıralama destekler.
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
    final sort = ref.watch(reviewSortProvider);
    final reviewsAsync = ref.watch(sortedReviewsProvider(
      SortedReviewsParams(targetId: targetId, type: type),
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSortOptions) _buildSortBar(context, ref, sort),
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) return _buildEmptyState(context);
            
            final currentUserId = ref.watch(authStateProvider).value?.uid;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              scrollCacheExtent: ScrollCacheExtent.pixels(1000),
              itemCount: reviews.length,
              itemBuilder: (context, i) {
                final review = reviews[i];
                final isOwner = currentUserId != null && currentUserId == review.userId;

                return ReviewCard(
                  review: review,
                  showActions: isOwner,
                  showReportMenu: !isOwner,
                  onEdited: isOwner
                      ? () => context.push('/edit-review/${review.id}')
                      : null,
                  onDeleted: isOwner
                      ? () async {
                          await ref.read(reviewActionControllerProvider.notifier).deleteReview(review);
                          invalidateUserProfileAfterReviewChange(ref);
                          if (context.mounted) {
                            showAppSnackBar(context, message: 'Yorumunuz başarıyla silindi', isSuccess: true);
                          }
                        }
                      : null,
                );
              },
            );
          },
          loading: () => const ListSkeleton(itemCount: 3),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Yorumlar yüklenemedi: $e',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortBar(BuildContext context, WidgetRef ref, ReviewSort current) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            loc.reviewSortLabel,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(loc.reviewSortNewest),
            selected: current == ReviewSort.newest,
            onSelected: (v) {
              if (v) {
                ref.read(reviewSortProvider.notifier).state = ReviewSort.newest;
              }
            },
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            labelStyle: AppTextStyles.labelSmall.copyWith(
              color: current == ReviewSort.newest
                  ? AppColors.primary
                  : AppColors.textSecondaryFor(context),
              fontWeight: current == ReviewSort.newest
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
            side: BorderSide(
              color: current == ReviewSort.newest
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.borderLightFor(context),
            ),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(loc.reviewSortMostLiked),
            selected: current == ReviewSort.mostLiked,
            onSelected: (v) {
              if (v) {
                ref.read(reviewSortProvider.notifier).state =
                    ReviewSort.mostLiked;
              }
            },
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            labelStyle: AppTextStyles.labelSmall.copyWith(
              color: current == ReviewSort.mostLiked
                  ? AppColors.primary
                  : AppColors.textSecondaryFor(context),
              fontWeight: current == ReviewSort.mostLiked
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
            side: BorderSide(
              color: current == ReviewSort.mostLiked
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.borderLightFor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // Üni davet ediyor — eski metin "siz" diliyle yazılmıştı, Üni'nin
    // "sen" diline geçti.
    return Padding(
      padding: const EdgeInsets.all(24),
      child: UniEmptyState(
        icon: Icons.rate_review_outlined,
        title: 'Henüz yorum yapılmamış',
        script: RobotScripts.emptyUniReviews,
        compact: true,
      ),
    );
  }

}
