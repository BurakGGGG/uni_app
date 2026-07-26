import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../practice_exams/domain/models/exam_target.dart';
import '../../../practice_exams/domain/practice_exam_analytics.dart';
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
import '../../domain/insights/target_roadmap.dart';
import '../../domain/insights/uni_insight.dart';
import '../../domain/insights/weekly_plan.dart';
import '../../domain/screen_tips.dart';
import '../robot_action_route.dart';
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
    estimatedRank: estimatedRank,
  );
});

/// Susturulmuş notlar ayıklanmış, önceliğe göre sıralı liste.
///
/// Misafirde Denemelerim'e götüren düğmeler düşer ([UniInsight.withoutAction]):
/// o ekran üyelere özel, düğme yalnız giriş duvarına çarptırırdı. Not metni
/// misafire de değerli olduğu için kartın kendisi kalır.
final uniInsightsProvider = Provider<List<UniInsight>>((ref) {
  final ctx = ref.watch(insightContextProvider).valueOrNull;
  if (ctx == null) return const [];
  final memory = ref.watch(robotMemoryProvider);
  final signedIn = ref.watch(authStateProvider).valueOrNull != null;

  return [
    for (final insight in InsightEngine.analyze(ctx))
      if (!insight.dismissible || !memory.isInsightDismissed(insight.id))
        if (signedIn || !robotActionNeedsAccount(insight.action))
          insight
        else
          insight.withoutAction(),
  ];
});

/// Ana sayfa kartının gösterdiği tek not; hiç not yoksa null (kart günün
/// ipucuna düşer).
final topInsightProvider = Provider<UniInsight?>((ref) {
  final all = ref.watch(uniInsightsProvider);
  return all.isEmpty ? null : all.first;
});

/// Açık sekmenin ipucu — yüzen Üni'nin "burası ne işe yarar" repliği.
///
/// Notlardan ayrı bir yol: not kullanıcının verisi hakkında konuşur, ipucu
/// ekran hakkında. Karar saf fonksiyonda ([uniScreenTip]); burada yalnız
/// bağlam toplanıyor.
final uniScreenTipProvider =
    Provider.autoDispose.family<ScreenTip?, String>((ref, path) {
  // Önce "bu ekranın ipucu var mı": ana sayfada boşuna kaynak dinlemeyelim.
  if (!screenHasTip(path)) return null;

  // Bağlam yalnız o sekmenin ihtiyacı kadar toplanır — Keşfet'e bakarken
  // tercih listesi akışına (Firestore) abone olmanın anlamı yok.
  var listCount = 0;
  var hasAnyList = false;

  if (path.startsWith('/my-lists')) {
    final lists = ref.watch(myPreferenceListsProvider).valueOrNull ?? const [];
    hasAnyList = lists.isNotEmpty;
    listCount = lists.isEmpty
        ? 0
        : lists.map((l) => l.items.length).reduce((a, b) => a > b ? a : b);
  }

  return uniScreenTip(
    ScreenTipContext(
      path: path,
      signedIn: ref.watch(authStateProvider).valueOrNull != null,
      hasAnyList: hasAnyList,
      listCount: listCount,
    ),
  );
});

/// Tercih yolunun 4. adımı: listeyle ve ÖSYM verisiyle ilgili uyarılar.
///
/// Kurulum notu (`setup.noProfile`) ve takvim geri sayımı dışarıda kalır —
/// ikisinin de yeri var: kurulum 1. adımın kendisi, takvim de başlıktaki
/// dönem çipi. Aynı cümleyi ekranda iki kez göstermemek için süzülüyorlar.
final pathInsightsProvider = Provider<List<UniInsight>>((ref) {
  return [
    for (final insight in ref.watch(uniInsightsProvider))
      if (insight.kind == InsightKind.list || insight.kind == InsightKind.data)
        insight,
  ];
});

/// "Asıl" tercih listesi — en dolu olan. Kullanıcı 10 liste tutabiliyor;
/// panelin 3. adımı hangisini özetleyeceğini motorun `_list()` kuralıyla
/// AYNI şekilde seçer, yoksa kart ile uyarılar farklı listeden konuşur.
final mainListProvider = Provider<ListSnapshot?>((ref) {
  final ctx = ref.watch(insightContextProvider).valueOrNull;
  final lists = ctx?.lists ?? const <ListSnapshot>[];
  if (lists.isEmpty) return null;
  return lists.reduce((a, b) => b.itemCount > a.itemCount ? b : a);
});

/// Hedef yol haritası — panel bloğu ve `target.roadmap` notu AYNI hesabı
/// paylaşır ([InsightEngine.roadmapFor]); iki yerde ayrı hesaplanırsa kart
/// ile not farklı sayı söyler.
final targetRoadmapProvider = Provider<TargetRoadmap?>((ref) {
  final ctx = ref.watch(insightContextProvider).valueOrNull;
  return ctx == null ? null : InsightEngine.roadmapFor(ctx);
});

/// Hedefe kat edilen yolun oranı. Başlangıç noktası ilk denemenin puanıdır;
/// tek deneme varsa referans yok, null döner.
final targetProgressProvider = Provider<double?>((ref) {
  final roadmap = ref.watch(targetRoadmapProvider);
  if (roadmap == null) return null;
  final ctx = ref.watch(insightContextProvider).valueOrNull;
  if (ctx == null) return null;

  final exams = ctx.liveExams;
  if (exams.length < 2) return null;
  final points = trendFor(exams, roadmap.scoreType, year: exams.first.year);
  final start = points.firstOrNull?.placementScore;
  return roadmap.progress(startScore: start);
});

/// Bu haftanın planı ve işaretlenmiş görevleri.
final weeklyPlanProvider = Provider<WeeklyPlan?>((ref) {
  final ctx = ref.watch(insightContextProvider).valueOrNull;
  if (ctx == null) return null;
  final plan = WeeklyPlanner.build(
    ctx,
    roadmap: ref.watch(targetRoadmapProvider),
  );
  return plan.isEmpty ? null : plan;
});

/// İşaretli görev id'leri; hafta dönünce kendiliğinden boşalır.
final donePlanTasksProvider = Provider<Set<String>>((ref) {
  final plan = ref.watch(weeklyPlanProvider);
  if (plan == null) return const {};
  return ref.watch(robotMemoryProvider).donePlanTasks(plan.weekKey);
});

/// Hedefi olmayan kullanıcı için öneri: tercih listesinin en üstündeki,
/// taban verisi olan ve puan türü tutan program.
///
/// Soğuk başlangıcın en sıkışık adımı hedef seçmek — kullanıcı zaten bir
/// liste kurmuşsa "ilk tercihin hedefin olsun mu?" diye sormak, bölüm adı
/// arayıp üniversite seçtirmekten hızlı.
final suggestedTargetProvider = Provider<ExamTarget?>((ref) {
  if (ref.watch(examTargetProvider) != null) return null;
  final lists = ref.watch(myPreferenceListsProvider).valueOrNull ?? const [];
  if (lists.isEmpty) return null;

  final profileType =
      ref.watch(studentScoreProfileProvider)?.scoreType.toUpperCase() ?? '';

  final main = lists.reduce((a, b) => b.items.length > a.items.length ? b : a);
  final items = [...main.items]..sort((a, b) => a.order.compareTo(b.order));

  for (final item in items) {
    final rank = item.ranking;
    final type = item.scoreType?.toUpperCase() ?? '';
    if (rank == null || rank <= 0 || type.isEmpty) continue;
    if (profileType.isNotEmpty && type != profileType) continue;
    return ExamTarget(
      departmentId: item.deptId,
      departmentName: item.deptName,
      universityName: item.uniName,
      scoreType: type,
      targetRank: rank,
      targetScore: item.baseScore,
      setAt: DateTime.now(),
    );
  }
  return null;
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
