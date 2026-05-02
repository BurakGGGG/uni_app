import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
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
      appBar: AppBar(
        title: const Text('Favoriler'),
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
      ),
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
          );
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
                return Dismissible(
                  key: ValueKey('fav_${uni.id}'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Favorilerden Çıkar?'),
                        content: Text('${uni.name}\nfavorilerinden çıkarılacak. Emin misin?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('İptal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                            child: const Text('Çıkar'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) {
                    final user = ref.read(authStateProvider).value;
                    if (user != null) {
                      ref.read(favoritesControllerProvider.notifier)
                         .toggleFavorite(user.uid, uni.id, true);
                    }
                  },
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: UniCard(
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
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
