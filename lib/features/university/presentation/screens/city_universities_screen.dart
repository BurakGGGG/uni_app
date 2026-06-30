import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/turkish_compare.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/university_providers.dart';
import '../../domain/models/city_model.dart';
import '../../domain/models/university_model.dart';

final _cityUniFilterProvider = StateProvider.family.autoDispose<String?, String>(
  (ref, cityId) => null,
);

class CityUniversitiesScreen extends ConsumerWidget {
  final String cityId;
  const CityUniversitiesScreen({super.key, required this.cityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cityAsync = ref.watch(cityDetailProvider(cityId));
    final unisAsync = ref.watch(universitiesByCityProvider(cityId));
    final filter = ref.watch(_cityUniFilterProvider(cityId));

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(cityDetailProvider(cityId));
          ref.invalidate(universitiesByCityProvider(cityId));
          await ref.read(cityDetailProvider(cityId).future);
        },
        child: CustomScrollView(
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
                    ? _buildKpiStrip(context, city, unisAsync)
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, st) => const SizedBox.shrink(),
              ),
            ),

            // ─── Filter Pills ────────────────────────────────────────
            SliverToBoxAdapter(
              child: unisAsync.whenData((universities) {
                final filtered = filter == null
                    ? universities
                    : universities.where((u) => u.type == filter).toList();
                    
                return Padding(
                  padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 16, Responsive.horizontalPadding(context), 8),
                  child: Row(
                    children: [
                      _FilterPill(
                        label: 'Tümü',
                        selected: filter == null,
                        onTap: () => ref.read(_cityUniFilterProvider(cityId).notifier).state = null,
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Devlet',
                        selected: filter == 'Devlet',
                        onTap: () => ref.read(_cityUniFilterProvider(cityId).notifier).state = 'Devlet',
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Vakıf',
                        selected: filter == 'Vakıf',
                        onTap: () => ref.read(_cityUniFilterProvider(cityId).notifier).state = 'Vakıf',
                      ),
                      const Spacer(),
                      Text('${filtered.length} sonuç', style: AppTextStyles.labelSmall),
                    ],
                  ),
                );
              }).valueOrNull ?? const SizedBox.shrink(),
            ),

            // ─── Üniversite Listesi ──────────────────────────────────
            unisAsync.when(
              loading: () => const SliverFillRemaining(
                child: ListSkeleton(itemCount: 5),
              ),
              error: (e, st) => SliverFillRemaining(
                child: ErrorState(
                  title: 'Üniversiteler yüklenemedi',
                  message: 'Lütfen internet bağlantını kontrol et.',
                  onRetry: () => ref.invalidate(universitiesByCityProvider(cityId)),
                ),
              ),
              data: (universities) {
                if (universities.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.school_outlined,
                      title: 'Üniversite bulunamadı',
                      message: 'Bu şehirde henüz üniversite eklenmemiş.',
                    ),
                  );
                }
                
                final filtered = filter == null
                    ? universities
                    : universities.where((u) => u.type == filter).toList();

                final sorted = [...filtered]..sort((a, b) {
                  if (b.reviewCount != a.reviewCount) return b.reviewCount.compareTo(a.reviewCount);
                  return turkishCompare(a.name, b.name);
                });
                
                if (sorted.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('Bu filtreye uygun üniversite bulunamadı.')),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final uni = sorted[index];
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
                        ).animate(
                          key: ValueKey('uni_${uni.id}_$filter'),
                        ).fadeIn(delay: (index * 40).ms, duration: 300.ms)
                          .slideX(begin: 0.05);
                      },
                      childCount: sorted.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiStrip(
      BuildContext context, CityModel city, AsyncValue<List<UniversityModel>> unisAsync) {
    final unis = unisAsync.valueOrNull ?? [];
    final devletCount = unis.where((u) => u.type == 'Devlet').length;
    final vakifCount = unis.where((u) => u.type == 'Vakıf').length;

    return Container(
      margin: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 16, Responsive.horizontalPadding(context), 0),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: [
          _KpiChip(
            icon: Icons.apps_rounded,
            label: '${city.appUniversityCount} ÜniSeç\'te',
            color: city.brandPrimary,
          ),
          _KpiChip(
            icon: Icons.account_balance_rounded,
            label: '$devletCount Devlet',
            color: AppColors.stateUni,
          ),
          _KpiChip(
            icon: Icons.business_rounded,
            label: '$vakifCount Vakıf',
            color: AppColors.foundationUni,
          ),
          _KpiChip(
            icon: Icons.school_outlined,
            label: '${city.totalUniversityCount} toplam',
            color: AppColors.textSecondaryFor(context),
          ),
        ],
      ),
    );
  }

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
      expandedHeight: 220,
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(32),
        child: SizedBox(
          height: 32,
          child: CustomPaint(
            painter: _WavePainter(color: AppColors.backgroundFor(context)),
            size: Size.infinite,
          ),
        ),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.biggest.height;
          final collapsed = top <=
              kToolbarHeight + MediaQuery.paddingOf(context).top + 40;

          return FlexibleSpaceBar(
            centerTitle: true,
            titlePadding:
                const EdgeInsets.only(left: 60, right: 60, bottom: 44),
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
                  // Sadece arka plan deseni (Glow)
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
                  // Sadece İsim (Logo kaldırıldı)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          city.name,
                          style: AppTextStyles.displayMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${city.appUniversityCount} üniversite',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
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

class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height / 2);
    
    final amplitude = 12.0;
    final frequency = 1.5;
    for (double x = 0; x <= size.width; x++) {
      final y = amplitude *
          math.sin((x / size.width) * 2 * math.pi * frequency);
      path.lineTo(x, (size.height / 2) + y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _KpiChip extends StatelessWidget {
  final IconData icon; 
  final String label; 
  final Color color;
  const _KpiChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: color, fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLightFor(context),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? Colors.white : AppColors.textSecondaryFor(context),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
