import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/university_providers.dart';
import '../../domain/models/city_model.dart';

/// Şehir emoji mapping
String _cityEmoji(String cityName) {
  const emojis = {
    'İstanbul': '🌉',
    'Ankara': '🏛️',
    'İzmir': '🌊',
    'Antalya': '☀️',
    'Eskişehir': '🎓',
    'Bursa': '🌿',
    'Çanakkale': '⚓',
    'Sivas': '🏔️',
    'Trabzon': '⛰️',
    'Mersin': '🍊',
  };
  return emojis[cityName] ?? '🏙️';
}

class AllCitiesScreen extends ConsumerWidget {
  const AllCitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(citiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Şehirler'),
      ),
      body: citiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Hata: $e')),
        data: (cities) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cities.length,
            itemBuilder: (context, index) {
              final city = cities[index];
              return _CityListTile(city: city, index: index);
            },
          );
        },
      ),
    );
  }
}

class _CityListTile extends StatelessWidget {
  final CityModel city;
  final int index;

  const _CityListTile({required this.city, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: InkWell(
          onTap: () => context.push('/city/${city.id}'),
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Emoji
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _cityEmoji(city.name),
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Bilgi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(city.name, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.school_rounded, size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            '${city.appUniversityCount} üniversite (toplam ${city.totalUniversityCount})',
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
