import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../../university/domain/models/university_model.dart';

/// Keşfet ekranı — arama ve filtreleme
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String _selectedFilter = 'Tümü';
  String _searchQuery = '';
  final _filters = ['Tümü', 'Devlet', 'Vakıf'];
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UniversityModel> _applyFilters(List<UniversityModel> universities) {
    var filtered = universities;

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      filtered = filtered.where((uni) =>
        uni.name.toLowerCase().contains(lowerQuery)
      ).toList();
    }

    // Tür filtresi
    if (_selectedFilter != 'Tümü') {
      filtered = filtered.where((uni) => uni.type == _selectedFilter).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final allUnisAsync = ref.watch(allUniversitiesProvider);

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
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: 'Üniversite ara...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                  suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear_rounded, size: 20),
                      )
                    : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // ─── Filtreler ──────────────────────────────────────
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = filter == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  );
                },
              ),
            ),

            // ─── Sonuç Sayısı ────────────────────────────────────
            allUnisAsync.when(
              data: (unis) {
                final filtered = _applyFilters(unis);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text(
                    '${filtered.length} üniversite bulundu',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textTertiary),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ─── Üniversite Listesi ─────────────────────────────
            const SizedBox(height: 4),
            Expanded(
              child: allUnisAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Hata: $e')),
                data: (universities) {
                  final filtered = _applyFilters(universities);

                  if (filtered.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.search_off_rounded,
                      title: 'Sonuç bulunamadı',
                      description: 'Farklı bir arama terimi veya filtre deneyin.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final uni = filtered[index];
                      return UniCard(
                        title: uni.name,
                        subtitle: '${uni.type} • Kuruluş: ${uni.establishedYear}',
                        // TODO(sprint3): Bu değerler artık UniversityModel'den geliyor, yorum sistemi aktif olunca canlı güncellenecek
                        rating: uni.avgRating,
                        reviewCount: uni.reviewCount,
                        tags: [
                          if (uni.hasCampus) 'Kampüslü',
                          uni.type,
                        ],
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
                      ).animate().fadeIn(
                        delay: Duration(milliseconds: 50 * index),
                        duration: 300.ms,
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
