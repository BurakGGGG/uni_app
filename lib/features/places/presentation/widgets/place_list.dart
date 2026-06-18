import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/models/place_model.dart';
import '../providers/place_providers.dart';
import '../providers/place_filter_provider.dart';
import 'place_card.dart';

class PlaceList extends ConsumerWidget {
  final String universityId;
  final bool showTypeFilter;
  final bool shrinkWrap;

  const PlaceList({
    super.key,
    required this.universityId,
    this.showTypeFilter = true,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // filteredPlacesProvider kullan — tek source of truth
    final filteredAsync = ref.watch(filteredPlacesProvider(universityId));
    final allAsync = ref.watch(placesByUniversityProvider(universityId));
    final filter = ref.watch(placeFilterProvider(universityId));

    return filteredAsync.when(
      loading: () => const ShimmerList(itemCount: 3),
      error: (e, _) => ErrorStateWidget(message: '$e'),
      data: (filtered) {
        final allPlaces = allAsync.valueOrNull ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTypeFilter) _buildFilterBar(context, ref, allPlaces, filter),
            if (filtered.isEmpty)
              !filter.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: EmptyStateWidget(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'Eşleşen mekan yok',
                      description:
                          '${filter.filterCount} filtreyle eşleşen mekan bulunamadı. Filtreleri gevşetmeyi deneyin.',
                    ),
                  )
                : const _PlacesEmptyState()
            else
              ListView.builder(
                shrinkWrap: shrinkWrap,
                physics: shrinkWrap
                    ? const NeverScrollableScrollPhysics()
                    : null,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final place = filtered[i];
                  return PlaceCard(
                    place: place,
                    onTap: () => context.push('/place/${place.id}'),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(
      BuildContext context, WidgetRef ref, List<PlaceModel> all, PlaceFilterState filter) {
    final types = all.map((p) => p.type).toSet().toList();
    if (types.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: types.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildFilterChip(context, ref, null, 'Tümü', all.length, filter);
          }
          final t = types[index - 1];
          final count = all.where((p) => p.type == t).length;
          return _buildFilterChip(context, ref, t, t.label, count, filter);
        },
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    PlaceType? type,
    String label,
    int count,
    PlaceFilterState filter,
  ) {
    // null = Tümü seçili ise type filter boş demektir
    final selected = type == null
        ? filter.selectedTypes.isEmpty
        : filter.selectedTypes.contains(type);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: selected,
        onSelected: (_) {
          final notifier =
              ref.read(placeFilterProvider(universityId).notifier);
          if (type == null) {
            // "Tümü" tıklandı → type filtresini sıfırla
            notifier.reset();
          } else {
            // Sadece tek bir type seçimi: önceki set'i temizle, yeni type'ı set et
            // veya zaten seçili ise kaldır (tekrar tıklayınca Tümü'ye dön)
            if (filter.selectedTypes.contains(type) &&
                filter.selectedTypes.length == 1) {
              // Zaten tek seçiliydi, kaldır → Tümü
              notifier.toggleType(type);
            } else {
              // Yeni seçim: önce mevcut type'ları temizle
              for (final t in filter.selectedTypes.toList()) {
                notifier.toggleType(t);
              }
              notifier.toggleType(type);
            }
          }
        },
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.borderLightFor(context),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
    );
  }
}

class _PlacesEmptyState extends StatelessWidget {
  const _PlacesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.place_outlined,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Mekan verisi toplanıyor',
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Bu üniversitenin mekan verileri henüz eklenmedi. Bölümler ve Yorumlar sekmelerini inceleyebilirsin.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondaryFor(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
