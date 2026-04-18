import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../providers/favorites_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Favoriler', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: user == null ? _buildUnauthenticatedState(context) : _buildFavoritesList(context, ref),
    );
  }

  Widget _buildUnauthenticatedState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Giriş Yapmalısın',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Favori üniversitelerini kaydetmek için giriş yapmalısın.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: GradientButton(
              text: 'Giriş Yap / Kayıt Ol',
              onPressed: () => context.push('/login'),
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildFavoritesList(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final allUnisAsync = ref.watch(allUniversitiesProvider);

    return favoritesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Hata: $e')),
      data: (favoriteIds) {
        if (favoriteIds.isEmpty) {
          return const Center(
            child: EmptyStateWidget(
              icon: Icons.favorite_border_rounded,
              title: 'Henüz favorin yok',
              description: 'İlgilendiğin üniversiteleri favorilerine ekleyerek buradan kolayca takip edebilirsin.',
            ),
          ).animate().fadeIn();
        }

        return allUnisAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Hata: $e')),
          data: (allUnis) {
            // Favori ID'lerine göre üniversiteleri filtrele
            final favoriteUnis = allUnis.where((uni) => favoriteIds.contains(uni.id)).toList();

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: favoriteUnis.length,
              itemBuilder: (context, index) {
                final uni = favoriteUnis[index];
                return Stack(
                  children: [
                    UniCard(
                      title: uni.name,
                      subtitle: '${uni.type} • Kuruluş: ${uni.establishedYear}',
                      rating: uni.avgRating,
                      reviewCount: uni.reviewCount,
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
                      delay: Duration(milliseconds: 50 * index.clamp(0, 10)),
                      duration: 300.ms,
                    ),
                    
                    // Kaldır Butonu (Sağ üst köşe)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: AppColors.softShadow,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.favorite_rounded, color: AppColors.error, size: 20),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final user = ref.read(authStateProvider).value;
                            if (user != null) {
                              ref.read(favoritesControllerProvider.notifier).toggleFavorite(user.uid, uni.id, true);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
