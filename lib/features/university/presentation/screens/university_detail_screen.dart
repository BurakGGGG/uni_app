import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import '../providers/university_providers.dart';
import '../../domain/models/university_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

import '../../../reviews/presentation/providers/review_providers.dart';
import '../../../reviews/domain/models/review_model.dart';
import '../../../reviews/presentation/widgets/review_card.dart';



import '../../domain/models/department_model.dart';

import '../widgets/uni_hero.dart';
import '../widgets/uni_info_strip.dart';
import '../widgets/uni_section.dart';

class UniversityDetailScreen extends ConsumerWidget {
  final String universityId;
  const UniversityDetailScreen({super.key, required this.universityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uniAsync = ref.watch(universityDetailProvider(universityId));
    
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: uniAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(AppLocalizations.of(context).errorGeneral(e.toString()))),
        data: (uni) {
          if (uni == null) {
            return Center(child: Text(AppLocalizations.of(context).universityNotFound));
          }
          return _Body(uni: uni);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final UniversityModel uni;
  const _Body({required this.uni});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(departmentsByUniversityProvider(uni.id));

    final reviewsAsync = ref.watch(sortedReviewsProvider(
      SortedReviewsParams(targetId: uni.id, type: ReviewType.university),
    ));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(universityDetailProvider(uni.id));
        ref.invalidate(departmentsByUniversityProvider(uni.id));

      },
      child: CustomScrollView(
        slivers: [
          UniHero(uni: uni),
          SliverPersistentHeader(
            pinned: false,
            delegate: _InfoStripDelegate(
              establishedYear: uni.establishedYear,
              departmentCount: deptsAsync.value?.length ?? 0,
              reviewCount: uni.reviewCount,
              avgRating: uni.avgRating,
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                // Action Butonları
                _ActionButtons(uni: uni),
                
                const SizedBox(height: 16),
                
                // Bölümler section
                UniSection(
                  title: 'Bölümler',
                  subtitle: '${deptsAsync.value?.length ?? 0} bölüm — En çok aranan 3 tanesi',
                  ctaText: 'Tüm bölümleri gör',
                  onCtaTap: () => context.push('/university/${uni.id}/departments'),
                  child: _DepartmentsPreview(deptsAsync: deptsAsync),
                ),
                
                // Mekanlar section (Yakında)
                UniSection(
                  title: 'Mekanlar',
                  subtitle: 'Yakında sizlerin önerileriyle!',
                  child: _PlacesComingSoon(),
                ),
                
                // Yorumlar section
                UniSection(
                  title: 'Yorumlar',
                  subtitle: uni.reviewCount > 0 
                    ? '${uni.reviewCount} yorum — En çok beğenilen 3 tanesi'
                    : 'Henüz yorum yok',
                  ctaText: 'Tüm yorumları gör',
                  onCtaTap: () => context.push('/university/${uni.id}/reviews'),
                  child: _ReviewsPreview(reviewsAsync: reviewsAsync),
                ),
                
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Yardımcı Widgetlar ─────────────────────────────
class _InfoStripDelegate extends SliverPersistentHeaderDelegate {
  final int establishedYear;
  final int departmentCount;
  final int reviewCount;
  final double avgRating;
  
  _InfoStripDelegate({
    required this.establishedYear,
    required this.departmentCount,
    required this.reviewCount,
    required this.avgRating,
  });

  @override
  double get minExtent => 108;
  @override
  double get maxExtent => 108;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.backgroundFor(context),
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 16),
      child: UniInfoStrip(
        establishedYear: establishedYear,
        departmentCount: departmentCount,
        reviewCount: reviewCount,
        avgRating: avgRating,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _InfoStripDelegate oldDelegate) {
    return establishedYear != oldDelegate.establishedYear ||
           departmentCount != oldDelegate.departmentCount ||
           reviewCount != oldDelegate.reviewCount ||
           avgRating != oldDelegate.avgRating;
  }
}

class _ActionButtons extends ConsumerWidget {
  final UniversityModel uni;
  const _ActionButtons({required this.uni});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isEduUser = user != null && (user.email?.endsWith('.edu.tr') ?? false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchUrl('https://maps.google.com/?q=${Uri.encodeComponent(uni.name)}'),
                  icon: const Icon(Icons.map_rounded, size: 20),
                  label: const Text('Haritada Aç'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/university/${uni.id}/gallery'),
                  icon: const Icon(Icons.photo_library_rounded, size: 20),
                  label: const Text('Galeri'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/university/${uni.id}/ratings'),
            icon: const Icon(Icons.analytics_rounded, size: 20),
            label: const Text('Kategori Puanları'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              if (!isEduUser) {
                _showReviewInfoSheet(context, user: user);
                return;
              }
              context.push('/write-review/university/${uni.id}');
            },
            icon: const Icon(Icons.rate_review_rounded, size: 20),
            label: const Text('Üniversiteyi Değerlendir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEduUser ? AppColors.primary : AppColors.surfaceVariant,
              foregroundColor: isEduUser ? Colors.white : AppColors.textTertiaryFor(context),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentsPreview extends StatelessWidget {
  final AsyncValue<List<DepartmentModel>> deptsAsync;
  const _DepartmentsPreview({required this.deptsAsync});

  @override
  Widget build(BuildContext context) {
    return deptsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Text(AppLocalizations.of(context).errorDepartmentsLoad),
      data: (depts) {
        if (depts.isEmpty) return Text(AppLocalizations.of(context).noDepartmentsFound, style: TextStyle(color: AppColors.textSecondaryFor(context)));
        
        final previewDepts = depts.take(3).toList();
        return Column(
          children: previewDepts.map((d) => 
            GestureDetector(
              onTap: () => context.push('/department/${d.id}'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLightFor(context)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(d.name, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiaryFor(context)),
                  ],
                ),
              ),
            )
          ).toList(),
        );
      },
    );
  }
}

class _PlacesComingSoon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.coffee_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Kafeler Yakında!',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu bölüme yakında kafeler ve mekanlar eklenecek.\nSizlerin önerileriyle bu listeyi oluşturacağız! 🎉',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryFor(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsPreview extends StatelessWidget {
  final AsyncValue<List<ReviewModel>> reviewsAsync;
  const _ReviewsPreview({required this.reviewsAsync});

  @override
  Widget build(BuildContext context) {
    return reviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Text(AppLocalizations.of(context).errorReviewsLoad),
      data: (reviews) {
        if (reviews.isEmpty) return const SizedBox();
        
        final sortedReviews = List.from(reviews)
          ..sort((a, b) => b.likes.compareTo(a.likes));
        final previewReviews = sortedReviews.take(3).toList();
        return Column(
          children: previewReviews.map((r) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ReviewCard(review: r),
            )
          ).toList(),
        );
      },
    );
  }
}

Future<void> _launchUrl(String urlString) async {
  final url = Uri.parse(urlString);
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

void _showReviewInfoSheet(BuildContext context, {required dynamic user}) {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  if (user == null) {
    icon = Icons.login_rounded;
    iconColor = AppColors.primary;
    title = AppLocalizations.of(context).authSignIn;
    description = AppLocalizations.of(context).reviewLoginRequired;
    buttonText = AppLocalizations.of(context).authSignIn;
    onButtonPressed = () {
      Navigator.pop(context);
      GoRouter.of(context).push('/login');
    };
  } else {
    icon = Icons.verified_user_rounded;
    iconColor = AppColors.warning;
    title = AppLocalizations.of(context).reviewEduRequiredTitle;
    description = AppLocalizations.of(context).reviewEduRequiredDesc;
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
                color: AppColors.textSecondaryFor(context),
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
