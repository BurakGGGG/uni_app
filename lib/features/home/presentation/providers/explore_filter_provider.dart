import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExploreFilterState {
  final List<String> selectedCities; // Şehir ID'leri
  final List<String> selectedTypes; // "Devlet", "Vakıf"

  const ExploreFilterState({
    this.selectedCities = const [],
    this.selectedTypes = const [],
  });

  ExploreFilterState copyWith({
    List<String>? selectedCities,
    List<String>? selectedTypes,
  }) {
    return ExploreFilterState(
      selectedCities: selectedCities ?? this.selectedCities,
      selectedTypes: selectedTypes ?? this.selectedTypes,
    );
  }

  int get activeFilterCount => selectedCities.length + selectedTypes.length;
}

class ExploreFilterNotifier extends Notifier<ExploreFilterState> {
  @override
  ExploreFilterState build() {
    return const ExploreFilterState();
  }

  void toggleCity(String cityId) {
    final cities = List<String>.from(state.selectedCities);
    if (cities.contains(cityId)) {
      cities.remove(cityId);
    } else {
      cities.add(cityId);
    }
    state = state.copyWith(selectedCities: cities);
  }

  void toggleType(String type) {
    final types = List<String>.from(state.selectedTypes);
    if (types.contains(type)) {
      types.remove(type);
    } else {
      types.add(type);
    }
    state = state.copyWith(selectedTypes: types);
  }

  void clearFilters() {
    state = const ExploreFilterState();
  }
}

final exploreFilterProvider = NotifierProvider<ExploreFilterNotifier, ExploreFilterState>(() {
  return ExploreFilterNotifier();
});
