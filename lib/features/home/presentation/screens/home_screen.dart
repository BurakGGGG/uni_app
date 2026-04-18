import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../../university/domain/models/city_model.dart';
import '../../../university/domain/models/university_model.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../reviews/presentation/providers/review_providers.dart';
import '../../../reviews/domain/models/review_model.dart';

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
                            Text(
                              AppConstants.appName,
                              style: AppTextStyles.displaySmall.copyWith(
                                color: AppColors.primary,
                              ),
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
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
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
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
            ),

            // ─── Hero Banner ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _HeroBanner(),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: popular.length,
                          itemBuilder: (context, index) {
                            return _PopularUniCard(
                              university: popular[index],
                              index: index,
                              onTap: () => context.push('/university/${popular[index].id}'),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
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
                    height: 110,
                    child: citiesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Center(child: Text('$e')),
                      data: (cities) {
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: cities.length,
                          itemBuilder: (context, index) {
                            return _CityChip(
                              city: cities[index],
                              onTap: () => context.push('/city/${cities[index].id}'),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ),

            // ─── Son Yorumlar ───────────────────────────────────────
            SliverToBoxAdapter(
              child: const SectionHeader(
                title: 'Son Yorumlar',
                actionText: 'Tümünü Gör',
                padding: EdgeInsets.fromLTRB(20, 16, 12, 4),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
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
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('Henüz değerlendirme yapılmamış')),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final review = reviews[index];
                      return _RecentReviewCard(review: review)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 550 + index * 80), duration: 400.ms)
                          .slideX(begin: 0.05, end: 0);
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

// ─── Şehir Emoji Mapping ──────────────────────────────────────────────
String _cityEmoji(String cityName) {
  const emojis = {
    'İstanbul': '🌉',
    'Ankara': '🏛️',
    'İzmir': '🌊',
    'Antalya': '☀️',
    'Eskişehir': '🎓',
    'Bursa': '🌿',
    'Çanakkale': '⚓',
    'Sivas': '🏔️',
    'Trabzon': '⛰️',
    'Mersin': '🍊',
  };
  return emojis[cityName] ?? '🏙️';
}

// ─── Widget Components ──────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
      ),
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
            padding: const EdgeInsets.all(AppConstants.spacingXxl),
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
    final favoritesAsync = ref.watch(favoritesProvider);
    final isFavorite = favoritesAsync.value?.contains(university.id) ?? false;
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

    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.school_rounded, color: color, size: 24),
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
    );
  }
}

class _CityChip extends StatelessWidget {
  final CityModel city;
  final VoidCallback onTap;

  const _CityChip({required this.city, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_cityEmoji(city.name), style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                city.name,
                style: AppTextStyles.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${city.appUniversityCount} üni',
                style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _RecentReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
          // Kullanıcı bilgisi
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundImage: review.userPhotoUrl != null ? NetworkImage(review.userPhotoUrl!) : null,
                child: review.userPhotoUrl == null
                    ? Text(
                        review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?',
                        style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: AppTextStyles.titleSmall),
                    if (review.userUniversity != null)
                      Text(
                        review.userUniversity!,
                        style: AppTextStyles.labelSmall,
                      ),
                  ],
                ),
              ),
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.ratingColor(review.rating)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: AppColors.ratingColor(review.rating),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.ratingColor(review.rating),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Yorum metni
          Text(
            review.comment,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Zaman
          Text(
            '${review.createdAt.day}.${review.createdAt.month}.${review.createdAt.year}',
            style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

