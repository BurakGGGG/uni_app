import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/models/place_model.dart';
import '../providers/place_providers.dart';
import 'place_card.dart';

class PlaceList extends ConsumerStatefulWidget {
  final String universityId;
  final PlaceType? initialFilterType;
  final bool showTypeFilter;
  final bool shrinkWrap;

  const PlaceList({
    super.key,
    required this.universityId,
    this.initialFilterType,
    this.showTypeFilter = true,
    this.shrinkWrap = true,
  });

  @override
  ConsumerState<PlaceList> createState() => _PlaceListState();
}

class _PlaceListState extends ConsumerState<PlaceList> {
  PlaceType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialFilterType;
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(placesByUniversityProvider(widget.universityId));

    return placesAsync.when(
      loading: () => const ShimmerList(itemCount: 3),
      error: (e, _) => ErrorStateWidget(message: '$e'),
      data: (places) {
        final filtered = _selectedType == null
            ? places
            : places.where((p) => p.type == _selectedType).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showTypeFilter) _buildFilterBar(places),
            if (filtered.isEmpty)
              _selectedType != null
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: EmptyStateWidget(
                      icon: Icons.place_outlined,
                      title: '${_selectedType!.label} bulunamadı',
                      description: 'Bu üniversite için bu kategoride mekan yok.',
                    ),
                  )
                : const _PlacesEmptyState()
            else
              ListView.builder(
                shrinkWrap: widget.shrinkWrap,
                physics: widget.shrinkWrap
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

  Widget _buildFilterBar(List<PlaceModel> all) {
    final types = all.map((p) => p.type).toSet().toList();
    if (types.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          _buildFilterChip(null, 'Tümü', all.length),
          ...types.map((t) {
            final count = all.where((p) => p.type == t).length;
            return _buildFilterChip(t, t.label, count);
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(PlaceType? type, String label, int count) {
    final selected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: selected,
        onSelected: (_) => setState(() => _selectedType = type),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.borderLight,
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
            child: Icon(Icons.place_outlined, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Bu üniversite için mekan ekleniyor',
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Çok yakında bu üniversitenin kafeleri, yurtları ve kütüphaneleri burada listelenecek.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
