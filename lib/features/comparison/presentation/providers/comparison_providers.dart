import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/ai_comparison_summary_service.dart';
import '../../data/city_comparison_repository.dart';
import '../../data/comparison_repository.dart';
import '../../data/comparison_history_repository.dart';
import '../../data/department_comparison_repository.dart';
import '../../domain/models/city_comparison.dart';
import '../../domain/models/comparison_history_entry.dart';
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

void _comparisonKeepAliveFiveMinutes(Ref ref) {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);
}

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
    FutureProvider.autoDispose<ComparisonGateDecision?>((ref) async {
  _comparisonKeepAliveFiveMinutes(ref);
  final selection = ref.watch(comparisonSelectionProvider);
  if (!selection.bothSelected) return null;
  if (selection.uniIdA == selection.uniIdB) return null;

  final idA = selection.uniIdA!;
  final idB = selection.uniIdB!;

  return ref.read(comparisonGateControllerProvider).guardPair(
        ComparisonPair(idA: idA, idB: idB),
      );
});

/// Karşılaştırma sonucu — her iki uni seçildiğinde otomatik tetiklenir
final comparisonResultProvider =
    FutureProvider.autoDispose<ComparisonResult?>((ref) async {
  _comparisonKeepAliveFiveMinutes(ref);
  final selection = ref.watch(comparisonSelectionProvider);
  if (!selection.bothSelected) return null;
  if (selection.uniIdA == selection.uniIdB) return null;

  final idA = selection.uniIdA!;
  final idB = selection.uniIdB!;

  final gateDecision = await ref.watch(comparisonGateDecisionProvider.future);
  if (gateDecision == null || !gateDecision.isAllowed) return null;

  try {
    final result = await ref.read(comparisonRepositoryProvider).compare(idA, idB);
    if (result != null) {
      // Plus/Pro ise geçmişe ekle (misafir/free sessizce no-op)
      unawaited(_recordHistoryIfEligible(
        ref,
        type: ComparisonHistoryType.university,
        entityAId: result.uniA.id,
        entityBId: result.uniB.id,
        entityAName: result.uniA.name,
        entityBName: result.uniB.name,
        // Üniversite logoları: önce local asset path'i deniyoruz, yoksa
        // (boş string ise) network logoUrl'i kullan.
        entityALogo: result.uniA.logoAssetPath,
        entityBLogo: result.uniB.logoAssetPath,
      ));
    }
    return result;
  } catch (e, st) {
    debugPrint('[comparisonResultProvider] compare failed: $e');
    FirebaseCrashlytics.instance.recordError(
      e,
      st,
      reason: 'comparisonResultProvider failed',
      fatal: false,
    );
    rethrow;
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

// ─── Karşılaştırma Geçmişi ────────────────────────────────────────

final comparisonHistoryRepositoryProvider =
    Provider<ComparisonHistoryRepository>((ref) {
  return ComparisonHistoryRepository();
});

/// Plus/Pro kullanıcı geçmişi kullanabilir mi? (UI gating için)
final canUseComparisonHistoryProvider = Provider<bool>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  return tier.when(
    data: (t) => canUseComparisonHistory(t),
    loading: () => false,
    error: (_, _) => false,
  );
});

/// Geçmiş listesi — real-time stream. Misafir/free kullanıcı için boş döner
/// (UI hep paywall kartı gösterecek).
final comparisonHistoryProvider =
    StreamProvider<List<ComparisonHistoryEntry>>((ref) {
  final canUse = ref.watch(canUseComparisonHistoryProvider);
  if (!canUse) return Stream.value(const <ComparisonHistoryEntry>[]);
  return ref.watch(comparisonHistoryRepositoryProvider).watchHistory();
});

/// Helper: Karşılaştırma başarılıysa ve kullanıcı Plus/Pro ise geçmişe kaydeder.
/// Tier yetersizse veya misafirse sessizce no-op döner (asıl akış bozulmaz).
Future<void> _recordHistoryIfEligible(
  Ref ref, {
  required ComparisonHistoryType type,
  required String entityAId,
  required String entityBId,
  required String entityAName,
  required String entityBName,
  String? entityALogo,
  String? entityBLogo,
}) async {
  if (!ref.read(canUseComparisonHistoryProvider)) return;
  await ref.read(comparisonHistoryRepositoryProvider).recordComparison(
        type: type,
        entityAId: entityAId,
        entityBId: entityBId,
        entityAName: entityAName,
        entityBName: entityBName,
        entityALogo: entityALogo,
        entityBLogo: entityBLogo,
      );
}

final departmentComparisonResultProvider =
    FutureProvider.autoDispose.family<DepartmentComparisonResult?, ComparisonPair>(
        (ref, pair) async {
  _comparisonKeepAliveFiveMinutes(ref);
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
    if (result != null) {
      // Bölümler için: bağlı oldukları üniversitenin logosu (varsa).
      // department.universityId üzerinden lookup.
      String? logoForDept(DepartmentModel dept) {
        final uniId = dept.universityId;
        if (uniId.isEmpty) return null;
        return 'assets/logos/$uniId.png';
      }
      unawaited(_recordHistoryIfEligible(
        ref,
        type: ComparisonHistoryType.department,
        entityAId: result.deptA.id,
        entityBId: result.deptB.id,
        entityAName: result.deptA.name,
        entityBName: result.deptB.name,
        entityALogo: logoForDept(result.deptA),
        entityBLogo: logoForDept(result.deptB),
      ));
    }
    return result;
  } catch (e, st) {
    debugPrint('[DepartmentComparison] compare failed for $key: $e');
    FirebaseCrashlytics.instance.recordError(
      e,
      st,
      reason: 'departmentComparisonResultProvider failed',
      fatal: false,
    );
    return null;
  }
});

final cityComparisonResultProvider =
    FutureProvider.autoDispose.family<CityComparisonResult?, ComparisonPair>(
        (ref, pair) async {
  _comparisonKeepAliveFiveMinutes(ref);
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
    if (result != null) {
      unawaited(_recordHistoryIfEligible(
        ref,
        type: ComparisonHistoryType.city,
        entityAId: result.cityA.id,
        entityBId: result.cityB.id,
        entityAName: result.cityA.name,
        entityBName: result.cityB.name,
        entityALogo: result.cityA.logoAssetPath,
        entityBLogo: result.cityB.logoAssetPath,
      ));
    }
    return result;
  } catch (e, st) {
    debugPrint('[CityComparison] compare failed for $key: $e');
    FirebaseCrashlytics.instance.recordError(
      e,
      st,
      reason: 'cityComparisonResultProvider failed',
      fatal: false,
    );
    return null;
  }
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
    FutureProvider.autoDispose<List<UniversityModel>>((ref) async {
  _comparisonKeepAliveFiveMinutes(ref);
  final repository = UniversityRepository();
  return repository.getAllUniversities();
});

final departmentPickerDepartmentsProvider =
    FutureProvider.autoDispose<List<DepartmentModel>>((ref) async {
  _comparisonKeepAliveFiveMinutes(ref);
  final filter = ref.watch(departmentPickerFilterProvider);
  final repository = UniversityRepository();

  List<DepartmentModel> departments;
  final uniId = filter.universityId;
  if (uniId != null && uniId.isNotEmpty) {
    departments = await repository.getDepartmentsByUniversity(uniId);
  } else {
    final universities = await repository.getAllUniversities();
    final departmentLists = await Future.wait(
      universities.map((u) => repository.getDepartmentsByUniversity(u.id)),
    );
    departments = departmentLists.expand((e) => e).toList();
  }

  final normalizedQuery = filter.query.trim().toLowerCase();
  final filtered = departments.where((d) {
    final scoreType = d.effectiveScoreType ?? '';
    final filterScore = filter.scoreType;
    final matchesScoreType = filterScore == null ||
        filterScore.isEmpty ||
        scoreType == filterScore;

    final matchesQuery = normalizedQuery.isEmpty ||
        d.name.toLowerCase().contains(normalizedQuery) ||
        d.faculty.toLowerCase().contains(normalizedQuery);

    return matchesScoreType && matchesQuery;
  }).toList();

  filtered.sort((a, b) {
    final aScore = a.effectiveBaseScore ?? 0;
    final bScore = b.effectiveBaseScore ?? 0;
    if (aScore != bScore) return bScore.compareTo(aScore);
    return a.name.compareTo(b.name);
  });

  return filtered;
});

final departmentPickerAvailableScoreTypesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  _comparisonKeepAliveFiveMinutes(ref);
  final departments = await ref.watch(departmentPickerDepartmentsProvider.future);
  final scoreTypes = departments
      .map((d) => (d.effectiveScoreType ?? '').trim())
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

/// Regenerate tetikleyicisi — her increment'te provider yeniden çalışır.
final _aiRegenerateTriggerProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Regenerate modunda mı?
final _aiRegenerateActiveProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Bu session'da regenerate hakkı kullanılmış cache key'lerini tutar.
/// UI bu set'i kontrol ederek butonu gizler — server zaten kalıcı tutuyor,
/// bu sadece UX için (kullanıcı buton kayboldu/kullanılmaz görsün).
final regenerateUsedPairsProvider =
    StateProvider<Set<String>>((ref) => <String>{});

/// Regenerate sonucu UI'a tek seferlik feedback mesajı.
/// UI listen ile yakalayıp snackbar gösterir ve null'a resetler.
class RegenerateFeedback {
  final String message;
  final bool isError;
  // Aynı mesajın art arda tetiklenmesini ayırt etmek için (ScaffoldMessenger
  // aynı objeyi 2. kez göstermeyebilir). Her instance benzersiz tag taşır.
  final int tag;
  const RegenerateFeedback({
    required this.message,
    required this.isError,
    required this.tag,
  });
}

final regenerateFeedbackProvider =
    StateProvider<RegenerateFeedback?>((ref) => null);

final aiComparisonSummaryProvider =
    FutureProvider.autoDispose<AiComparisonSummaryResult?>((ref) async {
  _comparisonKeepAliveFiveMinutes(ref);
  final canUseAi = ref.watch(canUseAiComparisonProvider);
  if (!canUseAi) return null;

  // Regenerate trigger'ı dinle — değişince provider yeniden çalışır
  ref.watch(_aiRegenerateTriggerProvider);
  final regenerate = ref.read(_aiRegenerateActiveProvider);

  final result = await ref.watch(comparisonResultProvider.future);
  if (result == null) return null;

  final pairKey = _pairKey(result.uniA.id, result.uniB.id);
  final service = ref.read(aiComparisonSummaryServiceProvider);
  try {
    final summary = await service.summarizeUniversityComparison(
      result,
      regenerate: regenerate,
    );
    if (regenerate) {
      // Regenerate başarılı — flag'i sıfırla, set'e ekle (UI butonu gizlesin),
      // kullanıcıya feedback ver.
      ref.read(_aiRegenerateActiveProvider.notifier).state = false;
      ref.read(regenerateUsedPairsProvider.notifier).update((set) => {...set, pairKey});
      ref.read(regenerateFeedbackProvider.notifier).state = RegenerateFeedback(
        message: 'Özet yeniden üretildi',
        isError: false,
        tag: DateTime.now().microsecondsSinceEpoch,
      );
    }
    return summary;
  } on AiSummaryRegenerateAlreadyUsed {
    // Server reddetti — kullanıcı bu çift için zaten regenerate yapmış.
    // Flag'i sıfırla, set'e ekle, kullanıcıya feedback ver, eski özeti
    // (cache'den) almak için non-regenerate istek yap.
    ref.read(_aiRegenerateActiveProvider.notifier).state = false;
    ref.read(regenerateUsedPairsProvider.notifier).update((set) => {...set, pairKey});
    ref.read(regenerateFeedbackProvider.notifier).state = RegenerateFeedback(
      message: 'Bu karşılaştırma için yeniden üretme hakkını zaten kullandın.',
      isError: true,
      tag: DateTime.now().microsecondsSinceEpoch,
    );
    return service.summarizeUniversityComparison(result, regenerate: false);
  } on AiSummaryQuotaExceeded {
    // UI bu durumu özel olarak işleyecek (limit_reached state)
    rethrow;
  } on AiSummaryFailure catch (e) {
    debugPrint('[aiComparisonSummaryProvider] failed: ${e.userMessage}');
    rethrow;
  } catch (e, st) {
    debugPrint('[aiComparisonSummaryProvider] unknown error: $e');
    FirebaseCrashlytics.instance.recordError(
      e,
      st,
      reason: 'aiComparisonSummaryProvider unknown error',
      fatal: false,
    );
    rethrow;
  }
});

/// Regenerate tetikleme fonksiyonu — UI'dan çağrılır.
void triggerAiRegenerate(WidgetRef ref) {
  ref.read(_aiRegenerateActiveProvider.notifier).state = true;
  ref.read(_aiRegenerateTriggerProvider.notifier).state++;
}


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

// ─── 4.6: Tipli Trend State ────────────────────────────────────────
sealed class TrendDataState {
  const TrendDataState();
}

class TrendDataSuccess extends TrendDataState {
  final List<RatingTrendPoint> points;
  const TrendDataSuccess(this.points);
}

class TrendDataInsufficient extends TrendDataState {
  /// "Trend için yeterli yorum yok" durumu
  final int reviewCount;
  const TrendDataInsufficient(this.reviewCount);
}

class TrendDataError extends TrendDataState {
  final String userMessage;
  const TrendDataError(this.userMessage);
}

final ratingTrendProvider =
    FutureProvider.autoDispose.family<TrendDataState, ComparisonPair>(
  (ref, pair) async {
    _comparisonKeepAliveFiveMinutes(ref);
    final canUse = ref.watch(canUseProComparisonChartsProvider);
    if (!canUse) return const TrendDataInsufficient(0);

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

      // Tüm aylar sıfırsa → yeterli yorum yok
      if (output.every((p) => p.avgRatingA == 0 && p.avgRatingB == 0)) {
        return const TrendDataInsufficient(0);
      }

      return TrendDataSuccess(output);
    } catch (e, st) {
      debugPrint('[ratingTrendProvider] aggregation failed: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'ratingTrendProvider Firestore aggregation failed',
        fatal: false,
      );
      return const TrendDataError('Trend verisi şu anda yüklenemiyor.');
    }
  },
);

final categoryHeatMapProvider =
    FutureProvider.autoDispose.family<List<CategoryHeatMapCell>, ComparisonPair>(
  (ref, pair) async {
    _comparisonKeepAliveFiveMinutes(ref);
    final canUse = ref.watch(canUseProComparisonChartsProvider);
    if (!canUse) return const [];

    try {
      final repo = UniversityRepository();
      final results = await Future.wait([
        repo.getUniversity(pair.idA),
        repo.getUniversity(pair.idB),
      ]);
      final uniA = results[0];
      final uniB = results[1];
      if (uniA == null || uniB == null) return const [];

      final categories = <String>{
        ...uniA.categoryRatings.keys,
        ...uniB.categoryRatings.keys,
      }.toList()
        ..sort();

      return categories
          .map(
            (category) => CategoryHeatMapCell(
              category: category,
              valueA: (uniA.categoryRatings[category] ?? 0).toDouble(),
              valueB: (uniB.categoryRatings[category] ?? 0).toDouble(),
            ),
          )
          .toList();
    } catch (e, st) {
      debugPrint('[categoryHeatMapProvider] failed: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'categoryHeatMapProvider failed',
        fatal: false,
      );
      return const [];
    }
  },
);

final departmentScatterProvider =
    FutureProvider.autoDispose.family<DepartmentScatterData, ComparisonPair>(
  (ref, pair) async {
    _comparisonKeepAliveFiveMinutes(ref);
    final canUse = ref.watch(canUseProComparisonChartsProvider);
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
            .map((d) {
              final baseScore = d.effectiveBaseScore;
              final ranking = d.effectiveRanking;
              if (baseScore == null ||
                  ranking == null ||
                  baseScore <= 0 ||
                  ranking <= 0) {
                return null;
              }
              return DepartmentScatterPoint(
                departmentId: d.id,
                departmentName: d.name,
                baseScore: baseScore,
                ranking: ranking,
                universityId: universityId,
              );
            })
            .whereType<DepartmentScatterPoint>()
            .toList();
      }

      return DepartmentScatterData(
        pointsA: mapPoints(departmentLists[0], pair.idA),
        pointsB: mapPoints(departmentLists[1], pair.idB),
      );
    } catch (e, st) {
      debugPrint('[departmentScatterProvider] failed: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'departmentScatterProvider failed',
        fatal: false,
      );
      return const DepartmentScatterData(pointsA: [], pointsB: []);
    }
  },
);

String _pairKey(String a, String b) {
  final sorted = [a, b]..sort();
  return '${sorted[0]}__${sorted[1]}';
}