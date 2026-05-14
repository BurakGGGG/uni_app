import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../../university/domain/models/university_model.dart';
import '../providers/explore_filter_provider.dart';

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
      backgroundColor: AppColors.surface,
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Keşfet', style: AppTextStyles.displaySmall),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Üniversiteleri keşfet, filtrele ve karşılaştır',
                style: AppTextStyles.bodySmall,
              ),
            ),

            // ─── Arama ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                            : AppColors.surfaceVariant,
                        foregroundColor: filters.activeFilterCount > 0 
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: filters.activeFilterCount > 0 
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : AppColors.borderLight,
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
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _QuickFilterChip(
                            label: 'Devlet',
                            isSelected: filters.selectedTypes.contains('Devlet'),
                            onSelected: (_) => ref.read(exploreFilterProvider.notifier).toggleType('Devlet'),
                          ),
                          _QuickFilterChip(
                            label: 'Vakıf',
                            isSelected: filters.selectedTypes.contains('Vakıf'),
                            onSelected: (_) => ref.read(exploreFilterProvider.notifier).toggleType('Vakıf'),
                          ),
                        ],
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text(
                    '${filtered.length} üniversite bulundu',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textTertiary),
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
                loading: () => const ListSkeleton(itemCount: 6),
                error: (e, st) => ErrorState(
                  title: 'Üniversiteler yüklenemedi',
                  message: 'Lütfen internet bağlantını kontrol et.',
                  onRetry: () => ref.invalidate(allUniversitiesProvider),
                ),
                data: (universities) {
                  final filtered = _applyFilters(universities, filters);

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Sonuç bulunamadı',
                      message: 'Farklı bir filtre kombinasyonu deneyin.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final uni = filtered[index];
                      return UniCard(
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
                            color: (uni.type == 'Devlet'
                                    ? AppColors.stateUni
                                    : AppColors.foundationUni)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            uni.type,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: uni.type == 'Devlet'
                                  ? AppColors.stateUni
                                  : AppColors.foundationUni,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
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
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.borderLight,
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
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filtreler', style: AppTextStyles.titleLarge),
                  TextButton(
                    onPressed: () => ref.read(exploreFilterProvider.notifier).clearFilters(),
                    child: Text(
                      'Temizle', 
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.borderLight),

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Tür Filtresi
                  Text('Üniversite Türü', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterOption(
                        label: 'Devlet',
                        isSelected: filters.selectedTypes.contains('Devlet'),
                        onTap: () => ref.read(exploreFilterProvider.notifier).toggleType('Devlet'),
                      ),
                      _FilterOption(
                        label: 'Vakıf',
                        isSelected: filters.selectedTypes.contains('Vakıf'),
                        onTap: () => ref.read(exploreFilterProvider.notifier).toggleType('Vakıf'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Şehir Filtresi
                  Text('Şehirler', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  citiesAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, st) => const Text('Şehirler yüklenemedi'),
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
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: GradientButton(
                text: 'Sonuçları Göster',
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
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
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
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
