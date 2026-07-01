import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import '../../../../l10n/generated/app_localizations.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/widgets/app_showcase_tooltip.dart';
import '../../../../core/services/feature_discovery_service.dart';
import '../../../university/presentation/providers/university_providers.dart';

import '../../../university/domain/models/university_model.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../reviews/presentation/providers/review_providers.dart';
import '../../../reviews/presentation/widgets/review_card.dart';
import '../../../reviews/domain/models/review_model.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../university/presentation/widgets/city_card.dart';
import '../../../stories/presentation/widgets/story_bubble_carousel.dart';
import '../widgets/home_list_skeleton.dart';
import '../../../../core/utils/haptic.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Ana Sayfa ekranı
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeStartShowcase();
    });
  }

  void _maybeStartShowcase() {
    if (!mounted) return;
    final fd = ref.read(featureDiscoveryProvider);
    if (!fd.isCompleted(FeatureDiscoveryService.homeCompleted)) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        ShowcaseView.getNamed('app_tour').startShowCase([
          AppTourKeys.search,
          AppTourKeys.story,
          AppTourKeys.hero,
          AppTourKeys.notification,
          AppTourKeys.exploreTab,
          AppTourKeys.compareTab,
          AppTourKeys.listsTab,
        ]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final citiesAsync = ref.watch(citiesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ─── Header ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppWordmark(fontSize: 28),
                        // Bildirim ikonu — Showcase Adım 4
                        Showcase.withWidget(
                          key: AppTourKeys.notification,
                          scope: 'app_tour',
                          disableMovingAnimation: true,
                          targetBorderRadius: BorderRadius.circular(12),
                          targetPadding: const EdgeInsets.all(4),
                          container: const AppShowcaseTooltip(
                            title: 'Bildirimler',
                            description:
                                'Yeni duyurular, güncellemeler ve sana özel bildirimleri takip et.',
                            currentStep: 4,
                            totalSteps: 7,
                          ),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceFor(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.borderLightFor(context),
                              ),
                            ),
                            child: const NotificationBell(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── Arama Çubuğu — Showcase Adım 1 ────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Showcase.withWidget(
                  key: AppTourKeys.search,
                  scope: 'app_tour',
                  disableMovingAnimation: true,
                  targetBorderRadius: BorderRadius.circular(16),
                  targetPadding: const EdgeInsets.all(4),
                  container: AppShowcaseTooltip(
                    title: loc.showcaseSearchTitle,
                    description: loc.showcaseSearchDescription,
                    currentStep: 1,
                    totalSteps: 7,
                  ),
                  child: AppSearchBar(
                    readOnly: true,
                    onTap: () {
                      context.push('/search');
                    },
                  ),
                ),
              ),
            ),

            // ─── Story Bubble Carousel — Showcase Adım 2 ──────
            SliverToBoxAdapter(
              child: Showcase.withWidget(
                key: AppTourKeys.story,
                scope: 'app_tour',
                disableMovingAnimation: true,
                targetBorderRadius: BorderRadius.circular(16),
                targetPadding: const EdgeInsets.all(4),
                container: const AppShowcaseTooltip(
                  title: 'Hikayeler',
                  description:
                      'Üniversitelerden güncel duyuruları ve hikayeleri burada gör.',
                  currentStep: 2,
                  totalSteps: 7,
                ),
                child: const StoryBubbleCarousel(),
              ),
            ),

            // ─── Hero Banner — Showcase Adım 2 ──────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Showcase.withWidget(
                  key: AppTourKeys.hero,
                  scope: 'app_tour',
                  disableMovingAnimation: true,
                  targetBorderRadius: BorderRadius.circular(24),
                  targetPadding: const EdgeInsets.all(4),
                  container: const AppShowcaseTooltip(
                    title: 'Puan Hesaplayıcı',
                    description:
                        'YKS puanını hesapla, sana uygun üniversite ve bölümleri keşfet.',
                    currentStep: 3,
                    totalSteps: 7,
                  ),
                  child: const _HeroBanner(),
                ),
              ),
            ),

            // ─── Popüler Üniversiteler ──────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SectionHeader(
                    title: loc.homePopularUniversities,
                    actionText: loc.homeSeeAll,
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
                    onAction: () => context.go('/explore'),
                  ),
                  SizedBox(
                    height: Responsive.cardListHeight(context),
                    child: ref
                        .watch(popularUniversitiesProvider)
                        .when(
                          loading: () => const HomeListSkeleton(),
                          error: (e, st) => ErrorStateWidget(
                            message: 'Üniversiteler yüklenemedi',
                            onRetry: () =>
                                ref.invalidate(popularUniversitiesProvider),
                            compact: true,
                          ),
                          data: (popular) {
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              scrollCacheExtent: ScrollCacheExtent.pixels(200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: popular.length,
                              itemBuilder: (context, index) {
                                return RepaintBoundary(
                                  child: AnimatedListItem(
                                    index: index,
                                    direction: Axis.horizontal,
                                    slideOffset: 40,
                                    staggerDelay: const Duration(
                                      milliseconds: 80,
                                    ),
                                    child: _PopularUniCard(
                                      university: popular[index],
                                      index: index,
                                      onTap: () => context.push(
                                        '/university/${popular[index].id}',
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),

            // ─── Şehirler ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SectionHeader(
                    title: loc.homeCities,
                    actionText: loc.homeSeeAll,
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                    onAction: () => context.push('/cities'),
                  ),
                  SizedBox(
                    height: 200,
                    child: citiesAsync.when(
                      loading: () => const HomeListSkeleton(),
                      error: (e, st) => ErrorStateWidget(
                        message: loc.homeCitiesLoadError,
                        onRetry: () => ref.invalidate(citiesProvider),
                        compact: true,
                      ),
                      data: (cities) {
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: cities.length,
                          itemBuilder: (context, index) {
                            return CityCard.compact(
                              city: cities[index],
                              onTap: () =>
                                  context.push('/city/${cities[index].id}'),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ─── Son Yorumlar ───────────────────────────────────────
            SliverToBoxAdapter(
              child: SectionHeader(
                title: loc.homeRecentReviews,
                actionText: loc.homeSeeAll,
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                onAction: () => context.push('/all-reviews'),
              ),
            ),

            ref
                .watch(recentReviewsProvider)
                .when(
                  loading: () => const SliverToBoxAdapter(
                    child: HomeListSkeleton(
                      itemCount: 2,
                      height: 150,
                      scrollDirection: Axis.vertical,
                    ),
                  ),
                  error: (e, st) => SliverToBoxAdapter(
                    child: ErrorStateWidget(
                      message: 'Yorumlar yüklenemedi',
                      onRetry: () => ref.invalidate(recentReviewsProvider),
                      compact: true,
                    ),
                  ),
                  data: (reviews) {
                    if (reviews.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.rate_review_outlined,
                                  size: 48,
                                  color: AppColors.textTertiaryFor(context),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  loc.homeNoReviews,
                                  style: AppTextStyles.titleMedium,
                                ),
                                Text(
                                  loc.homeFirstReview,
                                  style: AppTextStyles.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final review = reviews[index];
                        return ReviewCard(
                          review: review,
                          compact: true,
                          showReportMenu: false,
                          showActions: false,
                          showTargetInfo: true,
                          onTap: () {
                            switch (review.type) {
                              case ReviewType.department:
                                context.push('/department/${review.targetId}');
                                break;
                              case ReviewType.place:
                                context.push('/place/${review.targetId}');
                                break;
                              case ReviewType.university:
                                context.push('/university/${review.targetId}');
                                break;
                            }
                          },
                        );
                      }, childCount: reviews.length),
                    );
                  },
                ),

            // Bottom padding
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }
}

// ─── Widget Components ──────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push('/score-calculator'),
      child: Container(
        constraints: BoxConstraints(
          minHeight: Responsive.heroBannerMinHeight(context),
        ),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradientFor(context),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary
                  .withValues(alpha: isDark ? 0.18 : 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Modern Glow Effects
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 60,
              bottom: -50,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.white : AppColors.secondary)
                          .withValues(alpha: isDark ? 0.12 : 0.3),
                      blurRadius: 40,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            // Pattern Overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(painter: _GridPatternPainter()),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calculate_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'YKS 2025',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.homeHeroBannerTitle,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: Colors.white,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              loc.homeStart,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.primary,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Icon Graphic
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;
    const spacing = 20.0;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PopularUniCard extends ConsumerWidget {
  final UniversityModel university;
  final int index;
  final VoidCallback onTap;

  const _PopularUniCard({
    required this.university,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesProvider.select(
        (async) => async.value?.contains(university.id) ?? false,
      ),
    );
    // Marka paletiyle uyumlu, küratörlü aksan tonu (rastgele gökkuşağı yerine)
    final color = AppColors.accentForIndex(index);

    final brandColor = university.brandColor ?? color;

    return Semantics(
      label:
          '${university.name}, ${university.type}${isFavorite ? ', favorilerde' : ''}',
      button: true,
      child: Container(
        width: Responsive.cardWidth(context),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          boxShadow: AppColors.softShadowFor(context),
          gradient: LinearGradient(
            colors: [
              brandColor.withValues(alpha: 0.5),
              brandColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Material(
          color: AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(AppConstants.radiusLg - 1.5),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg - 1.5),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: Image.asset(
                          university.logoAssetPath,
                          fit: BoxFit.contain,
                          semanticLabel: 'Üniversite logosu',
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.school_rounded,
                                  color: color,
                                  size: 28,
                                ),
                              ),
                        ),
                      ),
                      _FavoriteHeartButton(
                        universityId: university.id,
                        isFavorite: isFavorite,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Başlık
                  Text(
                    university.name,
                    style: AppTextStyles.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Tür rozeti
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (university.type == 'Devlet'
                                      ? AppColors.stateUni
                                      : AppColors.foundationUni)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          university.type,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: university.type == 'Devlet'
                                ? AppColors.stateUni
                                : AppColors.foundationUni,
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Favoriye ekleme/çıkarma butonu — scale bounce animasyonu + haptic feedback.
class _FavoriteHeartButton extends ConsumerStatefulWidget {
  final String universityId;
  final bool isFavorite;

  const _FavoriteHeartButton({
    required this.universityId,
    required this.isFavorite,
  });

  @override
  ConsumerState<_FavoriteHeartButton> createState() =>
      _FavoriteHeartButtonState();
}

class _FavoriteHeartButtonState extends ConsumerState<_FavoriteHeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scaleAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.85), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 30),
      ],
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant _FavoriteHeartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite != oldWidget.isFavorite) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    AppHaptic.favoriteToggle();
    ref
        .read(favoritesControllerProvider.notifier)
        .toggleFavorite(user.uid, widget.universityId, widget.isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFavorite,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Icon(
            widget.isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: widget.isFavorite
                ? AppColors.error
                : AppColors.textTertiaryFor(context),
            size: 20,
          ),
        ),
      ),
    );
  }
}
