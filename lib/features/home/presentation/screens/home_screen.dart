import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../university/presentation/providers/university_providers.dart';

import '../../../university/domain/models/university_model.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../reviews/presentation/providers/review_providers.dart';
import '../../../reviews/presentation/widgets/review_card.dart';
import '../../../reviews/domain/models/review_model.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../university/presentation/widgets/city_card.dart';

/// Ana Sayfa ekranı
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(citiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ─── Header ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Merhaba! 👋',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Üni',
                                  style: AppTextStyles.displaySmall.copyWith(
                                    color: AppColors.primary,
                                    fontFamily: 'SpaceGrotesk',
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.2,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                SvgPicture.asset(
                                  'assets/icons/compare_icon.svg',
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 1),
                                Text(
                                  'eç',
                                  style: AppTextStyles.displaySmall.copyWith(
                                    color: AppColors.primary,
                                    fontFamily: 'SpaceGrotesk',
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Bildirim ikonu
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: const NotificationBell(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── Arama Çubuğu ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: AppSearchBar(
                  readOnly: true,
                  onTap: () {
                    context.push('/search');
                  },
                ),
              ),
            ),

            // ─── Hero Banner ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: const _HeroBanner(),
              ),
            ),

            // ─── Popüler Üniversiteler ──────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SectionHeader(
                    title: 'Popüler Üniversiteler',
                    actionText: 'Tümünü Gör',
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
                    onAction: () => context.go('/explore'),
                  ),
                  SizedBox(
                    height: 200,
                    child: ref.watch(popularUniversitiesProvider).when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Center(child: Text('Hata: $e')),
                      data: (popular) {
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          cacheExtent: 200,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: popular.length,
                          itemBuilder: (context, index) {
                            return RepaintBoundary(
                              child: _PopularUniCard(
                                university: popular[index],
                                index: index,
                                onTap: () => context.push('/university/${popular[index].id}'),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ─── Şehirler ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SectionHeader(
                    title: 'Şehirler',
                    actionText: 'Tümünü Gör',
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                    onAction: () => context.push('/cities'),
                  ),
                  SizedBox(
                    height: 200,
                    child: citiesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Center(child: Text('$e')),
                      data: (cities) {
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: cities.length,
                          itemBuilder: (context, index) {
                            return CityCard.compact(
                              city: cities[index],
                              onTap: () => context.push('/city/${cities[index].id}'),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ─── Son Yorumlar ───────────────────────────────────────
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Son Yorumlar',
                actionText: 'Tümünü Gör',
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                onAction: () => context.push('/all-reviews'),
              ),
            ),

            ref.watch(recentReviewsProvider).when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (e, st) => SliverToBoxAdapter(
                child: Center(child: Text('Yorumlar yüklenemedi: $e')),
              ),
              data: (reviews) {
                if (reviews.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.rate_review_outlined, size: 48, color: AppColors.textTertiary),
                            const SizedBox(height: 12),
                            Text('Henüz yorum yok', style: AppTextStyles.titleMedium),
                            Text(
                              'İlk yorumu yazan siz olun!',
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final review = reviews[index];
                      return ReviewCard(
                        review: review,
                        compact: true,
                        showReportMenu: false,
                        showActions: false,
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
                    childCount: reviews.length,
                  ),
                );
              },
            ),

            // Bottom padding
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }
}

// ─── Widget Components ──────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Dekoratif daireler
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // İçerik
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '2026 Tercih Dönemi',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hayalindeki üniversiteyi\nkeşfetmeye başla!',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Keşfet →',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularUniCard extends ConsumerWidget {
  final UniversityModel university;
  final int index;
  final VoidCallback onTap;

  const _PopularUniCard({
    required this.university,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesProvider.select((async) => async.value?.contains(university.id) ?? false),
    );
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];
    final color = colors[index % colors.length];

    final brandColor = university.brandColor ?? color;

    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        boxShadow: AppColors.softShadow,
        gradient: LinearGradient(
          colors: [
            brandColor.withValues(alpha: 0.5),
            brandColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.0), // Çerçeve kalınlığı
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg - 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg - 1.5),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppConstants.radiusLg - 1.5),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Image.asset(
                        university.logoAssetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.school_rounded, color: color, size: 28),
                        ),
                      ),
                    ),
                    if (isFavorite)
                      const Icon(Icons.favorite_rounded, color: AppColors.error, size: 18),
                  ],
                ),
                const Spacer(),
                // Başlık
                Text(
                  university.name,
                  style: AppTextStyles.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Tür rozeti
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (university.type == 'Devlet' ? AppColors.stateUni : AppColors.foundationUni)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        university.type,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: university.type == 'Devlet' ? AppColors.stateUni : AppColors.foundationUni,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
      ),
    );
  }
}
