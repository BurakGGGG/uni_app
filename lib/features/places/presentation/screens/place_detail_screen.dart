import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/place_providers.dart';

/// Sprint 4 — Placeholder mekan detay ekranı.
/// Gün 3'te tam olarak doldurulacak.
class PlaceDetailScreen extends ConsumerWidget {
  final String placeId;
  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeAsync = ref.watch(placeDetailProvider(placeId));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Mekan Detayı'),
      ),
      body: placeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (place) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(place?.name ?? 'Bulunamadı',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Detay ekranı yarın yapılacak'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
