import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/widgets/badge_showcase.dart';
import '../../domain/models/review_model.dart';
import '../providers/review_providers.dart';
import '../widgets/review_card.dart';

final _myReviewFilterProvider = StateProvider.autoDispose<ReviewType?>((ref) => null);

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yorumlarım')),
        body: _buildUnauthenticatedState(context),
      );
    }
    
    final reviewsAsync = ref.watch(userReviewsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Yorumlarım')),
      body: RefreshIndicator(
        onRefresh: () async {
          invalidateUserProfileAfterReviewChange(ref);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) return _buildEmptyState(context);

            final filterType = ref.watch(_myReviewFilterProvider);
            final filteredReviews = filterType == null 
                ? reviews 
                : reviews.where((r) => r.type == filterType).toList();

            final pendingCount = reviews.where((r) => !r.isApproved).length;

            final profile = ref.watch(currentUserProvider).value;

            return Column(
              children: [
                if (profile != null)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: BadgeShowcase(),
                  ),
                if (pendingCount > 0)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$pendingCount yorumun moderasyon nedeniyle yayınlanmadı. '
                            'Aşağıda işaretlendi.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 4,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0: return _buildFilterChip(context, ref, null, 'Tümü', filterType);
                        case 1: return _buildFilterChip(context, ref, ReviewType.university, 'Üniversiteler', filterType);
                        case 2: return _buildFilterChip(context, ref, ReviewType.department, 'Bölümler', filterType);
                        case 3: return _buildFilterChip(context, ref, ReviewType.place, 'Mekanlar', filterType);
                        default: return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: filteredReviews.isEmpty 
                    ? const EmptyStateWidget(
                        icon: Icons.filter_list_off_rounded,
                        title: 'Yorum bulunamadı',
                        description: 'Bu kategoriye ait yorumunuz bulunmuyor.',
                      )
                    : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: filteredReviews.length,
                    itemBuilder: (_, i) {
                      final r = filteredReviews[i];
                      return AnimatedListItem(
                        index: i,
                        child: ReviewCard(
                        review: r,
                        showActions: true,
                        showReportMenu: false,
                        showTargetInfo: true, // YENİ
                        onEdited: () => context.push('/edit-review/${r.id}'),
                        onTap: () {
                          switch (r.type) {
                            case ReviewType.department:
                              context.push('/department/${r.targetId}');
                              break;
                            case ReviewType.place:
                              context.push('/place/${r.targetId}');
                              break;
                            case ReviewType.university:
                              context.push('/university/${r.targetId}');
                              break;
                          }
                        },
                        onDeleted: () async {
                          await ref.read(reviewActionControllerProvider.notifier).deleteReview(r);
                          invalidateUserProfileAfterReviewChange(ref);
                          if (context.mounted) {
                            showAppSnackBar(context, message: 'Yorumunuz başarıyla silindi', isSuccess: true);
                          }
                        },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const ListSkeleton(itemCount: 4),
          error: (e, _) => ErrorStateWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(userReviewsProvider(user.uid)),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.rate_review_outlined,
      title: 'Henüz yorumun yok',
      description: 'Üniversiteni değerlendir ve diğer öğrencilere yardımcı ol.',
      action: ElevatedButton.icon(
        onPressed: () => context.push('/write-review'),
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: const Text('Yorum Yaz'),
      ),
    );
  }

  Widget _buildUnauthenticatedState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 64, color: AppColors.textTertiaryFor(context)),
          const SizedBox(height: 16),
          Text('Giriş Yapmanız Gerekiyor', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Yorumlarınızı görebilmek için\nlütfen giriş yapın.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.push('/login'),
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, ReviewType? type, String label, ReviewType? currentFilter) {
    final selected = type == currentFilter;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        ref.read(_myReviewFilterProvider.notifier).state = type;
      },
      backgroundColor: AppColors.surfaceFor(context),
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: selected ? AppColors.primary : AppColors.textSecondaryFor(context),
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.3)
            : AppColors.borderLightFor(context),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }
}
