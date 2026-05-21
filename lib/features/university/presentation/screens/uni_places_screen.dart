import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../places/presentation/widgets/place_list.dart';

/// Mekanlar sayfası — Üniversiteye ait tüm mekanlar
class UniPlacesScreen extends ConsumerWidget {
  final String universityId;

  const UniPlacesScreen({super.key, required this.universityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        title: const Text('Mekanlar'),
      ),
      body: SingleChildScrollView(
        child: PlaceList(
          universityId: universityId,
          showTypeFilter: true,
          shrinkWrap: true,
        ),
      ),
    );
  }
}
