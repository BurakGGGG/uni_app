import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';

/// Keşfet ekranı — arama ve filtreleme
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedFilter = 'Tümü';
  final _filters = ['Tümü', 'Devlet', 'Vakıf', 'SAY', 'EA', 'SÖZ'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Keşfet',
                style: AppTextStyles.displaySmall,
              ),
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
                hintText: 'Üniversite, bölüm veya şehir ara...',
                trailing: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
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

            // ─── Üniversite Listesi ─────────────────────────────
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: 5,
                itemBuilder: (context, index) {
                  final unis = [
                    {'name': 'Orta Doğu Teknik Üniversitesi', 'city': 'Ankara', 'type': 'Devlet', 'rating': 4.7, 'reviews': 342},
                    {'name': 'Boğaziçi Üniversitesi', 'city': 'İstanbul', 'type': 'Devlet', 'rating': 4.8, 'reviews': 412},
                    {'name': 'İstanbul Teknik Üniversitesi', 'city': 'İstanbul', 'type': 'Devlet', 'rating': 4.5, 'reviews': 287},
                    {'name': 'Hacettepe Üniversitesi', 'city': 'Ankara', 'type': 'Devlet', 'rating': 4.4, 'reviews': 198},
                    {'name': 'Koç Üniversitesi', 'city': 'İstanbul', 'type': 'Vakıf', 'rating': 4.6, 'reviews': 176},
                  ];
                  final uni = unis[index];
                  return UniCard(
                    title: uni['name'] as String,
                    subtitle: '${uni['city']} • ${uni['type']}',
                    rating: uni['rating'] as double,
                    reviewCount: uni['reviews'] as int,
                    tags: const ['Kampüslü', 'Kütüphane', 'Spor'],
                    onTap: () {
                      // TODO: Üniversite detay sayfasına git
                    },
                    badge: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (uni['type'] == 'Devlet'
                                ? AppColors.stateUni
                                : AppColors.foundationUni)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        uni['type'] as String,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: uni['type'] == 'Devlet'
                              ? AppColors.stateUni
                              : AppColors.foundationUni,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
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
