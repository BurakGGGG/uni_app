import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../../university/domain/models/university_model.dart';
import '../providers/explore_filter_provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/widgets/native_ad_widget.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {

  // Filter memoization
  List<UniversityModel>? _cachedFilteredList;
  ExploreFilterState? _lastFilter;
  List<UniversityModel>? _lastInput;

  List<UniversityModel> _applyFilters(List<UniversityModel> universities, ExploreFilterState filters) {
    // Memo check — aynı input ve filter ise yeniden hesaplama
    if (_cachedFilteredList != null &&
        _lastFilter == filters &&
        identical(_lastInput, universities)) {
      return _cachedFilteredList!;
    }

    var filtered = universities;

    // Şehir filtresi
    if (filters.selectedCities.isNotEmpty) {
      filtered = filtered.where((uni) => filters.selectedCities.contains(uni.cityId)).toList();
    }

    // Tür filtresi
    if (filters.selectedTypes.isNotEmpty) {
      filtered = filtered.where((uni) => filters.selectedTypes.contains(uni.type)).toList();
    }

    _cachedFilteredList = filtered;
    _lastFilter = filters;
    _lastInput = universities;
    return filtered;
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allUnisAsync = ref.watch(allUniversitiesProvider);
    final filters = ref.watch(exploreFilterProvider);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 16, Responsive.horizontalPadding(context), 0),
              child: Text(loc.exploreTitle, style: AppTextStyles.displaySmall),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context)),
              child: Text(
                loc.exploreSubtitle,
                style: AppTextStyles.bodySmall,
              ),
            ),

            // ─── Arama ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 16, Responsive.horizontalPadding(context), 8),
              child: AppSearchBar(
                readOnly: true,
                onTap: () => context.push('/search'),
              ),
            ),

            // ─── Filtreler (Hızlı Seçim) ────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Filtrele Butonu
                  Badge(
                    isLabelVisible: filters.activeFilterCount > 0,
                    label: Text(filters.activeFilterCount.toString()),
                    backgroundColor: AppColors.primary,
                    offset: const Offset(4, -4),
                    child: IconButton(
                      onPressed: () => _showFilterBottomSheet(context),
                      icon: const Icon(Icons.tune_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: filters.activeFilterCount > 0 
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.surfaceVariantFor(context),
                        foregroundColor: filters.activeFilterCount > 0 
                            ? AppColors.primary
                            : AppColors.textSecondaryFor(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: filters.activeFilterCount > 0 
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : AppColors.borderLightFor(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Hızlı Tür Filtreleri (Devlet / Vakıf)
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: Builder(
                        builder: (context) {
                          final children = [
                            _QuickFilterChip(
                              label: loc.exploreTypeState,
                              isSelected: filters.selectedTypes.contains(loc.exploreTypeState),
                              onSelected: (_) => ref.read(exploreFilterProvider.notifier).toggleType(loc.exploreTypeState),
                            ),
                            _QuickFilterChip(
                              label: loc.exploreTypeFoundation,
                              isSelected: filters.selectedTypes.contains(loc.exploreTypeFoundation),
                              onSelected: (_) => ref.read(exploreFilterProvider.notifier).toggleType(loc.exploreTypeFoundation),
                            ),
                          ];
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: children.length,
                            itemBuilder: (context, index) => children[index],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Sonuç Sayısı ────────────────────────────────────
            allUnisAsync.when(
              data: (unis) {
                final filtered = _applyFilters(unis, filters);
                return Padding(
                  padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 12, Responsive.horizontalPadding(context), 4),
                  child: Text(
                    loc.exploreFoundCount(filtered.length),
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textTertiaryFor(context)),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, st) => const SizedBox.shrink(),
            ),

            // ─── Üniversite Listesi ─────────────────────────────
            const SizedBox(height: 4),
            Expanded(
              child: allUnisAsync.when(
                loading: () => const ListSkeleton(itemCount: 8),
                error: (e, st) => ErrorState(
                  title: 'Üniversiteler yüklenemedi',
                  message: 'Lütfen internet bağlantını kontrol et.',
                  onRetry: () => ref.invalidate(allUniversitiesProvider),
                ),
                data: (universities) {
                  final filtered = _applyFilters(universities, filters);

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.search_off_rounded,
                      title: loc.exploreNoResults,
                      message: loc.exploreNoResultsSub,
                    );
                  }

                  final showAds = ref.watch(subscriptionTierProvider).valueOrNull == SubscriptionTier.free;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    itemCount: showAds
                        ? filtered.length + (filtered.isEmpty ? 0 : (filtered.length - 1) ~/ 5)
                        : filtered.length,
                    itemBuilder: (context, index) {
                      if (showAds && (index + 1) % 6 == 0) {
                        return const NativeAdWidget();
                      }

                      final uniIndex = showAds ? index - (index ~/ 6) : index;
                      final uni = filtered[uniIndex];

                      return AnimatedListItem(
                        index: index,
                        child: UniCard(
                          title: uni.name,
                          subtitle: '${uni.type} • Kuruluş: ${uni.establishedYear}',
                          rating: uni.avgRating,
                          reviewCount: uni.reviewCount,
                          tags: [
                            if (uni.hasCampus) 'Kampüslü',
                            uni.type,
                          ],
                          brandPrimaryColor: uni.brandColor,
                          logoAssetPath: uni.logoAssetPath,
                          onTap: () => context.push('/university/${uni.id}'),
                          badge: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (uni.type == loc.exploreTypeState
                                      ? AppColors.stateUni
                                      : AppColors.foundationUni)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              uni.type,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: uni.type == loc.exploreTypeState
                                    ? AppColors.stateUni
                                    : AppColors.foundationUni,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
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
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _QuickFilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: onSelected,
        backgroundColor: AppColors.surfaceFor(context),
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textSecondaryFor(context),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.borderLightFor(context),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

// ─── Filter Bottom Sheet ──────────────────────────────────────────

class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(exploreFilterProvider);
    final loc = AppLocalizations.of(context);
    final citiesAsync = ref.watch(citiesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLightFor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.exploreFilters, style: AppTextStyles.titleLarge),
                  TextButton(
                    onPressed: () => ref.read(exploreFilterProvider.notifier).clearFilters(),
                    child: Text(
                      loc.exploreClear, 
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.borderLightFor(context)),

            // Content
            Expanded(
              child: Builder(
                builder: (context) {
                  final children = [
                    // Tür Filtresi
                    Text(loc.exploreUniType, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterOption(
                          label: loc.exploreTypeState,
                          isSelected: filters.selectedTypes.contains(loc.exploreTypeState),
                          onTap: () => ref.read(exploreFilterProvider.notifier).toggleType(loc.exploreTypeState),
                        ),
                        _FilterOption(
                          label: loc.exploreTypeFoundation,
                          isSelected: filters.selectedTypes.contains(loc.exploreTypeFoundation),
                          onTap: () => ref.read(exploreFilterProvider.notifier).toggleType(loc.exploreTypeFoundation),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Şehir Filtresi
                    Text(loc.exploreCities, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 12),
                    citiesAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, st) => Text(loc.exploreCitiesError),
                      data: (cities) {
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: cities.map((city) {
                            return _FilterOption(
                              label: city.name,
                              isSelected: filters.selectedCities.contains(city.id),
                              onTap: () => ref.read(exploreFilterProvider.notifier).toggleCity(city.id),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ];
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: children.length,
                    itemBuilder: (context, index) => children[index],
                  );
                },
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: GradientButton(
                text: loc.exploreShowResults,
                onPressed: () => context.pop(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLightFor(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimaryFor(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
