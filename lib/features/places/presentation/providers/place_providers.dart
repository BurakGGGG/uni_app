import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/place_repository.dart';
import '../../domain/models/place_model.dart';

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  return PlaceRepository();
});

final placesByUniversityProvider = FutureProvider.autoDispose
    .family<List<PlaceModel>, String>((ref, uniId) async {
      final link = ref.keepAlive();
      final timer = Timer(const Duration(minutes: 5), link.close);
      ref.onDispose(() => timer.cancel());

      return ref.read(placeRepositoryProvider).getPlacesByUniversity(uniId);
    });

/// Place detail — keepAlive + 5 dakika sonra otomatik dispose
final placeDetailProvider = FutureProvider.family<PlaceModel?, String>((
  ref,
  placeId,
) async {
  // keepAlive başlat, 5 dk sonra dispose et
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(() => timer.cancel());

  return ref.read(placeRepositoryProvider).getPlace(placeId);
});
