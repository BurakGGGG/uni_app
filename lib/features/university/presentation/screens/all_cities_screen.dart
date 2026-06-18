import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/turkish_compare.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/university_providers.dart';
import '../../domain/models/city_model.dart';
import '../widgets/city_card.dart';

final _searchProvider = StateProvider.autoDispose<String>((ref) => '');

class AllCitiesScreen extends ConsumerWidget {
  const AllCitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(citiesProvider);
    final query = ref.watch(_searchProvider);
    
    final crossAxisCount = Responsive.gridColumns(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: citiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (cities) {
          final filtered = _filter(cities, query);
          final popular = filtered.where((c) => c.appUniversityCount >= 3).toList();
          final others = filtered.where((c) => c.appUniversityCount < 3).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(citiesProvider);
              await ref.read(citiesProvider.future);
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  stretch: true,
                  expandedHeight: 180,
                  backgroundColor: AppColors.backgroundFor(context),
                  foregroundColor: AppColors.textPrimaryFor(context),
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  flexibleSpace: const _GalleryHero(),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SearchBarDelegate(
                    child: _SearchField(
                      onChanged: (v) => ref.read(_searchProvider.notifier).state = v,
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                          child: const Icon(
                            Icons.location_off_rounded,
                            size: 56,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('"$query" için sonuç yok', style: AppTextStyles.titleMedium),
                        const SizedBox(height: 6),
                        Text(
                          'Farklı bir arama deneyin',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryFor(context)),
                        ),
                      ],
                    ),
                  )
                else ...[
                  if (popular.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Popüler Şehirler',
                        subtitle: 'İstanbul, Ankara, İzmir, Eskişehir gibi yoğun şehirler',
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final city = popular[i];
                            return CityCard.tile(
                              city: city,
                              onTap: () => context.push('/city/${city.id}'),
                            ).animate(key: ValueKey(city.id))
                             .fadeIn(duration: 250.ms, delay: (i * 30).ms)
                             .slideY(begin: 0.1, duration: 250.ms);
                          },
                          childCount: popular.length,
                        ),
                      ),
                    ),
                  ],
                  if (others.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Diğer Şehirler',
                        subtitle: '5\'ten az üniversitesi olan şehirler',
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final city = others[i];
                            return CityCard.tile(
                              city: city,
                              onTap: () => context.push('/city/${city.id}'),
                            ).animate(key: ValueKey(city.id))
                             .fadeIn(duration: 250.ms, delay: (i * 30).ms)
                             .slideY(begin: 0.1, duration: 250.ms);
                          },
                          childCount: others.length,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<CityModel> _filter(List<CityModel> all, String query) {
    if (query.trim().isEmpty) return all;
    final q = query.toLowerCase();
    final qNorm = turkishNormalize(q);
    return all.where((c) {
      if (c.name.toLowerCase().contains(q)) return true;
      if (turkishNormalize(c.name.toLowerCase()).contains(qNorm)) return true;
      if (c.plateCode.contains(query)) return true;
      return false;
    }).toList();
  }
}

// ─── Hero (üstteki banner) ────────────────────────────────────
class _GalleryHero extends StatelessWidget {
  const _GalleryHero();

  @override
  Widget build(BuildContext context) {
    return FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: Stack(
          children: [
            // Decorative
            Positioned(
              right: -40, top: -40,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            // Content
            Positioned(
              left: 24, right: 24, bottom: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Şehirleri Keşfet',
                    style: AppTextStyles.displaySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Türkiye\'nin üniversite şehirleri',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
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

// ─── Sticky search ─────────────────────────────────────────────
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SearchBarDelegate({required this.child});

  @override
  double get minExtent => 72;
  @override
  double get maxExtent => 72;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.backgroundFor(context),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_) => false;
}

class _SearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      widget.onChanged(query);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.textTertiaryFor(context)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Şehir veya plaka ara...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section başlığı ──────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4, height: 18,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiaryFor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
