import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/university_providers.dart';

class CityUniversitiesScreen extends ConsumerWidget {
  final String cityId;

  const CityUniversitiesScreen({super.key, required this.cityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cityAsync = ref.watch(cityDetailProvider(cityId));
    final unisAsync = ref.watch(universitiesByCityProvider(cityId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── Header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: cityAsync.when(
                data: (city) => Text(
                  city?.name ?? '',
                  style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.secondary,
                      AppColors.primary,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      const Icon(Icons.location_city_rounded, color: Colors.white, size: 40),
                      const SizedBox(height: 8),
                      cityAsync.when(
                        data: (city) => Text(
                          '${city?.appUniversityCount ?? 0} üniversite',
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── Üniversite Listesi ──────────────────────────────
          unisAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => SliverFillRemaining(
              child: Center(child: Text('Hata: $e')),
            ),
            data: (universities) {
              if (universities.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyStateWidget(
                    icon: Icons.school_outlined,
                    title: 'Üniversite bulunamadı',
                    description: 'Bu şehirde henüz üniversite eklenmemiş.',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final uni = universities[index];
                      return UniCard(
                        title: uni.name,
                        subtitle: '${uni.type} • Kuruluş: ${uni.establishedYear}',
                        rating: 0,
                        reviewCount: 0,
                        tags: [
                          if (uni.hasCampus) 'Kampüslü',
                          uni.type,
                        ],
                        onTap: () => context.push('/university/${uni.id}'),
                        badge: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (uni.type == 'Devlet' ? AppColors.stateUni : AppColors.foundationUni)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            uni.type,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: uni.type == 'Devlet' ? AppColors.stateUni : AppColors.foundationUni,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(
                        delay: Duration(milliseconds: 80 * index),
                        duration: 300.ms,
                      );
                    },
                    childCount: universities.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
