import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';

import '../widgets/university_detail_skeleton.dart';

import '../providers/university_providers.dart';
import '../../domain/models/university_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

import '../../../reviews/presentation/providers/review_providers.dart';
import '../../../reviews/presentation/services/review_prompt_service.dart';
import '../../../reviews/presentation/utils/review_submission_guard.dart';
import '../../../reviews/domain/models/review_model.dart';
import '../../../reviews/presentation/widgets/review_card.dart';

import '../../../places/presentation/providers/place_providers.dart';
import '../../../places/domain/models/place_model.dart';
import '../../../places/presentation/widgets/place_card.dart';

import '../../../google_reviews/presentation/widgets/google_reviews_section.dart';

import '../../domain/models/department_model.dart';
import '../../../preference_wizard/presentation/widgets/feasibility_chip.dart';

import '../widgets/uni_hero.dart';
import '../widgets/uni_info_strip.dart';
import '../widgets/uni_section.dart';
import '../../../assistant/presentation/widgets/uni_university_fit.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/presentation/widgets/analytics_once_tracker.dart';
import '../../../../services/engagement_service.dart';
import '../../../../core/utils/responsive.dart';

class UniversityDetailScreen extends ConsumerWidget {
  final String universityId;
  const UniversityDetailScreen({super.key, required this.universityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uniAsync = ref.watch(universityDetailProvider(universityId));

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: uniAsync.when(
        loading: () => const UniversityDetailSkeleton(),
        error: (e, _) => ErrorStateWidget(
          message: AppLocalizations.of(context).errorGeneral(e.toString()),
          onRetry: () => ref.invalidate(universityDetailProvider(universityId)),
        ),
        data: (uni) {
          if (uni == null) {
            return Center(
              child: Text(AppLocalizations.of(context).universityNotFound),
            );
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
    final loc = AppLocalizations.of(context);
    final deptsAsync = ref.watch(departmentsByUniversityProvider(uni.id));

    final reviewsAsync = ref.watch(
      sortedReviewsProvider(
        SortedReviewsParams(targetId: uni.id, type: ReviewType.university),
      ),
    );

    final placesAsync = ref.watch(placesByUniversityProvider(uni.id));

    return AnalyticsOnceTracker(
      onTrack: () {
        AnalyticsService.instance.trackUniversityView(
          universityId: uni.id,
          universityName: uni.name,
        );
        EngagementService.instance.recordUniversityViewed(uni.id);
        // 3. ziyarette uygunsa "deneyimini paylaş" istemi — ekran otursun
        // diye kısa gecikmeli.
        Future.delayed(const Duration(seconds: 2), () {
          if (!context.mounted) return;
          ref
              .read(reviewPromptServiceProvider)
              .recordVisitAndMaybePrompt(context, ref, uni);
        });
      },
      child: RefreshIndicator(
        onRefresh: () async {
          ref.read(placeRepositoryProvider).clearCache();
          ref.invalidate(universityDetailProvider(uni.id));
          ref.invalidate(departmentsByUniversityProvider(uni.id));
          ref.invalidate(placesByUniversityProvider(uni.id));
          await Future.wait<void>([
            ref.read(universityDetailProvider(uni.id).future).then((_) {}),
            ref
                .read(departmentsByUniversityProvider(uni.id).future)
                .then((_) {}),
            ref.read(placesByUniversityProvider(uni.id).future).then((_) {}),
          ]);
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

                  // Üni'nin uygunluk özeti — "Bölümler"in hemen üstünde,
                  // keşiften tercihe köprü. Kendi kapısı var: susması
                  // gerektiğinde hiç çizilmez.
                  UniUniversityFit(
                    universityId: uni.id,
                    departments: deptsAsync.value ?? const [],
                  ),

                  // Bölümler section
                  UniSection(
                    title: loc.uniDetailDepartments,
                    subtitle: loc.uniDetailDepartmentsSubtitle(
                      deptsAsync.value?.length ?? 0,
                    ),
                    ctaText: loc.uniDetailSeeAllDepartments,
                    onCtaTap: () =>
                        context.push('/university/${uni.id}/departments'),
                    child: _DepartmentsPreview(
                      deptsAsync: deptsAsync,
                      onRetry: () => ref.invalidate(
                        departmentsByUniversityProvider(uni.id),
                      ),
                    ),
                  ),

                  // Mekanlar section
                  _PlacesSection(
                    uni: uni,
                    placesAsync: placesAsync,
                    onRetry: () =>
                        ref.invalidate(placesByUniversityProvider(uni.id)),
                  ),

                  // Yorumlar section
                  UniSection(
                    title: loc.uniDetailReviews,
                    // Yerel yorum yoksa "Henüz yorum yok" gösterme —
                    // altındaki Google Yorumları bölümü kendini anlatır.
                    subtitle: uni.reviewCount > 0
                        ? loc.uniDetailReviewsSubtitle(uni.reviewCount)
                        : null,
                    // Yorum yoksa CTA'yı ilk yorum yazma davetine çevir
                    // (first_review rozet hunisi).
                    ctaText: uni.reviewCount > 0
                        ? loc.uniDetailSeeAllReviews
                        : loc.uniDetailWriteFirstReview,
                    onCtaTap: uni.reviewCount > 0
                        ? () => context.push('/university/${uni.id}/reviews')
                        : () => _startFirstReview(context, ref, uni),
                    child: _ReviewsPreview(
                      reviewsAsync: reviewsAsync,
                      onRetry: () => ref.invalidate(
                        sortedReviewsProvider(
                          SortedReviewsParams(
                            targetId: uni.id,
                            type: ReviewType.university,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Google yorumları (canlı, saklanmaz — kota dolunca gizlenir)
                  GoogleReviewsSection(uni: uni),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
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
    final loc = AppLocalizations.of(context);
    final user = ref.watch(authStateProvider).value;
    final isEduUser =
        user != null && (user.email?.endsWith('.edu.tr') ?? false);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context), vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchUrl(
                    'https://maps.google.com/?q=${Uri.encodeComponent(uni.name)}',
                  ),
                  icon: const Icon(Icons.map_rounded, size: 20),
                  label: Text(loc.uniDetailOpenMap),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/university/${uni.id}/gallery'),
                  icon: const Icon(Icons.photo_library_rounded, size: 20),
                  label: Text(loc.uniDetailGallery),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/university/${uni.id}/ratings'),
            icon: const Icon(Icons.analytics_rounded, size: 20),
            label: Text(loc.uniDetailCategoryRatings),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
              openWriteReviewIfAllowed(
                context: context,
                ref: ref,
                type: ReviewType.university,
                targetId: uni.id,
                universityId: uni.id,
              );
            },
            icon: const Icon(Icons.rate_review_rounded, size: 20),
            label: Text(loc.uniDetailRateUniversity),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEduUser
                  ? AppColors.primary
                  : AppColors.surfaceVariantFor(context),
              foregroundColor: isEduUser
                  ? Colors.white
                  : AppColors.textTertiaryFor(context),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
  final VoidCallback? onRetry;
  const _DepartmentsPreview({required this.deptsAsync, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return deptsAsync.when(
      loading: () => const DepartmentsSkeleton(),
      error: (error, stackTrace) => ErrorStateWidget(
        message: AppLocalizations.of(context).errorDepartmentsLoad,
        onRetry: onRetry,
        compact: true,
      ),
      data: (depts) {
        if (depts.isEmpty) {
          return Text(
            AppLocalizations.of(context).noDepartmentsFound,
            style: TextStyle(color: AppColors.textSecondaryFor(context)),
          );
        }

        final previewDepts = depts.take(3).toList();
        return Column(
          children: previewDepts
              .map(
                (d) => GestureDetector(
                  onTap: () => context.push('/department/${d.id}'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceFor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.borderLightFor(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            d.name,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        FeasibilityChip.forDepartment(d, compact: true),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.textTertiaryFor(context),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _PlacesSection extends StatelessWidget {
  final UniversityModel uni;
  final AsyncValue<List<PlaceModel>> placesAsync;
  final VoidCallback? onRetry;
  const _PlacesSection({
    required this.uni,
    required this.placesAsync,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return placesAsync.when(
      loading: () => UniSection(
        title: loc.uniDetailPlaces,
        subtitle: loc.uniDetailPlacesLoading,
        child: const PlacesSkeleton(),
      ),
      error: (e, _) => UniSection(
        title: loc.uniDetailPlaces,
        subtitle: loc.uniDetailPlacesLoadError,
        child: ErrorStateWidget(
          message: loc.errorPlacesLoad,
          onRetry: onRetry,
          compact: true,
        ),
      ),
      data: (places) {
        if (places.isEmpty) {
          return UniSection(
            title: loc.uniDetailPlaces,
            subtitle: loc.uniDetailPlacesComingSoon,
            child: _PlacesEmptyState(uni: uni),
          );
        }

        final preview = places.take(3).toList();
        return UniSection(
          title: loc.uniDetailPlaces,
          subtitle: loc.uniDetailPlacesSubtitle(places.length),
          ctaText: loc.uniDetailSeeAllPlaces,
          onCtaTap: () => context.push('/university/${uni.id}/places'),
          child: Column(
            children: [
              ...preview.map(
                (p) => PlaceCard(
                  place: p,
                  margin: const EdgeInsets.only(bottom: 8),
                  onTap: () => context.push('/place/${p.id}'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final encodedName = Uri.encodeComponent(uni.name);
                    context.push('/suggest-place?uniId=${uni.id}&uniName=$encodedName');
                  },
                  icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                  label: const Text('Yeni Mekan Öner'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlacesEmptyState extends StatelessWidget {
  final UniversityModel uni;
  const _PlacesEmptyState({required this.uni});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: Responsive.horizontalPadding(context)),
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
            child: const Icon(
              Icons.coffee_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.uniDetailPlacesEmptyTitle,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.uniDetailPlacesEmptyDesc,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryFor(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              final encodedName = Uri.encodeComponent(uni.name);
              context.push('/suggest-place?uniId=${uni.id}&uniName=$encodedName');
            },
            icon: const Icon(Icons.add_location_alt_rounded, size: 18),
            label: const Text('Mekan Öner'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsPreview extends StatelessWidget {
  final AsyncValue<List<ReviewModel>> reviewsAsync;
  final VoidCallback? onRetry;
  const _ReviewsPreview({required this.reviewsAsync, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return reviewsAsync.when(
      loading: () => const ReviewsSkeleton(),
      error: (error, stackTrace) => ErrorStateWidget(
        message: AppLocalizations.of(context).errorReviewsLoad,
        onRetry: onRetry,
        compact: true,
      ),
      data: (reviews) {
        if (reviews.isEmpty) return const SizedBox();

        final sortedReviews = List.from(reviews)
          ..sort((a, b) => b.likes.compareTo(a.likes));
        final previewReviews = sortedReviews.take(3).toList();
        return Column(
          children: previewReviews
              .map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ReviewCard(review: r),
                ),
              )
              .toList(),
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

/// "İlk yorumu sen yaz" CTA'sı — _ActionButtons'takiyle aynı edu.tr gating'i.
void _startFirstReview(
  BuildContext context,
  WidgetRef ref,
  UniversityModel uni,
) {
  final user = ref.read(authStateProvider).value;
  final isEduUser =
      user != null && (user.email?.endsWith('.edu.tr') ?? false);
  if (!isEduUser) {
    _showReviewInfoSheet(context, user: user);
    return;
  }
  openWriteReviewIfAllowed(
    context: context,
    ref: ref,
    type: ReviewType.university,
    targetId: uni.id,
    universityId: uni.id,
  );
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
                color: AppColors.textTertiary.withValues(alpha: 0.31),
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
