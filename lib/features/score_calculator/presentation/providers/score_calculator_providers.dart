import 'package:flutter_riverpod/flutter_riverpod.dart';
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
/// Hedef bölüm seçicisinin listesi. [scoreType] doluysa yalnız o türde
/// okutulan bölümler döner — sıra modunda TYT seçen kullanıcıya SAY bölümü
/// önermek yanıltıcı olurdu.
final uniqueDepartmentNamesProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, scoreType) async {
  // Repoyu ikinci kez okumak yerine zaten bellekte tutulan listeden türetilir.
  final allDepts = await ref.watch(allScoredDepartmentsProvider.future);
  final wanted = scoreType.trim().toUpperCase();

  final uniqueNames = <String>{};
  for (final d in allDepts) {
    if (wanted.isNotEmpty && d.effectiveScoreType?.toUpperCase() != wanted) {
      continue;
    }
    uniqueNames.add(d.name);
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
/// Sıra modunda soru tersine döner — aynı sıra hangi yıl kaç puan ederdi;
/// puan modunda ise aynı puan hangi yıl kaçıncı sıra ederdi.
final yearComparisonProvider = FutureProvider.autoDispose
    .family<List<YearOutcome>, String>((ref, scoreType) async {
  final input = ref.watch(scoreInputProvider);
  final estimator = await ref.watch(multiYearRankEstimatorProvider.future);
  final service = ScoreOutcomeService(estimator: estimator);
  if (input.isRankMode) {
    if (!input.hasValidRank) return const [];
    return service.rankYearComparison(input.enteredRank!, scoreType);
  }
  if (input.isScoreMode) {
    if (!input.hasValidScore) return const [];
    return service.scoreYearComparison(input.enteredScore!, scoreType);
  }
  return service.yearComparison(input, scoreType);
});

/// Sonuç ekranında aktif tür (yıl karşılaştırması + bölüm önizleme paylaşır).
/// null → en güçlü tür kullanılır.
final resultSelectedTypeProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// Geçici profile yalnız KULLANICININ girdiği sıra yazılır. Puandan tahmin
/// edilen sıra yazılmaz: motor onu kendi hesaplar ve belirsizlik düzeltmesini
/// (`kEstimatedRankPullToMid`) uygular. Gerçek sıra girildiğinde ise o
/// düzeltme atlanmalı, kategoriler keskinleşmeli.
int? _userRankOf(ScoreTypeOutcome outcome) =>
    outcome.rankIsUserEntered ? outcome.estimatedRank : null;

/// Hesaplama sonucundan kalıcı öğrenci profili.
///
/// Sonuç ekranı ve tercih yolu akışı AYNI dönüşümü kullanır — iki yerde ayrı
/// kurulsaydı biri tahmini sırayı yazıp öteki yazmaz, eşleştirme yüzeyleri
/// sessizce farklı kategoriler gösterirdi.
StudentScoreProfile profileFromOutcome(
  String scoreType,
  ScoreTypeOutcome outcome,
) {
  return StudentScoreProfile(
    scoreType: scoreType,
    placementScore: outcome.score.placementScore,
    rank: _userRankOf(outcome),
    // Robot giriş ekranıyla aynı: profil yılı = bu yıl.
    year: DateTime.now().year,
    updatedAt: DateTime.now(),
  );
}

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
    rank: _userRankOf(typeOutcome),
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

/// Hedef bölüm önizlemesinde gösterilen program sayısı. Tam liste tercih
/// robotunda (`deptQuery` bölüm adına ayarlanarak açılır).
const int kTargetDeptPreviewCount = 5;

/// Önizlemenin kategori başına ilk tur payı. Beş kartın da aynı kategoriden
/// gelip "🟡 8 program" yazısını karşılıksız bırakmaması için.
const Map<MatchCategory, int> kTargetDeptPreviewQuota = {
  MatchCategory.guaranteed: 2,
  MatchCategory.target: 2,
  MatchCategory.dream: 1,
};

/// Opsiyonel hedef bölümün özet kararı.
class TargetDeptVerdict {
  final String departmentName;

  /// Hedefin değerlendirildiği puan türü — "tümünü gör" aktarımı bu türle
  /// yapılır.
  final String scoreType;

  final int guaranteed;
  final int target;
  final int dream;

  /// Ekranda gösterilen programlar (en çok [kTargetDeptPreviewCount]).
  ///
  /// Eskiden burada tek bir "en uygun" program vardı: öğrenci hedef bölümü
  /// için tek öneri görüp altındaki genel listede başka bölümlerden onlarca
  /// kart buluyordu (kullanıcı geri bildirimi).
  final List<UniversityMatch> top;

  const TargetDeptVerdict({
    required this.departmentName,
    required this.scoreType,
    required this.guaranteed,
    required this.target,
    required this.dream,
    required this.top,
  });

  int get total => guaranteed + target + dream;

  /// Listenin başındaki program — sana en uygun görüneni.
  UniversityMatch get best => top.first;

  /// Önizlemenin dışında kalan program sayısı.
  int get hiddenCount => total - top.length;
}

/// Hedef bölümün programlarını kategori içinde sıralar.
///
/// Tercih robotuyla aynı mantık (`PreferenceMatchEngine._sortCategory`,
/// `WizardSort.fit`): yüksek şanslılarda sınıra EN YAKIN olan başa gelir —
/// öğrencinin güvenle girebileceği en iyi program odur; diğer kategorilerde
/// en ulaşılabilir olan başa gelir.
void _sortTargetDept(List<UniversityMatch> list, {required bool isGuaranteed}) {
  list.sort((a, b) {
    final fa = a.fitScore?.toDouble() ?? (isGuaranteed ? 101 : -1);
    final fb = b.fitScore?.toDouble() ?? (isGuaranteed ? 101 : -1);
    final c = isGuaranteed ? fa.compareTo(fb) : fb.compareTo(fa);
    if (c != 0) return c;
    // Eğrinin tabanına yığılan programlarda (hepsi aynı fit) ayırt edici
    // kalan tek şey puana yakınlık — motordaki tie-break'in aynısı.
    if (!isGuaranteed) {
      final d = a.scoreDifference.abs().compareTo(b.scoreDifference.abs());
      if (d != 0) return d;
    }
    return b.departmentBaseScore.compareTo(a.departmentBaseScore);
  });
}

/// Kategori dengeli önizleme: önce her kategorinin payı, sonra artan
/// kontenjan aynı öncelik sırasıyla doldurulur.
List<UniversityMatch> _pickTargetDeptPreview(
  Map<MatchCategory, List<UniversityMatch>> byCategory,
) {
  const order = [
    MatchCategory.guaranteed,
    MatchCategory.target,
    MatchCategory.dream,
  ];
  final picked = <UniversityMatch>[];
  for (final c in order) {
    picked.addAll(byCategory[c]!.take(kTargetDeptPreviewQuota[c]!));
  }
  for (final c in order) {
    if (picked.length >= kTargetDeptPreviewCount) break;
    picked.addAll(
      byCategory[c]!
          .skip(kTargetDeptPreviewQuota[c]!)
          .take(kTargetDeptPreviewCount - picked.length),
    );
  }
  return picked;
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
  final byCategory = {
    for (final c in MatchCategory.values) c: <UniversityMatch>[],
  };

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
      rank: _userRankOf(typeOutcome),
      year: DateTime.now().year,
      updatedAt: DateTime.now(),
    );
    final eval = evaluateDepartment(profile, dept, estimator: estimator);
    if (eval == null) continue;

    byCategory[eval.category]!.add(
      UniversityMatch(
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
      ),
    );
  }

  for (final entry in byCategory.entries) {
    _sortTargetDept(
      entry.value,
      isGuaranteed: entry.key == MatchCategory.guaranteed,
    );
  }
  final top = _pickTargetDeptPreview(byCategory);
  if (top.isEmpty) return null;

  return TargetDeptVerdict(
    departmentName: input.selectedDepartment,
    scoreType: top.first.department.effectiveScoreType!.toUpperCase(),
    guaranteed: byCategory[MatchCategory.guaranteed]!.length,
    target: byCategory[MatchCategory.target]!.length,
    dream: byCategory[MatchCategory.dream]!.length,
    top: top,
  );
});

