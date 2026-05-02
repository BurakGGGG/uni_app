import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../../university/domain/models/university_model.dart';
import '../providers/favorites_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  /// Animasyonla çıkan kartları geçici olarak gizlemek için
  final Set<String> _removingIds = {};

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoriler'),
      ),
      body: user == null
          ? _buildUnauthenticatedState(context)
          : _buildFavoritesList(context, ref),
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
            style: AppTextStyles.titleMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Favori üniversitelerini kaydetmek için giriş yapmalısın.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textTertiary),
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
        // _removingIds dışındaki favorileri göster
        final visibleIds = favoriteIds
            .where((id) => !_removingIds.contains(id))
            .toList();

        if (visibleIds.isEmpty && _removingIds.isEmpty) {
          return _buildEmptyState(context);
        }

        return allUnisAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Hata: $e')),
          data: (allUnis) {
            final favoriteUnis = allUnis
                .where((uni) => visibleIds.contains(uni.id))
                .toList();

            return Column(
              children: [
                // ─── Üst bar: sayı + tümünü temizle ─────────────
                _buildTopBar(context, ref, favoriteUnis.length),
                // ─── Liste ──────────────────────────────────────
                Expanded(
                  child: favoriteUnis.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: favoriteUnis.length,
                          itemBuilder: (context, index) {
                            final uni = favoriteUnis[index];
                            return _FavoriteUniCard(
                              key: ValueKey('fav_${uni.id}'),
                              university: uni,
                              onRemove: () => _removeFavorite(ref, uni),
                              onTap: () =>
                                  context.push('/university/${uni.id}'),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count favori',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          if (count > 0)
            GestureDetector(
              onLongPress: () => _clearAllFavorites(ref),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.delete_sweep_outlined,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      'Tümünü temizle',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 48,
                color: AppColors.error.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz favorin yok',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'İlgilendiğin üniversiteleri favorilerine ekleyerek\nburadan kolayca takip edebilirsin.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 200,
              child: GradientButton(
                text: 'Keşfet\'e Git',
                icon: Icons.explore_rounded,
                onPressed: () => context.go('/explore'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeFavorite(WidgetRef ref, UniversityModel uni) {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    // Animasyon için hemen gizle
    setState(() => _removingIds.add(uni.id));

    // Favoriyi sil
    ref
        .read(favoritesControllerProvider.notifier)
        .toggleFavorite(user.uid, uni.id, true);

    // Undo snackbar
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${uni.name} favorilerden çıkarıldı',
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'GERİ AL',
          textColor: AppColors.primary,
          onPressed: () {
            // Geri ekle
            ref
                .read(favoritesControllerProvider.notifier)
                .toggleFavorite(user.uid, uni.id, false);
            setState(() => _removingIds.remove(uni.id));
          },
        ),
      ),
    );

    // Snackbar süresi bittiğinde _removingIds'den temizle
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _removingIds.remove(uni.id));
      }
    });
  }

  void _clearAllFavorites(WidgetRef ref) {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final favoriteIds = ref.read(favoritesProvider).value ?? [];

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tümünü Temizle'),
        content: Text(
            '${favoriteIds.length} favori üniversiteni silmek istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Tümünü Sil'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        for (final id in favoriteIds) {
          ref
              .read(favoritesControllerProvider.notifier)
              .toggleFavorite(user.uid, id, true);
        }
      }
    });
  }
}

// ─── Favori Üniversite Kartı ────────────────────────────────────────

class _FavoriteUniCard extends StatefulWidget {
  final UniversityModel university;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _FavoriteUniCard({
    super.key,
    required this.university,
    required this.onRemove,
    required this.onTap,
  });

  @override
  State<_FavoriteUniCard> createState() => _FavoriteUniCardState();
}

class _FavoriteUniCardState extends State<_FavoriteUniCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _sizeAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sizeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInBack),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleRemove() {
    _animController.forward().then((_) {
      widget.onRemove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final uni = widget.university;

    return SizeTransition(
      sizeFactor: _sizeAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Stack(
            children: [
              UniCard(
                title: uni.name,
                subtitle:
                    '${uni.type} • Kuruluş: ${uni.establishedYear}',
                rating: uni.avgRating,
                reviewCount: uni.reviewCount,
                tags: [
                  if (uni.hasCampus) 'Kampüslü',
                  uni.type,
                ],
                onTap: widget.onTap,
                badge: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (uni.type == 'Devlet'
                            ? AppColors.stateUni
                            : AppColors.foundationUni)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    uni.type,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: uni.type == 'Devlet'
                          ? AppColors.stateUni
                          : AppColors.foundationUni,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              // ─── Kalp butonu (sağ üst) ─────────────────────
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleRemove,
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
