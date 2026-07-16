import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/domain/user_model.dart';
import '../../../reviews/presentation/providers/review_providers.dart';
import '../../../reviews/presentation/widgets/review_card.dart';
import '../../../reviews/domain/models/review_model.dart';
import '../providers/public_profile_provider.dart';

/// Başka bir kullanıcının herkese açık profil ekranı.
/// Route: /user/:userId
class PublicProfileScreen extends ConsumerWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: profileAsync.when(
        loading: () => const ShimmerList(itemCount: 4),
        error: (e, _) => ErrorStateWidget(message: 'Profil yüklenemedi: $e'),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: EmptyStateWidget(
                icon: Icons.person_off_outlined,
                title: 'Kullanıcı bulunamadı',
                description:
                    'Bu kullanıcı artık mevcut değil veya hesabını silmiş olabilir.',
              ),
            );
          }
          return _ProfileContent(profile: profile, userId: userId);
        },
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  final UserModel profile;
  final String userId;
  const _ProfileContent({required this.profile, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(userPublicReviewsProvider(userId));

    // Anonim yorumları gösterme (privacy) — onay filtresi sorguda uygulanır
    final approvedReviews = reviewsAsync.valueOrNull
            ?.where((r) => !r.isAnonymous)
            .toList() ??
        [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // ─── Avatar + İsim Kartı ──────────────────────────────
          _buildProfileCard(context),

          const SizedBox(height: 24),

          // ─── İstatistikler ────────────────────────────────────
          _buildStatsRow(),

          const SizedBox(height: 24),

          // ─── Yorumlar ─────────────────────────────────────────
          _buildReviewsSection(context, ref, reviewsAsync, approvedReviews),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: AppColors.softShadowFor(context),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: profile.photoUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: profile.photoUrl!,
                      fit: BoxFit.cover,
                      width: 88,
                      height: 88,
                      memCacheWidth: 176,
                      memCacheHeight: 176,
                      placeholder: (context, url) => Center(
                        child: Text(
                          profile.initials,
                          style: AppTextStyles.displaySmall
                              .copyWith(color: Colors.white),
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          profile.initials,
                          style: AppTextStyles.displaySmall
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      profile.initials,
                      style: AppTextStyles.displaySmall
                          .copyWith(color: Colors.white),
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          // İsim
          Text(profile.displayName, style: AppTextStyles.headlineMedium),

          const SizedBox(height: 6),

          // Doğrulanmış öğrenci rozeti
          if (profile.isVerifiedStudent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded,
                      color: AppColors.success, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Doğrulanmış Öğrenci',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Üniversite + Bölüm + Sınıf
          if (profile.university != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_rounded,
                    size: 14, color: AppColors.textTertiaryFor(context)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    profile.university!,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondaryFor(context)),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          if (profile.department != null)
            Text(
              profile.department!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textTertiaryFor(context)),
              textAlign: TextAlign.center,
            ),
          if (profile.grade != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _gradeLabel(profile.grade!),
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textTertiaryFor(context)),
              ),
            ),

          // Üniversitesini görüntüle butonu
          if (profile.universityId != null && profile.universityId!.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 32,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/university/${profile.universityId}'),
                icon: const Icon(Icons.school_outlined, size: 14),
                label: const Text('Üniversitesini Görüntüle'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
                  side: const BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
            ),
          ],

          // Bio
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantFor(context),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              child: Text(
                profile.bio!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondaryFor(context)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.rate_review_rounded,
            label: 'Yorum',
            value: '${profile.reviewCount}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_month_rounded,
            label: 'Üye',
            value: _memberSince(profile.createdAt),
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue asyncReviews,
    List approvedReviews,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Yorumları', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        if (asyncReviews.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (approvedReviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariantFor(context),
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 40, color: AppColors.textTertiary.withValues(alpha: 0.5)),
                const SizedBox(height: 8),
                Text(
                  'Henüz yorum yapmamış',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textTertiaryFor(context)),
                ),
              ],
            ),
          )
        else
          ...approvedReviews.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ReviewCard(
                review: r,
                showTargetInfo: true,
                showActions: false,
                showReportMenu: false,
                compact: true,
                onTap: () {
                  switch (r.type) {
                    case ReviewType.university:
                      context.push('/university/${r.targetId}');
                      break;
                    case ReviewType.department:
                      context.push('/department/${r.targetId}');
                      break;
                    case ReviewType.place:
                      context.push('/place/${r.targetId}');
                      break;
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  String _gradeLabel(int grade) {
    const labels = {
      0: 'Hazırlık',
      1: '1. Sınıf',
      2: '2. Sınıf',
      3: '3. Sınıf',
      4: '4. Sınıf',
      5: '5. Sınıf+',
      6: 'Mezun',
    };
    return labels[grade] ?? '';
  }

  String _memberSince(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays < 30) return '${diff.inDays} gün';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} ay';
    return '${(diff.inDays / 365).floor()} yıl';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textTertiaryFor(context)),
          ),
        ],
      ),
    );
  }
}
