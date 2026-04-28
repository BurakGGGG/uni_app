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
import '../../../reviews/presentation/widgets/review_list.dart';
import '../../../reviews/domain/models/review_model.dart';
import '../../../reviews/presentation/widgets/category_ratings_chart.dart';
import '../../../places/presentation/widgets/place_list.dart';

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

          final deptCount = deptsAsync.value?.length ?? 0;

          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildSliverAppBar(context, uni),
                SliverToBoxAdapter(child: _buildCompactInfoCard(context, ref, uni)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textTertiary,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelStyle: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                      unselectedLabelStyle: AppTextStyles.titleSmall,
                      tabs: [
                        Tab(text: 'Bölümler${deptCount > 0 ? " ($deptCount)" : ""}'),
                        const Tab(text: 'Mekanlar'),
                        Tab(text: 'Yorumlar${uni.reviewCount > 0 ? " (${uni.reviewCount})" : ""}'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _DepartmentsTab(deptsAsync: deptsAsync),
                  _PlacesTab(universityId: universityId),
                  _ReviewsTab(universityId: universityId, uni: uni),
                ],
              ),
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
          // Rozetler ve rating yan yana
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

          // Açıklama (max 2 satır)
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

          // Meta info (kuruluş + website)
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Sticky TabBar Delegate ───────────────────────────────────────
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: Material(
        color: AppColors.background,
        elevation: overlapsContent ? 2 : 0,
        child: tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

// ─── Bölümler Tab ─────────────────────────────────────────────────
class _DepartmentsTab extends StatelessWidget {
  final AsyncValue<List<DepartmentModel>> deptsAsync;

  const _DepartmentsTab({required this.deptsAsync});

  @override
  Widget build(BuildContext context) {
    return deptsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Bölümler yüklenemedi: $e')),
      data: (departments) {
        if (departments.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('Henüz bölüm eklenmemiş'),
            ),
          );
        }

        final lisans = departments.where((d) => d.type == 'Lisans').toList();
        final onlisans = departments.where((d) => d.type == 'Önlisans').toList();

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            if (lisans.isNotEmpty) ...[
              _SectionTitle(title: 'Lisans (${lisans.length})'),
              ...lisans.asMap().entries.map((e) => _DepartmentCard(
                department: e.value,
                index: e.key,
                onTap: () => context.push('/department/${e.value.id}'),
              )),
            ],
            if (onlisans.isNotEmpty) ...[
              _SectionTitle(title: 'Önlisans (${onlisans.length})'),
              ...onlisans.asMap().entries.map((e) => _DepartmentCard(
                department: e.value,
                index: e.key + lisans.length,
                onTap: () => context.push('/department/${e.value.id}'),
              )),
            ],
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }
}

// ─── Mekanlar Tab ─────────────────────────────────────────────────
class _PlacesTab extends StatelessWidget {
  final String universityId;

  const _PlacesTab({required this.universityId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      children: [
        PlaceList(
          universityId: universityId,
          showTypeFilter: true,
          shrinkWrap: true,
        ),
      ],
    );
  }
}

// ─── Yorumlar Tab ─────────────────────────────────────────────────
class _ReviewsTab extends ConsumerWidget {
  final String universityId;
  final UniversityModel uni;

  const _ReviewsTab({required this.universityId, required this.uni});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // Kategori puanları özeti
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: CategoryRatingsChart(
            ratings: uni.categoryRatings,
            reviewCount: uni.reviewCount,
          ),
        ),

        // Değerlendir butonu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Consumer(
            builder: (context, ref, _) {
              final currentUserAsync = ref.watch(currentUserProvider);
              return currentUserAsync.when(
                data: (profile) {
                  final canReview = profile != null &&
                      profile.universityId == universityId &&
                      profile.isVerifiedStudent;

                  return SizedBox(
                    width: double.infinity,
                    child: canReview
                      ? ElevatedButton.icon(
                          onPressed: () => context.push('/write-review/university/$universityId'),
                          icon: const Icon(Icons.add_comment_rounded, size: 18),
                          label: const Text('Bu Üniversiteyi Değerlendir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => _showReviewInfoSheet(
                            context,
                            profile: profile,
                            isOwnUniversity: profile?.universityId == universityId,
                          ),
                          icon: const Icon(Icons.info_outline_rounded, size: 18),
                          label: const Text('Neden değerlendiremiyorum?'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: AppColors.borderLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                            ),
                          ),
                        ),
                  );
                },
                loading: () => const SizedBox(height: 48),
                error: (err, stack) => const SizedBox.shrink(),
              );
            },
          ),
        ),

        // Yorum listesi
        ReviewList(
          targetId: universityId,
          type: ReviewType.university,
        ),
      ],
    );
  }
}

// ─── Section Title (mevcut) ───────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(title, style: AppTextStyles.labelMedium.copyWith(
        color: AppColors.textTertiary, fontWeight: FontWeight.w600,
      )),
    );
  }
}

// ─── Badge (icon parametresi eklendi) ─────────────────────────────
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

// ─── Department Card (mevcut, aynı kalıyor) ──────────────────────
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: (department.type == 'Lisans' ? AppColors.primary : AppColors.accent)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  department.type == 'Lisans' ? Icons.school_rounded : Icons.auto_stories_rounded,
                  color: department.type == 'Lisans' ? AppColors.primary : AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(department.name, style: AppTextStyles.titleSmall,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${department.faculty} • ${department.language}',
                    style: AppTextStyles.labelSmall,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )),
              if (department.baseScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(department.baseScore!.toStringAsFixed(1),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Favorite Button (mevcut, aynı kalıyor) ──────────────────────
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

// ─── Değerlendir Bilgi Bottom Sheet ──────────────────────────────────
void _showReviewInfoSheet(
  BuildContext context, {
  required dynamic profile,
  required bool isOwnUniversity,
}) {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  if (profile == null) {
    icon = Icons.login_rounded;
    iconColor = AppColors.primary;
    title = 'Giriş Yapın';
    description = 'Yorum yazabilmek için önce hesabınıza giriş yapmanız gerekiyor.';
    buttonText = 'Giriş Yap';
    onButtonPressed = () {
      Navigator.pop(context);
      GoRouter.of(context).push('/login');
    };
  } else if (!(profile.isVerifiedStudent as bool)) {
    icon = Icons.verified_user_rounded;
    iconColor = AppColors.warning;
    title = 'Doğrulama Gerekli';
    description = 'Yorum yazabilmek için edu.tr uzantılı e-posta adresinizle doğrulama yapmanız gerekiyor.';
    buttonText = null;
    onButtonPressed = null;
  } else if (!isOwnUniversity) {
    icon = Icons.school_rounded;
    iconColor = AppColors.info;
    title = 'Farklı Üniversite';
    description = 'Sadece kendi üniversitene yorum yapabilirsin. Bu üniversite senin kayıtlı olduğun üniversite değil.';
    buttonText = null;
    onButtonPressed = null;
  } else {
    // Bu duruma normalde düşmemeli ama güvenlik için
    icon = Icons.info_outline_rounded;
    iconColor = AppColors.textTertiary;
    title = 'Yorum Yazılamıyor';
    description = 'Şu anda bu üniversiteye yorum yazma yetkiniz bulunmuyor.';
    buttonText = null;
    onButtonPressed = null;
  }

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (buttonText != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    ),
                  ),
                  child: Text(buttonText),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
