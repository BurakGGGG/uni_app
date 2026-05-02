import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/university_providers.dart';
import '../../domain/models/department_model.dart';
import '../../domain/models/university_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../reviews/presentation/widgets/category_ratings_chart.dart';
import '../../../reviews/presentation/providers/review_providers.dart';
import '../../../reviews/presentation/widgets/review_card.dart';
import '../../../places/presentation/providers/place_providers.dart';
import '../../../places/domain/models/place_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UniversityDetailScreen extends ConsumerWidget {
  final String universityId;

  const UniversityDetailScreen({super.key, required this.universityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uniAsync = ref.watch(universityDetailProvider(universityId));
    final deptsAsync = ref.watch(departmentsByUniversityProvider(universityId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: uniAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Hata: $e')),
        data: (uni) {
          if (uni == null) {
            return const Center(child: Text('Üniversite bulunamadı'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(universityDetailProvider(universityId));
              ref.invalidate(departmentsByUniversityProvider(universityId));
              ref.invalidate(placesByUniversityProvider(universityId));
              ref.invalidate(universityReviewsProvider(universityId));
            },
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, uni),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      RepaintBoundary(child: _buildCompactInfoCard(context, ref, uni)),
                      RepaintBoundary(child: _buildRatingsPreview(context, uni)),
                      RepaintBoundary(child: _buildDepartmentsPreview(context, deptsAsync)),
                      RepaintBoundary(child: _buildPlacesPreview(context, ref)),
                      RepaintBoundary(child: _buildReviewsPreview(context, ref, uni)),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Compact SliverAppBar ─────────────────────────────────────
  Widget _buildSliverAppBar(BuildContext context, UniversityModel uni) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
      actions: [_FavoriteButton(universityId: universityId)],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          uni.name,
          style: AppTextStyles.titleSmall.copyWith(color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14, end: 56),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.85),
                AppColors.secondary,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.only(bottom: 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Compact Info Card ────────────────────────────────────────
  Widget _buildCompactInfoCard(BuildContext context, WidgetRef ref, UniversityModel uni) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
          Row(
            children: [
              _Badge(
                text: uni.type,
                color: uni.type == 'Devlet' ? AppColors.stateUni : AppColors.foundationUni,
              ),
              const SizedBox(width: 6),
              _Badge(
                text: uni.campusLayout.label,
                color: AppColors.info,
                icon: uni.campusLayout.icon,
              ),
              const Spacer(),
              if (uni.reviewCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.ratingColor(uni.avgRating).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 14,
                        color: AppColors.ratingColor(uni.avgRating)),
                      const SizedBox(width: 3),
                      Text(uni.avgRating.toStringAsFixed(1),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.ratingColor(uni.avgRating),
                          fontWeight: FontWeight.w700,
                        )),
                      const SizedBox(width: 4),
                      Text('(${uni.reviewCount})',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.ratingColor(uni.avgRating))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (uni.description.isNotEmpty)
            Text(
              uni.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('Kuruluş ${uni.establishedYear}',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary)),
              const SizedBox(width: 12),
              if (uni.website.isNotEmpty)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _launchUrl('https://${uni.website}'),
                    child: Row(
                      children: [
                        Icon(Icons.language_rounded, size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(uni.website,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  // ─── Genel Puanlar Önizleme ──────────────────────────────────
  Widget _buildRatingsPreview(BuildContext context, UniversityModel uni) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          CategoryRatingsChart(
            ratings: uni.categoryRatings,
            reviewCount: uni.reviewCount,
          ),
          if (uni.reviewCount > 0) ...[
            const SizedBox(height: 4),
            _SeeAllButton(
              label: 'Tüm yorumları gör',
              onTap: () => context.push('/university/$universityId/reviews'),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  // ─── Bölümler Önizleme ───────────────────────────────────────
  Widget _buildDepartmentsPreview(
      BuildContext context, AsyncValue<List<DepartmentModel>> deptsAsync) {
    return deptsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (departments) {
        if (departments.isEmpty) {
          return _PreviewSection(
            icon: Icons.school_rounded,
            title: 'Bölümler',
            count: 0,
            child: _MiniEmptyState(
              icon: Icons.school_outlined,
              message: 'Henüz bölüm bilgisi eklenmemiş',
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.05, end: 0);
        }

        final preview = departments.take(3).toList();

        return _PreviewSection(
          icon: Icons.school_rounded,
          title: 'Bölümler',
          count: departments.length,
          child: Column(
            children: [
              ...preview.map((dept) => _DepartmentPreviewTile(
                department: dept,
                onTap: () => context.push('/department/${dept.id}'),
              )),
              const SizedBox(height: 8),
              _SeeAllButton(
                label: 'Tüm ${departments.length} bölümü gör',
                onTap: () => context.push('/university/$universityId/departments'),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.05, end: 0);
      },
    );
  }

  // ─── Mekanlar Önizleme ───────────────────────────────────────
  Widget _buildPlacesPreview(BuildContext context, WidgetRef ref) {
    final placesAsync = ref.watch(placesByUniversityProvider(universityId));

    return placesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (places) {
        if (places.isEmpty) {
          return _PreviewSection(
            icon: Icons.place_rounded,
            title: 'Mekanlar',
            count: 0,
            child: _MiniEmptyState(
              icon: Icons.place_outlined,
              message: 'Henüz mekan eklenmemiş',
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms).slideY(begin: 0.05, end: 0);
        }

        final preview = places.take(4).toList();

        return _PreviewSection(
          icon: Icons.place_rounded,
          title: 'Mekanlar',
          count: places.length,
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.4,
                ),
                itemCount: preview.length,
                itemBuilder: (_, i) => _PlacePreviewCard(
                  place: preview[i],
                  onTap: () => context.push(
                      '/university/$universityId/place/${preview[i].id}'),
                ),
              ),
              _SeeAllButton(
                label: 'Tüm ${places.length} mekanı gör',
                onTap: () => context.push('/university/$universityId/places'),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 300.ms).slideY(begin: 0.05, end: 0);
      },
    );
  }

  // ─── Yorumlar Önizleme ───────────────────────────────────────
  Widget _buildReviewsPreview(
      BuildContext context, WidgetRef ref, UniversityModel uni) {
    final reviewsAsync =
        ref.watch(universityReviewsProvider(universityId));

    return reviewsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (reviews) {
        if (reviews.isEmpty) {
          return _PreviewSection(
            icon: Icons.rate_review_rounded,
            title: 'Yorumlar',
            count: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.rate_review_outlined,
                        size: 36,
                        color: AppColors.textTertiary.withValues(alpha: 0.4)),
                    const SizedBox(height: 8),
                    Text('Henüz yorum yapılmamış',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 300.ms).slideY(begin: 0.05, end: 0);
        }

        final preview = reviews.take(3).toList();

        return _PreviewSection(
          icon: Icons.rate_review_rounded,
          title: 'Yorumlar',
          count: reviews.length,
          child: Column(
            children: [
              ...preview.map((review) => ReviewCard(
                review: review,
                showActions: false,
                showReportMenu: false,
              )),
              const SizedBox(height: 8),
              _SeeAllButton(
                label: 'Tüm ${reviews.length} yorumu gör',
                onTap: () => context.push('/university/$universityId/reviews'),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 300.ms).slideY(begin: 0.05, end: 0);
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Yardımcı Widget'lar
// ═══════════════════════════════════════════════════════════════════

// ─── Preview Section Container ──────────────────────────────────
class _PreviewSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Widget child;

  const _PreviewSection({
    required this.icon,
    required this.title,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
          // Section header
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.titleMedium),
              const Spacer(),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Mini Empty State ───────────────────────────────────────────
class _MiniEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _MiniEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── "Tümünü Gör" Butonu ────────────────────────────────────────
class _SeeAllButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SeeAllButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Bölüm Önizleme Tile ───────────────────────────────────────
class _DepartmentPreviewTile extends StatelessWidget {
  final DepartmentModel department;
  final VoidCallback onTap;

  const _DepartmentPreviewTile({
    required this.department,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: (department.type == 'Lisans'
                          ? AppColors.primary
                          : AppColors.accent)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  department.type == 'Lisans'
                      ? Icons.school_rounded
                      : Icons.auto_stories_rounded,
                  color: department.type == 'Lisans'
                      ? AppColors.primary
                      : AppColors.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(department.name,
                        style: AppTextStyles.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(department.faculty,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textTertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (department.baseScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    department.baseScore!.toStringAsFixed(1),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mekan Önizleme Grid Kartı ──────────────────────────────────
class _PlacePreviewCard extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback onTap;

  const _PlacePreviewCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto thumbnail
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppConstants.radiusMd)),
                  child: place.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: place.imageUrls.first,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          memCacheWidth: 300,
                          placeholder: (_, _) => Container(
                            color: _typeColor(place.type).withValues(alpha: 0.08),
                            child: Icon(place.type.icon,
                                color: _typeColor(place.type), size: 28),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: _typeColor(place.type).withValues(alpha: 0.08),
                            child: Center(
                              child: Icon(place.type.icon,
                                  color: _typeColor(place.type), size: 28),
                            ),
                          ),
                        )
                      : Container(
                          color: _typeColor(place.type).withValues(alpha: 0.08),
                          child: Center(
                            child: Icon(place.type.icon,
                                color: _typeColor(place.type), size: 28),
                          ),
                        ),
                ),
              ),
              // İsim + rating
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name,
                        style: AppTextStyles.labelMedium
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (place.avgRating > 0)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 12, color: AppColors.ratingStar),
                          const SizedBox(width: 2),
                          Text(
                            place.avgRating.toStringAsFixed(1),
                            style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _typeColor(PlaceType type) {
    switch (type) {
      case PlaceType.cafe:
        return const Color(0xFFE65100);
      case PlaceType.dorm:
        return const Color(0xFF0D47A1);
      case PlaceType.library:
        return const Color(0xFF6A1B9A);
      case PlaceType.studyArea:
        return AppColors.success;
      case PlaceType.sports:
        return AppColors.warning;
    }
  }
}

// ─── Badge ──────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _Badge({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(text, style: AppTextStyles.labelSmall.copyWith(
            color: color, fontWeight: FontWeight.w600, fontSize: 10,
          )),
        ],
      ),
    );
  }
}

// ─── Favorite Button ────────────────────────────────────────────
class _FavoriteButton extends ConsumerWidget {
  final String universityId;

  const _FavoriteButton({required this.universityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final favoritesAsync = ref.watch(favoritesProvider);

    return favoritesAsync.when(
      data: (favorites) {
        final isFavorite = favorites.contains(universityId);
        return IconButton(
          onPressed: () {
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Favorilere eklemek için giriş yapmalısın.'),
                  action: SnackBarAction(
                    label: 'Giriş Yap',
                    textColor: Colors.white,
                    onPressed: () => context.push('/login'),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            ref.read(favoritesControllerProvider.notifier).toggleFavorite(
              user.uid, universityId, isFavorite);
          },
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? AppColors.error : Colors.white,
          ),
        );
      },
      loading: () => const IconButton(
        onPressed: null,
        icon: SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)),
      ),
      error: (err, stack) => const IconButton(
        onPressed: null,
        icon: Icon(Icons.favorite_border_rounded, color: Colors.white54),
      ),
    );
  }
}
