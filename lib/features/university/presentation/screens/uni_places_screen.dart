import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../places/presentation/widgets/place_list.dart';
import '../../../places/presentation/screens/place_filter_sheet.dart';
import '../../../places/presentation/providers/place_filter_provider.dart';
import '../../../../core/theme/app_colors.dart';

/// Tüm mekanların tam listesi — /university/:uniId/places
class UniPlacesScreen extends ConsumerWidget {
  final String universityId;

  const UniPlacesScreen({super.key, required this.universityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(placeFilterProvider(universityId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mekanlar'),
        actions: [
          IconButton(
            icon: Stack(children: [
              const Icon(Icons.tune_rounded),
              if (filter.filterCount > 0)
                Positioned(
                  right: 0, top: 0,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ]),
            onPressed: () => PlaceFilterSheet.show(context, universityId),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final children = [
            PlaceList(
              universityId: universityId,
              showTypeFilter: true,
              shrinkWrap: true,
            ),
          ];
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 80),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
          );
        },
      ),
    );
  }
}
