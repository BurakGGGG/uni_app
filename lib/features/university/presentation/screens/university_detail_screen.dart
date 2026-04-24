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
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../reviews/presentation/widgets/review_list.dart';
import '../../../reviews/domain/models/review_model.dart';
import '../../../reviews/presentation/widgets/category_ratings_chart.dart';

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

          return CustomScrollView(
            slivers: [
              // ─── Header ─────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
                actions: [
                  _FavoriteButton(universityId: universityId),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    uni.name,
                    style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                          AppColors.secondary,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Dekoratif daireler
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -20,
                          bottom: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        // İkon
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Bilgi Kartları ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tür & Kampüs rozetleri
                      Row(
                        children: [
                          _Badge(
                            text: uni.type,
                            color: uni.type == 'Devlet' ? AppColors.stateUni : AppColors.foundationUni,
                          ),
                          const SizedBox(width: 8),
                          _Badge(
                            text: uni.hasCampus ? 'Kampüslü' : 'Kampüssüz',
                            color: uni.hasCampus ? AppColors.success : AppColors.warning,
                          ),
                          const Spacer(),
                          Text(
                            'Kuruluş: ${uni.establishedYear}',
                            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ).animate().fadeIn(duration: 300.ms),

                      const SizedBox(height: 16),

                      // Açıklama
                      Text(
                        uni.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                      const SizedBox(height: 16),

                      // Web sitesi butonu
                      if (uni.website.isNotEmpty)
                        GestureDetector(
                          onTap: () => _launchUrl('https://${uni.website}'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.language_rounded, color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  uni.website,
                                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 14),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                      const SizedBox(height: 24),

                      // ─── Bölümler Başlığı ────────────────────────
                      Row(
                        children: [
                          const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text('Bölümler', style: AppTextStyles.headlineMedium),
                        ],
                      ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ─── Bölüm Listesi ──────────────────────────────────
              deptsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  )),
                ),
                error: (e, st) => SliverToBoxAdapter(
                  child: Center(child: Text('Bölümler yüklenemedi: $e')),
                ),
                data: (departments) {
                  if (departments.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('Henüz bölüm eklenmemiş'),
                      )),
                    );
                  }

                  // Lisans ve Önlisans ayır
                  final lisans = departments.where((d) => d.type == 'Lisans').toList();
                  final onlisans = departments.where((d) => d.type == 'Önlisans').toList();

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      // ─── Kategori Puanları ─────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: CategoryRatingsChart(
                          ratings: uni.categoryRatings,
                          reviewCount: uni.reviewCount,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (lisans.isNotEmpty) ...[
                        _SectionTitle(title: 'Lisans (${lisans.length})'),
                        ...lisans.asMap().entries.map((entry) =>
                          _DepartmentCard(
                            department: entry.value,
                            index: entry.key,
                            onTap: () => context.push('/department/${entry.value.id}'),
                          ),
                        ),
                      ],
                      if (onlisans.isNotEmpty) ...[
                        _SectionTitle(title: 'Önlisans (${onlisans.length})'),
                        ...onlisans.asMap().entries.map((entry) =>
                          _DepartmentCard(
                            department: entry.value,
                            index: entry.key + lisans.length,
                            onTap: () => context.push('/department/${entry.value.id}'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      
                      // ─── Yorumlar Başlığı ve Butonu ────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.rate_review_rounded, color: AppColors.primary, size: 22),
                                const SizedBox(width: 8),
                                Text('Yorumlar', style: AppTextStyles.headlineMedium),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () => context.push('/write-review/university/$universityId'),
                              icon: const Icon(Icons.add_comment_rounded, size: 18),
                              label: const Text('Değerlendir'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // ─── Yorum Listesi (ReviewList widget) ─────────
                      ReviewList(
                        targetId: universityId,
                        type: ReviewType.university,
                      ),
                      
                      const SizedBox(height: 100),
                    ]),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Badge Widget ─────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Department Card ──────────────────────────────────────────────

class _DepartmentCard extends StatelessWidget {
  final DepartmentModel department;
  final int index;
  final VoidCallback onTap;

  const _DepartmentCard({
    required this.department,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // İkon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (department.type == 'Lisans'
                            ? AppColors.primary
                            : AppColors.accent)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    department.type == 'Lisans'
                        ? Icons.school_rounded
                        : Icons.auto_stories_rounded,
                    color: department.type == 'Lisans'
                        ? AppColors.primary
                        : AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Bilgi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        department.name,
                        style: AppTextStyles.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${department.faculty} • ${department.language}',
                        style: AppTextStyles.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Taban puan
                if (department.baseScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      department.baseScore!.toStringAsFixed(1),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Favorite Button ──────────────────────────────────────────────

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
              // Giriş yapmamış kullanıcıyı uyar ve yönlendir
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

            // Favoriye ekle/çıkar
            ref.read(favoritesControllerProvider.notifier).toggleFavorite(
              user.uid,
              universityId,
              isFavorite,
            );
          },
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? AppColors.error : Colors.white,
          ),
        );
      },
      loading: () => const IconButton(
        onPressed: null,
        icon: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
        ),
      ),
      error: (_, st) => const IconButton(
        onPressed: null,
        icon: Icon(Icons.favorite_border_rounded, color: Colors.white54),
      ),
    );
  }
}

