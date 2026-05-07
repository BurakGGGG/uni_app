import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/city_comparison_repository.dart';
import '../../data/comparison_repository.dart';
import '../../data/department_comparison_repository.dart';
import '../../domain/models/city_comparison.dart';
import '../../domain/models/comparison_result.dart';
import '../../domain/models/department_comparison.dart';
import '../../domain/services/comparison_gate_service.dart';
import '../../../monetization/data/ad_service.dart';
import '../../../monetization/data/usage_stats_repository.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../../university/data/university_repository.dart';
import '../../../university/domain/models/department_model.dart';
import '../../../university/domain/models/university_model.dart';
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

final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService();
  service.preloadRewardedAd();
  return service;
});

class _UsageComparisonAdapter implements UsageComparisonPort {
  final UsageStatsRepository _repo;
  _UsageComparisonAdapter(this._repo);

  @override
  Future<bool> canCompare() => _repo.canCompare();

  @override
  Future<void> incrementDailyComparison() => _repo.incrementDailyComparison();
}

class _RewardedAdAdapter implements RewardedAdPort {
  final AdService _adService;
  _RewardedAdAdapter(this._adService);

  @override
  Future<bool> showRewardedAd() => _adService.showRewardedAd();
}

final comparisonGateServiceProvider = Provider<ComparisonGateService>((ref) {
  final usageRepo = ref.watch(usageStatsRepositoryProvider);
  final adService = ref.watch(adServiceProvider);
  return ComparisonGateService(
    usagePort: _UsageComparisonAdapter(usageRepo),
    adPort: _RewardedAdAdapter(adService),
  );
});

class ComparisonGateController {
  final Ref _ref;
  final Set<String> _consumedPairKeys = <String>{};

  ComparisonGateController(this._ref);

  Future<ComparisonGateDecision> guardPair(ComparisonPair pair) async {
    final key = _pairKey(pair.idA, pair.idB);
    if (_consumedPairKeys.contains(key)) {
      return const ComparisonGateDecision(status: ComparisonGateStatus.allowed);
    }

    final tier = await _ref.read(subscriptionTierProvider.future);
    final gateService = _ref.read(comparisonGateServiceProvider);
    final decision = await gateService.checkAndConsumeQuota(tier);

    if (decision.isAllowed) {
      _consumedPairKeys.add(key);
    }
    return decision;
  }

  String _pairKey(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}__${sorted[1]}';
  }
}

final comparisonGateControllerProvider = Provider<ComparisonGateController>((ref) {
  return ComparisonGateController(ref);
});

final comparisonGateDecisionProvider =
    FutureProvider<ComparisonGateDecision?>((ref) async {
  final selection = ref.watch(comparisonSelectionProvider);
  if (!selection.bothSelected) return null;
  if (selection.uniIdA == selection.uniIdB) return null;

  return ref.read(comparisonGateControllerProvider).guardPair(
        ComparisonPair(idA: selection.uniIdA!, idB: selection.uniIdB!),
      );
});

/// Karşılaştırma sonucu — her iki uni seçildiğinde otomatik tetiklenir
final comparisonResultProvider = FutureProvider<ComparisonResult?>((ref) async {
  final selection = ref.watch(comparisonSelectionProvider);
  if (!selection.bothSelected) return null;
  if (selection.uniIdA == selection.uniIdB) return null;

  final gateDecision = await ref.watch(comparisonGateDecisionProvider.future);
  if (gateDecision == null || !gateDecision.isAllowed) return null;

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

class DepartmentPickerFilter {
  final String? universityId;
  final String? scoreType;
  final String query;

  const DepartmentPickerFilter({
    this.universityId,
    this.scoreType,
    this.query = '',
  });

  DepartmentPickerFilter copyWith({
    String? universityId,
    String? scoreType,
    String? query,
    bool clearUniversityId = false,
    bool clearScoreType = false,
  }) {
    return DepartmentPickerFilter(
      universityId:
          clearUniversityId ? null : (universityId ?? this.universityId),
      scoreType: clearScoreType ? null : (scoreType ?? this.scoreType),
      query: query ?? this.query,
    );
  }
}

class DepartmentPickerFilterNotifier extends Notifier<DepartmentPickerFilter> {
  @override
  DepartmentPickerFilter build() => const DepartmentPickerFilter();

  void setUniversity(String? universityId) {
    state = state.copyWith(
      universityId: universityId,
      clearUniversityId: universityId == null,
    );
  }

  void setScoreType(String? scoreType) {
    state = state.copyWith(
      scoreType: scoreType,
      clearScoreType: scoreType == null,
    );
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void reset() {
    state = const DepartmentPickerFilter();
  }
}

final departmentPickerFilterProvider =
    NotifierProvider<DepartmentPickerFilterNotifier, DepartmentPickerFilter>(
  DepartmentPickerFilterNotifier.new,
);

final departmentPickerUniversitiesProvider =
    FutureProvider<List<UniversityModel>>((ref) async {
  final repository = UniversityRepository();
  return repository.getAllUniversities();
});

final departmentPickerDepartmentsProvider =
    FutureProvider<List<DepartmentModel>>((ref) async {
  final filter = ref.watch(departmentPickerFilterProvider);
  final repository = UniversityRepository();

  List<DepartmentModel> departments;
  if (filter.universityId != null && filter.universityId!.isNotEmpty) {
    departments =
        await repository.getDepartmentsByUniversity(filter.universityId!);
  } else {
    final universities = await repository.getAllUniversities();
    final departmentLists = await Future.wait(
      universities.map((u) => repository.getDepartmentsByUniversity(u.id)),
    );
    departments = departmentLists.expand((e) => e).toList();
  }

  final normalizedQuery = filter.query.trim().toLowerCase();
  final filtered = departments.where((d) {
    final scoreType = (d.scoreData?.scoreType ?? d.scoreType ?? '').trim();
    final matchesScoreType = filter.scoreType == null ||
        filter.scoreType!.isEmpty ||
        scoreType == filter.scoreType;

    final matchesQuery = normalizedQuery.isEmpty ||
        d.name.toLowerCase().contains(normalizedQuery) ||
        d.faculty.toLowerCase().contains(normalizedQuery);

    return matchesScoreType && matchesQuery;
  }).toList();

  filtered.sort((a, b) {
    final aScore = a.baseScore ?? a.scoreData?.baseScore ?? 0;
    final bScore = b.baseScore ?? b.scoreData?.baseScore ?? 0;
    if (aScore != bScore) return bScore.compareTo(aScore);
    return a.name.compareTo(b.name);
  });

  return filtered;
});

final departmentPickerAvailableScoreTypesProvider =
    FutureProvider<List<String>>((ref) async {
  final departments = await ref.watch(departmentPickerDepartmentsProvider.future);
  final scoreTypes = departments
      .map((d) => (d.scoreData?.scoreType ?? d.scoreType ?? '').trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return scoreTypes;
});

final canAccessDepartmentComparisonProvider = Provider<bool>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  return tier.when(
    data: (t) => canCompareDepartments(t),
    loading: () => false,
    error: (error, stackTrace) => false,
  );
});