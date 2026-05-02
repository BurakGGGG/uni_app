import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/university_providers.dart';
import '../../domain/models/university_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../reviews/presentation/providers/review_providers.dart';
import '../../../reviews/presentation/widgets/review_card.dart';

class UniversityDetailScreen extends ConsumerWidget {
  final String universityId;

  const UniversityDetailScreen({super.key, required this.universityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uniAsync = ref.watch(universityDetailProvider(universityId));

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
              _buildSliverAppBar(context, uni),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildInfoCard(uni),
                    const SizedBox(height: 16),
                    _buildActionButtons(context, ref, uni),
                    const SizedBox(height: 24),
                    _buildGridMenu(context, uni),
                    const SizedBox(height: 24),
                    _buildTopReviews(context, ref, uni),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, UniversityModel uni) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
      actions: [_FavoriteButton(universityId: universityId, iconColor: Colors.white)],
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

  Widget _buildInfoCard(UniversityModel uni) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(text: uni.type, color: uni.type == 'Devlet' ? AppColors.stateUni : AppColors.foundationUni),
              const SizedBox(width: 8),
              _Badge(text: uni.campusLayout.label, color: AppColors.info, icon: uni.campusLayout.icon),
              const Spacer(),
              if (uni.reviewCount > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 18, color: AppColors.ratingColor(uni.avgRating)),
                    const SizedBox(width: 4),
                    Text(uni.avgRating.toStringAsFixed(1), style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.ratingColor(uni.avgRating))),
                    const SizedBox(width: 2),
                    Text('(${uni.reviewCount})', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (uni.description.isNotEmpty) ...[
            Text(
              uni.description,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text('Kuruluş ${uni.establishedYear}', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textTertiary)),
                ],
              ),
              if (uni.website.isNotEmpty)
                GestureDetector(
                  onTap: () => _launchUrl('https://${uni.website}'),
                  child: Row(
                    children: [
                      const Icon(Icons.language_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        uni.website,
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, UniversityModel uni) {
    final user = ref.watch(authStateProvider).value;
    final isEduUser = user != null && (user.email?.endsWith('.edu.tr') ?? false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _launchUrl('https://maps.google.com/?q=${Uri.encodeComponent(uni.name)}'),
              icon: const Icon(Icons.map_rounded, size: 20),
              label: const Text('Harita aç'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (!isEduUser) {
                  _showReviewInfoSheet(context, user: user);
                  return;
                }
                context.push('/write-review/university/${uni.id}');
              },
              icon: const Icon(Icons.rate_review_rounded, size: 20),
              label: const Text('Değerlendir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEduUser ? AppColors.primary : AppColors.surfaceVariant,
                foregroundColor: isEduUser ? Colors.white : AppColors.textTertiary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTopReviews(BuildContext context, WidgetRef ref, UniversityModel uni) {
    final reviewsAsync = ref.watch(universityReviewsProvider(uni.id));

    return reviewsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (reviews) {
        if (reviews.isEmpty) return const SizedBox.shrink();

        final sortedReviews = List.of(reviews)..sort((a, b) => b.likes.compareTo(a.likes));
        final topReviews = sortedReviews.take(3).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Öne Çıkan Yorumlar',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...topReviews.map((review) => ReviewCard(
                review: review,
                showActions: false,
                showReportMenu: false,
              )),
            ],
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
        );
      },
    );
  }

  Widget _buildGridMenu(BuildContext context, UniversityModel uni) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2.2, // Rectangular cards
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _GridMenuCard(
            title: 'Bölümler',
            icon: Icons.school_rounded,
            color: const Color(0xFF6C63FF),
            onTap: () => context.push('/university/${uni.id}/departments'),
          ),
          _GridMenuCard(
            title: 'Mekanlar',
            icon: Icons.place_rounded,
            color: const Color(0xFFFF6584),
            onTap: () => context.push('/university/${uni.id}/places'),
          ),
          _GridMenuCard(
            title: 'Yorumlar',
            icon: Icons.forum_rounded,
            color: const Color(0xFF43A047),
            onTap: () => context.push('/university/${uni.id}/reviews'),
          ),
          _GridMenuCard(
            title: 'Fotolar',
            icon: Icons.photo_library_rounded,
            color: const Color(0xFFFDD835),
            onTap: () => context.push('/university/${uni.id}/gallery'),
          ),
        ],
      ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
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

class _GridMenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GridMenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _Badge({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(text, style: AppTextStyles.labelSmall.copyWith(
            color: color, fontWeight: FontWeight.bold, fontSize: 11,
          )),
        ],
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  final String universityId;
  final Color iconColor;

  const _FavoriteButton({
    required this.universityId,
    required this.iconColor,
  });

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
            color: isFavorite ? AppColors.error : iconColor,
          ),
        );
      },
      loading: () => IconButton(
        onPressed: null,
        icon: SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: iconColor.withValues(alpha: 0.7))),
      ),
      error: (err, stack) => IconButton(
        onPressed: null,
        icon: Icon(Icons.favorite_border_rounded, color: iconColor.withValues(alpha: 0.5)),
      ),
    );
  }
}

// ─── Değerlendir Bilgi Bottom Sheet ─────────────────────────────
void _showReviewInfoSheet(
  BuildContext context, {
  required dynamic user,
}) {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  if (user == null) {
    icon = Icons.login_rounded;
    iconColor = AppColors.primary;
    title = 'Giriş Yapın';
    description = 'Yorum yazabilmek için önce hesabınıza giriş yapmanız gerekiyor.';
    buttonText = 'Giriş Yap';
    onButtonPressed = () {
      Navigator.pop(context);
      GoRouter.of(context).push('/login');
    };
  } else {
    icon = Icons.verified_user_rounded;
    iconColor = AppColors.warning;
    title = 'Doğrulama Gerekli';
    description = 'Sadece onaylı üniversite öğrencileri değerlendirme yapabilir (.edu.tr).';
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
                      borderRadius: BorderRadius.circular(12),
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
