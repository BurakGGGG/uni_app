import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/ai_comparison_summary_service.dart';
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
import '../../../../services/analytics_service.dart';
import 'package:flutter/foundation.dart';

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

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
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
    await _ref.read(analyticsServiceProvider).logComparisonStarted(
          type: 'university',
          userTier: tier.name,
        );
    final gateService = _ref.read(comparisonGateServiceProvider);
    final decision = await gateService.checkAndConsumeQuota(tier);

    if (decision.isAllowed) {
      _consumedPairKeys.add(key);
      if (decision.rewardedAdWatched) {
        final stats = await _ref.read(usageStatsRepositoryProvider).getUsageStats();
        await _ref.read(analyticsServiceProvider).logAdWatched(
              completed: true,
              dailyComparisonCount: stats.dailyComparisons,
            );
      }
    } else {
      final stats = await _ref.read(usageStatsRepositoryProvider).getUsageStats();
      await _ref.read(analyticsServiceProvider).logAdWatched(
            completed: false,
            dailyComparisonCount: stats.dailyComparisons,
          );
      await _ref.read(analyticsServiceProvider).logPaywallShown(
            trigger: 'daily_limit',
            userTier: tier.name,
          );
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

final _comparisonResultCache = <String, ComparisonResult?>{};

/// Karşılaştırma sonucu — her iki uni seçildiğinde otomatik tetiklenir
final comparisonResultProvider = FutureProvider<ComparisonResult?>((ref) async {
  final selection = ref.watch(comparisonSelectionProvider);
  if (!selection.bothSelected) return null;
  if (selection.uniIdA == selection.uniIdB) return null;
  final key = _pairKey(selection.uniIdA!, selection.uniIdB!);

  final gateDecision = await ref.watch(comparisonGateDecisionProvider.future);
  if (gateDecision == null || !gateDecision.isAllowed) return null;

  try {
    final result = await ref.read(comparisonRepositoryProvider).compare(
          selection.uniIdA!,
          selection.uniIdB!,
        );
    _comparisonResultCache[key] = result;
    return result;
  } catch (_) {
    return _comparisonResultCache[key];
  }
});

class ComparisonPair {
  final String idA;
  final String idB;

  const ComparisonPair({
    required this.idA,
    required this.idB,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComparisonPair &&
          runtimeType == other.runtimeType &&
          idA == other.idA &&
          idB == other.idB;

  @override
  int get hashCode => idA.hashCode ^ idB.hashCode;
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
  final key = _pairKey(pair.idA, pair.idB);
  try {
    final result = await ref
        .read(departmentComparisonRepositoryProvider)
        .compare(
          pair.idA,
          pair.idB,
        )
        .timeout(const Duration(seconds: 10));
    _departmentResultCache[key] = result;
    return result;
  } catch (e) {
    debugPrint('[DepartmentComparison] compare failed for $key: $e');
    return _departmentResultCache[key];
  }
});

final _departmentResultCache = <String, DepartmentComparisonResult?>{};

final cityComparisonResultProvider =
    FutureProvider.family<CityComparisonResult?, ComparisonPair>((ref, pair) async {
  if (pair.idA == pair.idB) return null;
  final key = _pairKey(pair.idA, pair.idB);
  try {
    final result = await ref
        .read(cityComparisonRepositoryProvider)
        .compare(
          pair.idA,
          pair.idB,
        )
        .timeout(const Duration(seconds: 10));
    _cityResultCache[key] = result;
    return result;
  } catch (e) {
    debugPrint('[CityComparison] compare failed for $key: $e');
    return _cityResultCache[key];
  }
});

final _cityResultCache = <String, CityComparisonResult?>{};

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

final aiComparisonSummaryServiceProvider = Provider<AiComparisonSummaryService>((ref) {
  return AiComparisonSummaryService();
});

final _aiSummaryCache = <String, AiComparisonSummaryResult>{};

final aiComparisonSummaryProvider = FutureProvider<AiComparisonSummaryResult?>((ref) async {
  final canUseAi = ref.watch(canUseAiComparisonProvider);
  if (!canUseAi) return null;

  final result = await ref.watch(comparisonResultProvider.future);
  if (result == null) return null;

  final service = ref.read(aiComparisonSummaryServiceProvider);
  final key = _pairKey(result.uniA.id, result.uniB.id);
  try {
    final summary = await service.summarizeUniversityComparison(result);
    _aiSummaryCache[key] = summary;
    return summary;
  } catch (_) {
    return _aiSummaryCache[key];
  }
});

class RatingTrendPoint {
  final DateTime month;
  final double avgRatingA;
  final double avgRatingB;

  const RatingTrendPoint({
    required this.month,
    required this.avgRatingA,
    required this.avgRatingB,
  });
}

class CategoryHeatMapCell {
  final String category;
  final double valueA;
  final double valueB;

  const CategoryHeatMapCell({
    required this.category,
    required this.valueA,
    required this.valueB,
  });
}

class DepartmentScatterPoint {
  final String departmentId;
  final String departmentName;
  final double baseScore;
  final int ranking;
  final String universityId;

  const DepartmentScatterPoint({
    required this.departmentId,
    required this.departmentName,
    required this.baseScore,
    required this.ranking,
    required this.universityId,
  });
}

class DepartmentScatterData {
  final List<DepartmentScatterPoint> pointsA;
  final List<DepartmentScatterPoint> pointsB;

  const DepartmentScatterData({
    required this.pointsA,
    required this.pointsB,
  });
}

final canUseProComparisonChartsProvider = Provider<bool>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  return tier.when(
    data: (t) => canUseProCharts(t),
    loading: () => false,
    error: (error, stackTrace) => false,
  );
});

final _ratingTrendCache = <String, List<RatingTrendPoint>>{};
final _heatMapCache = <String, List<CategoryHeatMapCell>>{};
final _scatterCache = <String, DepartmentScatterData>{};

final ratingTrendProvider =
    FutureProvider.family<List<RatingTrendPoint>, ComparisonPair>(
  (ref, pair) async {
    final canUse = ref.watch(canUseProComparisonChartsProvider);
    if (!canUse) return const [];
    final key = _pairKey(pair.idA, pair.idB);

    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final startMonth = DateTime(now.year, now.month - 5, 1);

    Future<Map<DateTime, double>> aggregateMonthlyAvg(String universityId) async {
      final snapshot = await firestore
          .collection('reviews')
          .where('universityId', isEqualTo: universityId)
          .where('isApproved', isEqualTo: true)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startMonth),
          )
          .get();

      final totals = <DateTime, double>{};
      final counts = <DateTime, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rating = (data['rating'] as num?)?.toDouble();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (rating == null || createdAt == null) continue;
        final monthKey = DateTime(createdAt.year, createdAt.month, 1);
        totals[monthKey] = (totals[monthKey] ?? 0) + rating;
        counts[monthKey] = (counts[monthKey] ?? 0) + 1;
      }

      return {
        for (final month in totals.keys)
          month: counts[month] == null || counts[month] == 0
              ? 0
              : totals[month]! / counts[month]!,
      };
    }

    try {
      final results = await Future.wait([
        aggregateMonthlyAvg(pair.idA),
        aggregateMonthlyAvg(pair.idB),
      ]);
      final monthlyA = results[0];
      final monthlyB = results[1];

      final output = List.generate(6, (index) {
        final month = DateTime(startMonth.year, startMonth.month + index, 1);
        return RatingTrendPoint(
          month: month,
          avgRatingA: monthlyA[month] ?? 0,
          avgRatingB: monthlyB[month] ?? 0,
        );
      });
      _ratingTrendCache[key] = output;
      return output;
    } catch (_) {
      return _ratingTrendCache[key] ?? const [];
    }
  },
);

final categoryHeatMapProvider =
    FutureProvider.family<List<CategoryHeatMapCell>, ComparisonPair>(
  (ref, pair) async {
    final canUse = ref.watch(canUseProComparisonChartsProvider);
    if (!canUse) return const [];
    final key = _pairKey(pair.idA, pair.idB);

    try {
      final repo = UniversityRepository();
      final results = await Future.wait([
        repo.getUniversity(pair.idA),
        repo.getUniversity(pair.idB),
      ]);
      final uniA = results[0];
      final uniB = results[1];
      if (uniA == null || uniB == null) return _heatMapCache[key] ?? const [];

      final categories = <String>{
        ...uniA.categoryRatings.keys,
        ...uniB.categoryRatings.keys,
      }.toList()
        ..sort();

      final output = categories
          .map(
            (category) => CategoryHeatMapCell(
              category: category,
              valueA: (uniA.categoryRatings[category] ?? 0).toDouble(),
              valueB: (uniB.categoryRatings[category] ?? 0).toDouble(),
            ),
          )
          .toList();
      _heatMapCache[key] = output;
      return output;
    } catch (_) {
      return _heatMapCache[key] ?? const [];
    }
  },
);

final departmentScatterProvider =
    FutureProvider.family<DepartmentScatterData, ComparisonPair>(
  (ref, pair) async {
    final canUse = ref.watch(canUseProComparisonChartsProvider);
    final key = _pairKey(pair.idA, pair.idB);
    if (!canUse) {
      return const DepartmentScatterData(pointsA: [], pointsB: []);
    }

    try {
      final repo = UniversityRepository();
      final departmentLists = await Future.wait([
        repo.getDepartmentsByUniversity(pair.idA),
        repo.getDepartmentsByUniversity(pair.idB),
      ]);

    List<DepartmentScatterPoint> mapPoints(
      List<DepartmentModel> departments,
      String universityId,
    ) {
      return departments
          .where((d) {
            final baseScore = d.baseScore ?? d.scoreData?.baseScore;
            final ranking = d.ranking ?? d.scoreData?.ranking;
            return baseScore != null &&
                ranking != null &&
                baseScore > 0 &&
                ranking > 0;
          })
          .map((d) => DepartmentScatterPoint(
                departmentId: d.id,
                departmentName: d.name,
                baseScore: d.baseScore ?? d.scoreData!.baseScore,
                ranking: d.ranking ?? d.scoreData!.ranking,
                universityId: universityId,
              ))
          .toList();
    }

      final output = DepartmentScatterData(
        pointsA: mapPoints(departmentLists[0], pair.idA),
        pointsB: mapPoints(departmentLists[1], pair.idB),
      );
      _scatterCache[key] = output;
      return output;
    } catch (_) {
      return _scatterCache[key] ?? const DepartmentScatterData(pointsA: [], pointsB: []);
    }
  },
);

String _pairKey(String a, String b) {
  final sorted = [a, b]..sort();
  return '${sorted[0]}__${sorted[1]}';
}