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
        title: const Text('Tüm Yorumlar'),
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
                  cacheExtent: 1000,
                  itemCount: reviews.length,
                  itemBuilder: (context, i) {
                    final review = reviews[i];
                    final currentUser = ref.watch(authStateProvider).value;
                    final isOwner = currentUser?.uid == review.userId;

                    return ReviewCard(
                      review: review,
                      showActions: isOwner,
                      showReportMenu: !isOwner,
                      showTargetInfo: true, // YENİ
                      onTap: () {
                        switch (review.type) {
                          case ReviewType.department:
                            context.push('/department/${review.targetId}');
                            break;
                          case ReviewType.place:
                            context.push('/place/${review.targetId}');
                            break;
                          case ReviewType.university:
                            context.push('/university/${review.targetId}');
                            break;
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

// ─── Filtre Bottom Sheet ─────────────────────────────────────────────

class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(allReviewsFilterProvider);
    final universitiesAsync = ref.watch(allUniversitiesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filtreler', style: AppTextStyles.titleLarge),
                  if (filter.hasFilters)
                    TextButton(
                      onPressed: () => ref
                          .read(allReviewsFilterProvider.notifier)
                          .clearAll(),
                      child: Text(
                        'Temizle',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(color: AppColors.borderLight, height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Tip Filtresi
                  Text('Yorum Tipi', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _TypeOption(
                        icon: Icons.school_rounded,
                        label: 'Üniversite',
                        isSelected: filter.reviewType == ReviewType.university,
                        onTap: () {
                          final current = filter.reviewType;
                          ref.read(allReviewsFilterProvider.notifier).setReviewType(
                                current == ReviewType.university
                                    ? null
                                    : ReviewType.university,
                              );
                        },
                      ),
                      const SizedBox(width: 10),
                      _TypeOption(
                        icon: Icons.menu_book_rounded,
                        label: 'Bölüm',
                        isSelected: filter.reviewType == ReviewType.department,
                        onTap: () {
                          final current = filter.reviewType;
                          ref.read(allReviewsFilterProvider.notifier).setReviewType(
                                current == ReviewType.department
                                    ? null
                                    : ReviewType.department,
                              );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sıralama
                  Text('Sıralama', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('En Yeni'),
                        selected: filter.sort == ReviewSort.newest,
                        onSelected: (v) {
                          if (v) {
                            ref.read(allReviewsFilterProvider.notifier)
                                .setSort(ReviewSort.newest);
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('En Beğenilen'),
                        selected: filter.sort == ReviewSort.mostLiked,
                        onSelected: (v) {
                          if (v) {
                            ref.read(allReviewsFilterProvider.notifier)
                                .setSort(ReviewSort.mostLiked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Üniversite Filtresi
                  Text('Üniversite', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  universitiesAsync.when(
                    data: (universities) {
                      return Column(
                        children: [
                          ...universities.map(
                            (uni) => RadioListTile<String?>(
                              value: uni.id,
                              // ignore: deprecated_member_use
                              groupValue: filter.universityId,
                              // ignore: deprecated_member_use
                              onChanged: (val) => ref
                                  .read(allReviewsFilterProvider.notifier)
                                  .setUniversity(val),
                              title: Text(
                                uni.name,
                                style: AppTextStyles.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${uni.type} • ${uni.reviewCount} yorum',
                                style: AppTextStyles.labelSmall,
                              ),
                              dense: true,
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) =>
                        Text('Üniversiteler yüklenemedi', style: AppTextStyles.bodySmall),
                  ),
                ],
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: GradientButton(
                  text: 'Sonuçları Göster',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Tip Seçim Kartı ─────────────────────────────────────────────────

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
