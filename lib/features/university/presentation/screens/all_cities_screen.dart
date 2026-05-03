import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/university_providers.dart';
import '../../domain/models/city_model.dart';
import '../widgets/city_logo.dart';

class AllCitiesScreen extends ConsumerWidget {
  const AllCitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(citiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Şehirler')),
      body: citiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Hata: $e')),
        data: (cities) => Column(
          children: [
            // Üst bilgi bandı
            _buildCountBanner(context, cities.length),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                itemCount: cities.length,
                itemBuilder: (context, index) => _CityListCard(
                  city: cities[index],
                  onTap: () =>
                      context.push('/city/${cities[index].id}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBanner(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count şehir',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Türkiye\'nin üniversite şehirleri',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CityListCard extends StatelessWidget {
  final CityModel city;
  final VoidCallback onTap;

  const _CityListCard({required this.city, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: city.brandPrimary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: city.brandPrimary.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Row(
            children: [
              // Sol: Gradient panel + Logo
              _buildGradientPanel(),
              // Sağ: Bilgiler
              Expanded(child: _buildInfo(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientPanel() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: city.brandGradient,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(AppConstants.radiusLg - 1),
        ),
      ),
      child: Stack(
        children: [
          // Sağ kenar fade — sorunsuz geçiş
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    city.brandSecondary.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: CityLogo(city: city, size: 58, withBackground: false),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(city.name, style: AppTextStyles.titleLarge),
          const SizedBox(height: 6),
          // İstatistik satırı
          Row(
            children: [
              _StatBadge(
                icon: Icons.school_rounded,
                label: '${city.appUniversityCount} üniversite',
                color: city.brandPrimary,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Toplam üniversite bilgisi
          Text(
            'Şehirde toplam ${city.totalUniversityCount} üniversite var',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
