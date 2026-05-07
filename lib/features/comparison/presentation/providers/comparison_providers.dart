import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/city_comparison_repository.dart';
import '../../data/comparison_repository.dart';
import '../../data/department_comparison_repository.dart';
import '../../domain/models/city_comparison.dart';
import '../../domain/models/comparison_result.dart';
import '../../domain/models/department_comparison.dart';
import '../../../university/data/university_repository.dart';
import '../../../places/data/place_repository.dart';

// ─── Sprint 4 — Karşılaştırma Seçim State ─────────────────

class ComparisonSelection {
  final String? uniIdA;
  final String? uniIdB;
  const ComparisonSelection({this.uniIdA, this.uniIdB});

  ComparisonSelection copyWith({String? uniIdA, String? uniIdB}) {
    return ComparisonSelection(
      uniIdA: uniIdA ?? this.uniIdA,
      uniIdB: uniIdB ?? this.uniIdB,
    );
  }

  bool get bothSelected => uniIdA != null && uniIdB != null;
}

class ComparisonSelectionNotifier extends Notifier<ComparisonSelection> {
  @override
  ComparisonSelection build() => const ComparisonSelection();

  void selectA(String id) => state = state.copyWith(uniIdA: id);
  void selectB(String id) => state = state.copyWith(uniIdB: id);

  void swap() {
    state = ComparisonSelection(
      uniIdA: state.uniIdB,
      uniIdB: state.uniIdA,
    );
  }

  void reset() => state = const ComparisonSelection();
}

final comparisonSelectionProvider =
    NotifierProvider<ComparisonSelectionNotifier, ComparisonSelection>(
  ComparisonSelectionNotifier.new,
);

// ─── Repository + Result Provider (Kişi A) ─────────────────

final comparisonRepositoryProvider = Provider<ComparisonRepository>((ref) {
  return ComparisonRepository(
    uniRepo: UniversityRepository(),
    placeRepo: PlaceRepository(),
  );
});

/// Karşılaştırma sonucu — her iki uni seçildiğinde otomatik tetiklenir
final comparisonResultProvider = FutureProvider<ComparisonResult?>((ref) async {
  final selection = ref.watch(comparisonSelectionProvider);
  if (!selection.bothSelected) return null;
  if (selection.uniIdA == selection.uniIdB) return null;

  return ref.read(comparisonRepositoryProvider).compare(
    selection.uniIdA!,
    selection.uniIdB!,
  );
});

class ComparisonPair {
  final String idA;
  final String idB;

  const ComparisonPair({
    required this.idA,
    required this.idB,
  });
}

final departmentComparisonRepositoryProvider =
    Provider<DepartmentComparisonRepository>((ref) {
  return DepartmentComparisonRepository(
    universityRepository: UniversityRepository(),
  );
});

final cityComparisonRepositoryProvider = Provider<CityComparisonRepository>((ref) {
  return CityComparisonRepository(
    universityRepository: UniversityRepository(),
  );
});

final departmentComparisonResultProvider =
    FutureProvider.family<DepartmentComparisonResult?, ComparisonPair>(
        (ref, pair) async {
  if (pair.idA == pair.idB) return null;
  return ref.read(departmentComparisonRepositoryProvider).compare(
        pair.idA,
        pair.idB,
      );
});

final cityComparisonResultProvider =
    FutureProvider.family<CityComparisonResult?, ComparisonPair>((ref, pair) async {
  if (pair.idA == pair.idB) return null;
  return ref.read(cityComparisonRepositoryProvider).compare(
        pair.idA,
        pair.idB,
      );
});