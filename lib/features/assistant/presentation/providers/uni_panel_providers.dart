import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../practice_exams/presentation/providers/practice_exam_providers.dart';
import '../../../preference_lists/domain/models/preference_list_model.dart';
import '../../../preference_lists/presentation/providers/preference_list_providers.dart';
import '../../../preference_wizard/domain/list_health.dart';
import '../../../preference_wizard/domain/models/student_score_profile.dart';
import '../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../../../score_calculator/presentation/providers/score_calculator_providers.dart';
import '../../../university/domain/models/department_model.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../domain/insights/insight_context.dart';
import '../../domain/insights/insight_engine.dart';
import '../../domain/insights/uni_insight.dart';
import 'assistant_providers.dart';

/// İlk 5 tercihte şehir yığılması bu eşikten sonra anlamlı sayılır — motorun
/// eşiğiyle aynı pencereye bakar ([InsightEngine] 4'ten itibaren uyarır).
const int _kCityWindow = 5;

/// Motorun tek girdisi. Ağır kaynaklar (tüm bölümler, üniversiteler) zaten
/// `keepAlive` ve uygulama açılışında prefetch ediliyor; burada yalnız
/// birleştiriliyor.
///
/// Yüklenirken null değil, *bekleyen* bir AsyncValue döner — çağıran yüzeyler
/// (ana sayfa kartı) bu sırada kendi yedeğine düşer.
final insightContextProvider = FutureProvider<InsightContext>((ref) async {
  final profile = ref.watch(studentScoreProfileProvider);
  final exams = ref.watch(practiceExamsProvider);
  final target = ref.watch(examTargetProvider);
  final lists = ref.watch(myPreferenceListsProvider).valueOrNull ?? const [];

  // Liste ve veri aileleri olmadan da anlamlı bir bağlam var (kurulum,
  // gelişim, takvim) — bu yüzden ağır kaynaklar başarısız olursa boş geçilir,
  // panel yine de çalışır.
  List<DepartmentModel> allDepts = const [];
  Map<String, String> cityOfUni = const {};
  Map<String, String> cityNames = const {};
  try {
    allDepts = await ref.watch(allScoredDepartmentsProvider.future);
    final unis = await ref.watch(allUniversitiesProvider.future);
    cityOfUni = {for (final u in unis) u.id: u.cityId};
    final cities = await ref.watch(citiesProvider.future);
    cityNames = {for (final c in cities) c.id: c.name};
  } catch (_) {
    // yut — aşağıdaki anlık görüntüler boş alanlarla kurulur
  }

  final estimator = ref.watch(rankEstimatorProvider).valueOrNull;
  final estimatedRank =
      (profile == null || profile.hasRank || !profile.hasScore)
          ? null
          : estimator?.estimateRank(profile.placementScore, profile.scoreType);

  return InsightContext(
    now: DateTime.now(),
    profile: profile,
    exams: exams,
    target: target,
    lists: [
      for (final list in lists)
        _snapshotOf(
          list,
          profile: profile,
          estimatedRank: estimatedRank,
          cityOfUni: cityOfUni,
          cityNames: cityNames,
        ),
    ],
    tracked: _trackedOf(lists, allDepts),
  );
});

/// Susturulmuş notlar ayıklanmış, önceliğe göre sıralı liste.
final uniInsightsProvider = Provider<List<UniInsight>>((ref) {
  final ctx = ref.watch(insightContextProvider).valueOrNull;
  if (ctx == null) return const [];
  final memory = ref.watch(robotMemoryProvider);
  return [
    for (final insight in InsightEngine.analyze(ctx))
      if (!insight.dismissible || !memory.isInsightDismissed(insight.id))
        insight,
  ];
});

/// Ana sayfa kartının gösterdiği tek not; hiç not yoksa null (kart günün
/// ipucuna düşer).
final topInsightProvider = Provider<UniInsight?>((ref) {
  final all = ref.watch(uniInsightsProvider);
  return all.isEmpty ? null : all.first;
});

/// Panelin 3 adımlı kurulum çubuğu.
final setupPathProvider = Provider<SetupPath>((ref) {
  final ctx = ref.watch(insightContextProvider).valueOrNull;
  if (ctx == null) {
    return const SetupPath(hasProfile: false, hasTarget: false, hasExam: false);
  }
  return InsightEngine.setupPathOf(ctx);
});

// ── Anlık görüntü kurucuları ────────────────────────────────────

/// Firestore modelini motorun anladığı sayılara indirger.
/// Kategorileme `analyzeListHealth` ile yapılır — eşikler orada tanımlı.
ListSnapshot _snapshotOf(
  PreferenceListModel list, {
  required StudentScoreProfile? profile,
  required int? estimatedRank,
  required Map<String, String> cityOfUni,
  required Map<String, String> cityNames,
}) {
  // Profil yoksa kategori sayıları üretilemez; liste yine de sayılır
  // (list.empty / list.incomplete notları profilsiz de anlamlı).
  final report = profile == null
      ? null
      : analyzeListHealth(
          list.items,
          profile,
          estimatedStudentRank: estimatedRank,
        );

  // İlk 5 tercihte en çok geçen şehir.
  final head = [...list.items]..sort((a, b) => a.order.compareTo(b.order));
  final counts = <String, int>{};
  for (final item in head.take(_kCityWindow)) {
    final cityId = cityOfUni[item.uniId];
    if (cityId == null) continue;
    counts[cityId] = (counts[cityId] ?? 0) + 1;
  }
  String? topCityId;
  var topCount = 0;
  counts.forEach((cityId, count) {
    if (count > topCount) {
      topCount = count;
      topCityId = cityId;
    }
  });

  return ListSnapshot(
    listId: list.id,
    title: list.title,
    itemCount: list.items.length,
    guaranteed: report?.guaranteed ?? 0,
    target: report?.target ?? 0,
    dream: report?.dream ?? 0,
    unrated: report?.unrated ?? 0,
    likelyPlacementName: report?.likelyPlacement?.deptName,
    topCityName: topCityId == null ? null : cityNames[topCityId!],
    topCityCount: topCount,
  );
}

/// Listelerdeki programların ÖSYM verisi — taban trendi ve doluluk notları
/// buradan doğar. `PreferenceItem` yalnız son yılı taşıdığı için gerçek
/// bölüm kaydından okunur (hepsi zaten bellekte, ek okuma yok).
List<TrackedProgram> _trackedOf(
  List<PreferenceListModel> lists,
  List<DepartmentModel> allDepts,
) {
  if (lists.isEmpty || allDepts.isEmpty) return const [];

  final wanted = <String>{
    for (final list in lists)
      for (final item in list.items) item.deptId,
  };
  if (wanted.isEmpty) return const [];

  final out = <TrackedProgram>[];
  for (final dept in allDepts) {
    if (!wanted.contains(dept.id)) continue;
    final data = dept.scoreData;
    if (data == null) continue;
    out.add(TrackedProgram(
      departmentId: dept.id,
      departmentName: dept.name,
      universityName: _uniNameFor(dept.id, lists) ?? '',
      baseScoreDelta: data.yearOverYearDelta,
      fillRate: data.quota > 0 ? data.fillRate : null,
    ));
  }
  return out;
}

/// Üniversite adı listede denormalize duruyor — ayrıca sorgulamaya gerek yok.
String? _uniNameFor(String deptId, List<PreferenceListModel> lists) {
  for (final list in lists) {
    for (final item in list.items) {
      if (item.deptId == deptId) return item.uniName;
    }
  }
  return null;
}
