import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/university_providers.dart';
import '../../domain/models/city_model.dart';
import '../../domain/models/university_model.dart';
import '../widgets/city_logo.dart';

class CityUniversitiesScreen extends ConsumerWidget {
  final String cityId;
  const CityUniversitiesScreen({super.key, required this.cityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cityAsync = ref.watch(cityDetailProvider(cityId));
    final unisAsync = ref.watch(universitiesByCityProvider(cityId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── Hero AppBar ─────────────────────────────────────────
          cityAsync.when(
            data: (city) => city != null
                ? _CityHeroAppBar(city: city)
                : const SliverAppBar(title: Text('Şehir')),
            loading: () => const SliverAppBar(title: Text('Yükleniyor...')),
            error: (e, st) => const SliverAppBar(title: Text('Hata')),
          ),

          // ─── KPI Strip ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: cityAsync.when(
              data: (city) => city != null
                  ? _buildKpiStrip(city, unisAsync)
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, st) => const SizedBox.shrink(),
            ),
          ),

          // ─── Üniversite Listesi ──────────────────────────────────
          unisAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => SliverFillRemaining(
              child: Center(child: Text('Hata: $e')),
            ),
            data: (universities) {
              if (universities.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyStateWidget(
                    icon: Icons.school_outlined,
                    title: 'Üniversite bulunamadı',
                    description:
                        'Bu şehirde henüz üniversite eklenmemiş.',
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final uni = universities[index];
                      return UniCard(
                        title: uni.name,
                        subtitle:
                            '${uni.type} • Kuruluş: ${uni.establishedYear}',
                        rating: uni.avgRating,
                        reviewCount: uni.reviewCount,
                        brandPrimaryColor: uni.brandColor,
                        logoAssetPath: uni.logoAssetPath,
                        tags: [
                          if (uni.hasCampus) 'Kampüslü',
                          uni.type
                        ],
                        onTap: () =>
                            context.push('/university/${uni.id}'),
                        badge: _uniTypeBadge(uni.type),
                      );
                    },
                    childCount: universities.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiStrip(
      CityModel city, AsyncValue<List<UniversityModel>> unisAsync) {
    final unis = unisAsync.valueOrNull ?? [];
    final devletCount = unis.where((u) => u.type == 'Devlet').length;
    final vakifCount = unis.where((u) => u.type == 'Vakıf').length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: city.brandPrimary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: city.brandPrimary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _kpi('${city.appUniversityCount}', 'Uygulama\'da',
              city.brandPrimary),
          _divider(),
          _kpi('$devletCount', 'Devlet',
              AppColors.stateUni),
          _divider(),
          _kpi('$vakifCount', 'Vakıf',
              AppColors.foundationUni),
          _divider(),
          _kpi('${city.totalUniversityCount}', 'Toplam',
              AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _kpi(String value, String label, Color color) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: AppTextStyles.headlineSmall.copyWith(
                    color: color, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textTertiary)),
          ],
        ),
      );

  Widget _divider() => Container(width: 1, height: 28, color: AppColors.borderLight);

  Widget _uniTypeBadge(String type) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: (type == 'Devlet' ? AppColors.stateUni : AppColors.foundationUni)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          type,
          style: AppTextStyles.labelSmall.copyWith(
            color: type == 'Devlet'
                ? AppColors.stateUni
                : AppColors.foundationUni,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      );
}

class _CityHeroAppBar extends StatelessWidget {
  final CityModel city;
  const _CityHeroAppBar({required this.city});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: city.brandPrimary,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: Colors.white.withValues(alpha: 0.22),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.pop(),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.biggest.height;
          final collapsed = top <=
              kToolbarHeight + MediaQuery.paddingOf(context).top + 20;

          return FlexibleSpaceBar(
            centerTitle: true,
            titlePadding:
                const EdgeInsets.only(left: 60, right: 60, bottom: 14),
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: collapsed ? 1.0 : 0.0,
              child: Text(
                city.name,
                style: AppTextStyles.titleMedium
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            background: Container(
              decoration: BoxDecoration(gradient: city.brandGradient),
              child: Stack(
                children: [
                  // Ambient glow
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 0.85,
                          colors: [
                            Colors.white.withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Dark overlay gradient (alt kısımdan AppBar ile birleşim)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            city.brandPrimary.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Logo + İsim
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        // Logo — beyaz daire üzerinde
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(10),
                          child: CityLogo(
                              city: city, size: 60, withBackground: false),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          city.name,
                          style: AppTextStyles.displaySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${city.appUniversityCount} üniversite',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
