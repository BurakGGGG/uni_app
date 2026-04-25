import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../domain/models/review_model.dart';
import '../providers/review_providers.dart';
import '../widgets/review_card.dart';

/// Sprint 3 Fix — Bug 3
/// Tüm yorumları filtreli/sıralı gösteren ekran.
class AllReviewsScreen extends ConsumerWidget {
  const AllReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(allReviewsFilterProvider);
    final reviewsAsync = ref.watch(allFilteredReviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Tüm Yorumlar', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          Badge(
            isLabelVisible: filter.activeFilterCount > 0,
            label: Text('${filter.activeFilterCount}'),
            backgroundColor: AppColors.primary,
            offset: const Offset(-4, 4),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => _showFilterSheet(context, ref),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Aktif filtre chip'leri
          _buildActiveFilterChips(ref, filter),

          // Sıralama barı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Sıralama:',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'En Yeni',
                  selected: filter.sort == ReviewSort.newest,
                  onTap: () => ref.read(allReviewsFilterProvider.notifier)
                      .setSort(ReviewSort.newest),
                ),
                const SizedBox(width: 6),
                _SortChip(
                  label: 'En Beğenilen',
                  selected: filter.sort == ReviewSort.mostLiked,
                  onTap: () => ref.read(allReviewsFilterProvider.notifier)
                      .setSort(ReviewSort.mostLiked),
                ),
              ],
            ),
          ),

          // Yorum listesi
          Expanded(
            child: reviewsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Yorumlar yüklenemedi', style: AppTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Text('$e',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ),
              data: (reviews) {
                if (reviews.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.rate_review_outlined,
                    title: filter.hasFilters
                        ? 'Bu filtreye uygun yorum yok'
                        : 'Henüz yorum yok',
                    description: filter.hasFilters
                        ? 'Farklı bir filtre deneyin veya tüm yorumları görün.'
                        : 'İlk yorumu yazan siz olun!',
                    actionText: filter.hasFilters ? 'Filtreleri Temizle' : null,
                    onAction: filter.hasFilters
                        ? () => ref.read(allReviewsFilterProvider.notifier).clearAll()
                        : null,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 100),
                  itemCount: reviews.length,
                  itemBuilder: (context, i) {
                    final review = reviews[i];
                    final currentUser = ref.watch(authStateProvider).value;
                    final isOwner = currentUser?.uid == review.userId;

                    return ReviewCard(
                      review: review,
                      showActions: isOwner,
                      showReportMenu: !isOwner,
                      onTap: () {
                        if (review.type == ReviewType.department) {
                          context.push('/department/${review.targetId}');
                        } else {
                          context.push('/university/${review.targetId}');
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips(WidgetRef ref, AllReviewsFilterState filter) {
    if (!filter.hasFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (filter.reviewType != null)
            Chip(
              label: Text(
                filter.reviewType == ReviewType.university ? 'Üniversite' : 'Bölüm',
              ),
              onDeleted: () =>
                  ref.read(allReviewsFilterProvider.notifier).setReviewType(null),
              deleteIconColor: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
            ),
          if (filter.universityId != null)
            Consumer(
              builder: (context, ref, _) {
                final uniAsync =
                    ref.watch(universityDetailProvider(filter.universityId!));
                return Chip(
                  label: Text(uniAsync.value?.name ?? 'Üniversite'),
                  onDeleted: () => ref
                      .read(allReviewsFilterProvider.notifier)
                      .setUniversity(null),
                  deleteIconColor: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  labelStyle:
                      AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _FilterBottomSheet(),
    );
  }
}

// ─── Sıralama Chip'i ──────────────────────────────────────────

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Filtre Bottom Sheet (İskelet — Gün 3'te doldurulacak) ──────

class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(allReviewsFilterProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filtreler', style: AppTextStyles.titleLarge),
                if (filter.hasFilters)
                  TextButton(
                    onPressed: () {
                      ref.read(allReviewsFilterProvider.notifier).clearAll();
                      Navigator.pop(context);
                    },
                    child: const Text('Temizle'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Yorum Tipi filtresi
            Text('Yorum Tipi', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Hepsi'),
                  selected: filter.reviewType == null,
                  onSelected: (_) {
                    ref.read(allReviewsFilterProvider.notifier).setReviewType(null);
                  },
                ),
                ChoiceChip(
                  label: const Text('Üniversite'),
                  selected: filter.reviewType == ReviewType.university,
                  onSelected: (_) {
                    ref.read(allReviewsFilterProvider.notifier)
                        .setReviewType(ReviewType.university);
                  },
                ),
                ChoiceChip(
                  label: const Text('Bölüm'),
                  selected: filter.reviewType == ReviewType.department,
                  onSelected: (_) {
                    ref.read(allReviewsFilterProvider.notifier)
                        .setReviewType(ReviewType.department);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Uygula butonu
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Uygula'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
