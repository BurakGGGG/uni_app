import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/place_repository.dart';
import '../../domain/models/place_model.dart';

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  return PlaceRepository();
});

final placesByUniversityProvider = 
    FutureProvider.family<List<PlaceModel>, String>((ref, uniId) async {
  ref.keepAlive();
  return ref.read(placeRepositoryProvider).getPlacesByUniversity(uniId);
});

final placeDetailProvider = 
    FutureProvider.family<PlaceModel?, String>((ref, placeId) async {
  ref.keepAlive();
  return ref.read(placeRepositoryProvider).getPlace(placeId);
});

final placeWatchProvider = 
    StreamProvider.family<PlaceModel?, String>((ref, placeId) {
  ref.keepAlive();
  return ref.read(placeRepositoryProvider).watchPlace(placeId);
});
