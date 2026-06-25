import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/place_model.dart';
import '../providers/place_filter_provider.dart';

class PlaceFilterSheet extends ConsumerWidget {
  final String universityId;

  const PlaceFilterSheet({super.key, required this.universityId});

  static Future<void> show(BuildContext context, String uniId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: PlaceFilterSheet(universityId: uniId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(placeFilterProvider(universityId));
    final notifier = ref.read(placeFilterProvider(universityId).notifier);

    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderLightFor(context),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text('Filtrele', style: AppTextStyles.headlineMedium),
              const Spacer(),
              if (!filter.isEmpty)
                TextButton(
                  onPressed: notifier.reset,
                  child: const Text('Sıfırla'),
                ),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              final children = [
                const _SectionTitle('Mekan Tipi'),
                _TypeFilters(filter: filter, notifier: notifier),
                const SizedBox(height: 24),
                const _SectionTitle('Fiyat Seviyesi'),
                const SizedBox(height: 8),
                _PriceFilters(filter: filter, notifier: notifier),
                const SizedBox(height: 24),
                const _SectionTitle('Özellikler'),
                const SizedBox(height: 8),
                _AmenityFilters(filter: filter, notifier: notifier),
                const SizedBox(height: 32),
              ];
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: children.length,
                itemBuilder: (context, index) => children[index],
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            border: Border(top: BorderSide(color: AppColors.borderLightFor(context))),
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              filter.isEmpty
                  ? 'Tümünü Göster'
                  : 'Filtreleri Uygula (${filter.filterCount})',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(title, style: AppTextStyles.titleSmall),
    );
  }
}

class _TypeFilters extends StatelessWidget {
  final PlaceFilterState filter;
  final PlaceFilterNotifier notifier;
  const _TypeFilters({required this.filter, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final types = PlaceType.values;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: types.map((t) {
          final selected = filter.selectedTypes.contains(t);
          return FilterChip(
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(t.icon, size: 14,
                  color: selected ? Colors.white : AppColors.textSecondaryFor(context)),
              const SizedBox(width: 6),
              Text(t.label),
            ]),
            selected: selected,
            onSelected: (_) => notifier.toggleType(t),
            backgroundColor: AppColors.surfaceVariantFor(context),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimaryFor(context),
              fontWeight: FontWeight.w600,
            ),
            checkmarkColor: Colors.white,
          );
        }).toList(),
      ),
    );
  }
}

class _PriceFilters extends StatelessWidget {
  final PlaceFilterState filter;
  final PlaceFilterNotifier notifier;
  const _PriceFilters({required this.filter, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final prices = ['₺', '₺₺', '₺₺₺'];
    final labels = ['Ekonomik', 'Orta', 'Yüksek'];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: List.generate(prices.length, (i) {
        final selected = filter.selectedPriceRanges.contains(prices[i]);
        return FilterChip(
          label: Text('${prices[i]} ${labels[i]}'),
          selected: selected,
          onSelected: (_) => notifier.togglePrice(prices[i]),
          backgroundColor: AppColors.surfaceVariantFor(context),
          selectedColor: AppColors.success,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimaryFor(context),
            fontWeight: FontWeight.w600,
          ),
          checkmarkColor: Colors.white,
        );
      }),
    );
  }
}

class _AmenityFilters extends StatelessWidget {
  final PlaceFilterState filter;
  final PlaceFilterNotifier notifier;
  const _AmenityFilters({required this.filter, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final amenities = [
      'Sessiz', 'Wi-Fi', 'Bol Priz', '7/24', 'KYK',
      'Kız Yurdu', 'Erkek Yurdu', 'Karma',
    ];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: amenities.map((a) {
        final selected = filter.requiredAmenities.contains(a);
        return FilterChip(
          label: Text(a),
          selected: selected,
          onSelected: (_) => notifier.toggleAmenity(a),
          backgroundColor: AppColors.surfaceVariantFor(context),
          selectedColor: AppColors.info,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimaryFor(context),
            fontWeight: FontWeight.w600,
          ),
          checkmarkColor: Colors.white,
        );
      }).toList(),
    );
  }
}
