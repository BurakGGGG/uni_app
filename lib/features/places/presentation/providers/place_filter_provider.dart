import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/place_model.dart';
import 'place_providers.dart';

class PlaceFilterState {
  final Set<PlaceType> selectedTypes;
  final Set<String> selectedPriceRanges;  // ['₺', '₺₺', '₺₺₺']
  final Set<String> requiredAmenities;    // ['Sessiz', 'Wi-Fi'...]
  final String? searchQuery;
  
  const PlaceFilterState({
    this.selectedTypes = const {},
    this.selectedPriceRanges = const {},
    this.requiredAmenities = const {},
    this.searchQuery,
  });
  
  bool get isEmpty =>
      selectedTypes.isEmpty &&
      selectedPriceRanges.isEmpty &&
      requiredAmenities.isEmpty &&
      (searchQuery == null || searchQuery!.isEmpty);
  
  int get filterCount =>
      (selectedTypes.isNotEmpty ? 1 : 0) +
      (selectedPriceRanges.isNotEmpty ? 1 : 0) +
      (requiredAmenities.isNotEmpty ? 1 : 0) +
      (searchQuery != null && searchQuery!.isNotEmpty ? 1 : 0);
  
  PlaceFilterState copyWith({
    Set<PlaceType>? selectedTypes,
    Set<String>? selectedPriceRanges,
    Set<String>? requiredAmenities,
    String? searchQuery,
    bool clearSearch = false,
  }) {
    return PlaceFilterState(
      selectedTypes: selectedTypes ?? this.selectedTypes,
      selectedPriceRanges: selectedPriceRanges ?? this.selectedPriceRanges,
      requiredAmenities: requiredAmenities ?? this.requiredAmenities,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }
}

class PlaceFilterNotifier extends StateNotifier<PlaceFilterState> {
  PlaceFilterNotifier() : super(const PlaceFilterState());
  
  void toggleType(PlaceType type) {
    final newSet = Set<PlaceType>.from(state.selectedTypes);
    newSet.contains(type) ? newSet.remove(type) : newSet.add(type);
    state = state.copyWith(selectedTypes: newSet);
  }
  
  void togglePrice(String price) {
    final newSet = Set<String>.from(state.selectedPriceRanges);
    newSet.contains(price) ? newSet.remove(price) : newSet.add(price);
    state = state.copyWith(selectedPriceRanges: newSet);
  }
  
  void toggleAmenity(String amenity) {
    final newSet = Set<String>.from(state.requiredAmenities);
    newSet.contains(amenity) ? newSet.remove(amenity) : newSet.add(amenity);
    state = state.copyWith(requiredAmenities: newSet);
  }
  
  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);
  
  void reset() => state = const PlaceFilterState();
}

/// Her uni için ayrı filter state
final placeFilterProvider =
    StateNotifierProvider.family<PlaceFilterNotifier, PlaceFilterState, String>(
  (ref, uniId) => PlaceFilterNotifier(),
);

/// Filtrelenmiş mekanlar
final filteredPlacesProvider = 
    Provider.family<AsyncValue<List<PlaceModel>>, String>((ref, uniId) {
  final placesAsync = ref.watch(placesByUniversityProvider(uniId));
  final filter = ref.watch(placeFilterProvider(uniId));
  
  return placesAsync.whenData((all) {
    if (filter.isEmpty) return all;
    
    return all.where((p) {
      // Type filter
      if (filter.selectedTypes.isNotEmpty &&
          !filter.selectedTypes.contains(p.type)) {
        return false;
      }
      
      // Price filter (sadece kafe için anlamlı, ama applied)
      if (filter.selectedPriceRanges.isNotEmpty &&
          (p.priceRange == null ||
           !filter.selectedPriceRanges.contains(p.priceRange))) {
        return false;
      }
      
      // Amenity filter (TÜM seçili amenity'ler bulunmalı)
      if (filter.requiredAmenities.isNotEmpty) {
        for (final required in filter.requiredAmenities) {
          if (!p.amenities.any((a) => a.toLowerCase().contains(required.toLowerCase()))) {
            return false;
          }
        }
      }
      
      // Search query
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final q = filter.searchQuery!.toLowerCase();
        if (!p.name.toLowerCase().contains(q) &&
            !p.address.toLowerCase().contains(q) &&
            !p.description.toLowerCase().contains(q)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  });
});
