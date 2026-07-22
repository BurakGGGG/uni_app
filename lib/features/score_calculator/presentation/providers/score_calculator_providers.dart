import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../data/calc_history_store.dart';
import '../../domain/models/calc_history_entry.dart';
import '../../domain/models/score_input.dart';
import '../../domain/models/match_result.dart';
import '../../domain/models/multi_score_result.dart';
import '../../domain/score_calculator_engine.dart';
import '../../domain/score_outcome_service.dart';
import '../../../preference_wizard/domain/models/student_score_profile.dart';
import '../../../preference_wizard/domain/preference_match_engine.dart';
import '../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../../university/domain/models/department_model.dart';

/// Tüm unique bölüm isimleri (puan türünden bağımsız)
final uniqueDepartmentNamesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final repo = ref.watch(universityRepositoryProvider);
  final allDepts = await repo.getAllDepartments();

  final uniqueNames = <String>{};
  for (final d in allDepts) {
    if (d.effectiveBaseScore > 0) {
      uniqueNames.add(d.name);
    }
  }

  final sorted = uniqueNames.toList()..sort();
  return sorted;
});

/// Tüm bölümler (flat list, taban puanı olan) — hesaplama için
final allScoredDepartmentsProvider =
    FutureProvider<List<DepartmentModel>>((ref) async {
  ref.keepAlive();
  final repo = ref.read(universityRepositoryProvider);

  final allDepts = await repo.getAllDepartments();

  return allDepts.where((d) => d.effectiveBaseScore > 0).toList();
});

/// Kullanıcının girdiği sınav verileri
final scoreInputProvider = StateProvider<ScoreInput>((ref) {
  return const ScoreInput(
    scoreType: '',
    obpScore: 80,
    selectedDepartment: '',
  );
});

/// v2 ana sonuç: uygulanabilir tüm türlerin puanı + tahmini sıra + dilim.
/// Hesaplanabilir tür yoksa null (UI "Hesapla"yı kapalı tutar).
final multiScoreOutcomeProvider =
    FutureProvider.autoDispose<MultiScoreOutcome?>((ref) async {
  final input = ref.watch(scoreInputProvider);
  if (ScoreCalculatorEngine.applicableScoreTypes(input).isEmpty) return null;

  final estimator = await ref.watch(multiYearRankEstimatorProvider.future);
  return ScoreOutcomeService(estimator: estimator).buildAll(input);
});

/// Yıl karşılaştırması: aynı netler, seçilen türde 2022–2026 puan + sıra.
final yearComparisonProvider = FutureProvider.autoDispose
    .family<List<YearOutcome>, String>((ref, scoreType) async {
  final input = ref.watch(scoreInputProvider);
  final estimator = await ref.watch(multiYearRankEstimatorProvider.future);
  return ScoreOutcomeService(estimator: estimator)
      .yearComparison(input, scoreType);
});

/// Store — `sharedPreferencesProvider` main.dart'ta override edilir.
final calcHistoryStoreProvider = Provider<CalcHistoryStore>((ref) {
  return CalcHistoryStore(ref.watch(sharedPreferencesProvider));
});

/// Deneme geçmişi (en yeni başta, 50 kayıt tavanı).
class CalcHistoryNotifier extends StateNotifier<List<CalcHistoryEntry>> {
  CalcHistoryNotifier(this._store) : super(_store.read());

  final CalcHistoryStore _store;

  /// Sonuç ekranı her açılışta çağırır; aynı girdinin peş peşe kaydı
  /// çoğalmaz (sonuca dön-gel durumu).
  Future<void> add(CalcHistoryEntry entry) async {
    if (state.isNotEmpty &&
        state.first.year == entry.year &&
        jsonEncode(state.first.input.toJson()) ==
            jsonEncode(entry.input.toJson())) {
      return;
    }
    state = [entry, ...state].take(CalcHistoryStore.maxEntries).toList();
    await _store.save(state);
  }

  Future<void> rename(String id, String label) async {
    state = [
      for (final e in state) e.id == id ? e.copyWith(label: label) : e,
    ];
    await _store.save(state);
  }

  Future<void> remove(String id) async {
    state = [
      for (final e in state)
        if (e.id != id) e,
    ];
    await _store.save(state);
  }

  Future<void> clear() async {
    state = const [];
    await _store.clear();
  }
}

final calcHistoryProvider =
    StateNotifierProvider<CalcHistoryNotifier, List<CalcHistoryEntry>>(
  (ref) => CalcHistoryNotifier(ref.watch(calcHistoryStoreProvider)),
);

/// Sonuç ekranında aktif tür (yıl karşılaştırması + bölüm önizleme paylaşır).
/// null → en güçlü tür kullanılır.
final resultSelectedTypeProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// "Girebileceğin bölümler": seçilen türün puanıyla sihirbaz motorunun
/// birebir aynı yolu (geçici profil + matchAllPrograms + rank estimator).
final eligibleProgramsProvider = FutureProvider.autoDispose
    .family<PreferenceMatchResult?, String>((ref, scoreType) async {
  final outcome = await ref.watch(multiScoreOutcomeProvider.future);
  final typeOutcome = outcome?.byType(scoreType);
  if (typeOutcome == null) return null;

  final allDepts = await ref.watch(allScoredDepartmentsProvider.future);
  final allUnis = await ref.watch(allUniversitiesProvider.future);
  final estimator = await ref.watch(rankEstimatorProvider.future);

  final profile = StudentScoreProfile(
    scoreType: scoreType,
    placementScore: typeOutcome.score.placementScore,
    year: DateTime.now().year,
    updatedAt: DateTime.now(),
  );
  return PreferenceMatchEngine.matchAllPrograms(
    profile: profile,
    allDepartments: allDepts,
    allUniversities: allUnis,
    estimator: estimator,
  );
});

/// Opsiyonel hedef bölümün özet kararı.
class TargetDeptVerdict {
  final String departmentName;
  final int guaranteed;
  final int target;
  final int dream;

  /// En yüksek uygunluklu program (kart olarak gösterilir).
  final UniversityMatch best;

  const TargetDeptVerdict({
    required this.departmentName,
    required this.guaranteed,
    required this.target,
    required this.dream,
    required this.best,
  });

  int get total => guaranteed + target + dream;
}

/// Hedef bölüm seçiliyse: o addaki tüm programların sıralama-bazlı
/// değerlendirmesi (kategori sayıları + en iyi program).
final targetDepartmentVerdictProvider =
    FutureProvider.autoDispose<TargetDeptVerdict?>((ref) async {
  final input = ref.watch(scoreInputProvider);
  if (input.selectedDepartment.isEmpty) return null;

  final outcome = await ref.watch(multiScoreOutcomeProvider.future);
  if (outcome == null || outcome.isEmpty) return null;

  final allDepts = await ref.watch(allScoredDepartmentsProvider.future);
  final allUnis = await ref.watch(allUniversitiesProvider.future);
  final estimator = await ref.watch(rankEstimatorProvider.future);
  final uniMap = {for (final u in allUnis) u.id: u};

  final name = input.selectedDepartment.toLowerCase().trim();
  var guaranteed = 0;
  var target = 0;
  var dream = 0;
  UniversityMatch? best;

  for (final dept in allDepts) {
    if (dept.name.toLowerCase().trim() != name) continue;
    final deptType = dept.effectiveScoreType?.toUpperCase();
    if (deptType == null) continue;
    final typeOutcome = outcome.byType(deptType);
    if (typeOutcome == null) continue; // bu türde net girilmemiş
    final uni = uniMap[dept.universityId];
    if (uni == null) continue;

    final profile = StudentScoreProfile(
      scoreType: deptType,
      placementScore: typeOutcome.score.placementScore,
      year: DateTime.now().year,
      updatedAt: DateTime.now(),
    );
    final eval = evaluateDepartment(profile, dept, estimator: estimator);
    if (eval == null) continue;

    switch (eval.category) {
      case MatchCategory.guaranteed:
        guaranteed++;
        break;
      case MatchCategory.target:
        target++;
        break;
      case MatchCategory.dream:
        dream++;
        break;
    }

    final match = UniversityMatch(
      department: dept,
      university: uni,
      category: eval.category,
      departmentBaseScore: dept.effectiveBaseScore,
      departmentRanking: dept.rankingForMatching,
      scoreDifference:
          typeOutcome.score.placementScore - dept.effectiveBaseScore,
      matchBasis: eval.basis,
      fitScore: eval.fit,
      refRankYear: eval.refRankYear,
    );
    if (best == null || (match.fitScore ?? -1) > (best.fitScore ?? -1)) {
      best = match;
    }
  }

  if (best == null) return null;
  return TargetDeptVerdict(
    departmentName: input.selectedDepartment,
    guaranteed: guaranteed,
    target: target,
    dream: dream,
    best: best,
  );
});

