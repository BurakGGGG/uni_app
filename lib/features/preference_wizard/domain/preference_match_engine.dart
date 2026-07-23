import 'dart:math' as math;

import '../../score_calculator/domain/models/match_result.dart';
import '../../university/domain/models/department_model.dart';
import '../../university/domain/models/university_model.dart';
import 'match_constants.dart';
import 'models/student_score_profile.dart';
import 'models/wizard_filter.dart';
import 'models/wizard_prefs.dart';
import 'rank_estimator.dart';
import 'similar_programs.dart';

// ═══════════════════════════════════════════════════════════════
//  Saf kategorileme + uygunluk (fit) fonksiyonları
//  Çok-programlı motor, tek-program uygunluk rozeti ve liste sağlığı
//  aynı fonksiyonları kullanır. Kalibrasyon: match_constants.dart.
// ═══════════════════════════════════════════════════════════════

/// (öğrenciSırası / programTabanSırası) oranını 0-100 temel fit'ine çevirir.
/// Parçalı doğrusal — çapalar [kFitCurveAnchors].
double baseFitForRatio(double ratio) {
  final anchors = kFitCurveAnchors;
  if (ratio <= anchors.first.ratio) return anchors.first.fit;
  for (var i = 1; i < anchors.length; i++) {
    if (ratio <= anchors[i].ratio) {
      final a = anchors[i - 1];
      final b = anchors[i];
      final t = (ratio - a.ratio) / (b.ratio - a.ratio);
      return a.fit + (b.fit - a.fit) * t;
    }
  }
  return kFitFloor;
}

/// Fit skorundan üçlü kategori.
MatchCategory categoryForFit(int fit) {
  if (fit >= kFitGuaranteedMin) return MatchCategory.guaranteed;
  if (fit >= kFitTargetMin) return MatchCategory.target;
  return MatchCategory.dream;
}

/// Sürekli uygunluk skoru (0-100): temel eğri + sınırlı düzelticiler.
///
/// Düzeltici sırası sabittir (bkz. match_constants.dart): trend → boş
/// kontenjan → oynaklık → bayat yıl → tahmini sıra → kelepçe. Çok sıkılaşan
/// bir program hem trend cezası hem oynaklık çekmesi yiyebilir — bilinçli:
/// hızla sıkılaşan program gerçekten daha risklidir.
int computeFit({
  required int studentRank,
  required int programRank,
  int? previousProgramRank,
  bool estimatedBasis = false,
  bool staleReference = false,
  int? quota,
  int? placedCount,
}) {
  var fit = baseFitForRatio(studentRank / programRank);

  final hasPrev = previousProgramRank != null && previousProgramRank > 0;
  if (hasPrev) {
    final trend = programRank / previousProgramRank;
    if (trend < kTrendTightenRatio) {
      fit += kTrendTightenDelta;
    } else if (trend > kTrendRelaxRatio) {
      fit += kTrendRelaxDelta;
    }
  }

  if (quota != null && quota > 0 && placedCount != null && placedCount < quota) {
    fit += kEmptySeatsDelta;
  }

  if (hasPrev &&
      math.log(programRank / previousProgramRank).abs() >
          kVolatilityLnThreshold) {
    fit += (kFitUncertainMid - fit) * kVolatilityPullToMid;
  }
  if (staleReference) {
    fit += (kFitUncertainMid - fit) * kStaleYearPullToMid;
  }
  if (estimatedBasis) {
    fit += (kFitUncertainMid - fit) * kEstimatedRankPullToMid;
  }

  return fit.round().clamp(kFitMin, kFitMax);
}

/// Taban puan farkına göre kategori — SON ÇARE yolu.
///
/// Yıllar arası puan enflasyonu nedeniyle kaba bir yaklaşımdır (2024→2025'te
/// programların %78'inin tabanı ≥1 puan yükseldi); sıra sinyali kurulabilen
/// her durumda sıra-bazlı yol tercih edilir. `ScoreCalculatorEngine` da bu
/// fonksiyonu kullanır.
MatchCategory categorizeByScore(double placementScore, double baseScore) {
  final diff = placementScore - baseScore;
  if (diff >= kScoreDiffGuaranteedMin) return MatchCategory.guaranteed;
  if (diff >= kScoreDiffTargetMin) return MatchCategory.target;
  return MatchCategory.dream;
}

/// Başarı sıralaması oranına göre kategori (küçük sıralama = daha iyi).
/// Temel fit eğrisinden türer — düzelticiler uygulanmaz (iki argümanlık saf
/// imza korunur; rozet ve liste sağlığı bu yolu kullanır).
MatchCategory categorizeByRank(int studentRank, int programRank) {
  if (programRank <= 0) {
    // Referans yoksa kategori verilemez — güvenli taraf: hedef.
    return MatchCategory.target;
  }
  return categoryForFit(baseFitForRatio(studentRank / programRank).round());
}

/// Öğrencinin eşleştirmede kullanılacak sırası: gerçek sıra varsa o; yoksa
/// puandan tahmin (tahminci verilmişse). Hiçbiri kurulamazsa null.
({int rank, MatchBasis basis})? resolveStudentRank(
  StudentScoreProfile profile, {
  RankEstimator? estimator,
}) {
  if (profile.hasRank) {
    return (rank: profile.rank!, basis: MatchBasis.rank);
  }
  if (profile.hasScore && estimator != null) {
    final estimated =
        estimator.estimateRank(profile.placementScore, profile.scoreType);
    if (estimated != null) {
      return (rank: estimated, basis: MatchBasis.estimatedRank);
    }
  }
  return null;
}

/// Bir programın profile göre tam değerlendirmesi: kategori + sinyal + fit +
/// referans yıl. Hiçbir sinyal kurulamazsa null — çağıran programı atlar.
///
/// Öncelik: sıra (gerçek → tahmini) → taban puan farkı (son çare, fit yok).
({MatchCategory category, MatchBasis basis, int? fit, int? refRankYear})?
    evaluateDepartment(
  StudentScoreProfile profile,
  DepartmentModel dept, {
  RankEstimator? estimator,
}) {
  final ref = dept.rankingForMatchingWithYear;
  final student = resolveStudentRank(profile, estimator: estimator);

  if (student != null && ref != null) {
    final sd = dept.scoreData;
    final stale = ref.year != 0 && sd != null && ref.year < sd.year;
    final fit = computeFit(
      studentRank: student.rank,
      programRank: ref.rank,
      previousProgramRank: dept.previousRankingForMatching,
      estimatedBasis: student.basis == MatchBasis.estimatedRank,
      staleReference: stale,
      quota: sd?.quota,
      placedCount: sd?.placedCount,
    );
    return (
      category: categoryForFit(fit),
      basis: student.basis,
      fit: fit,
      refRankYear: ref.year == 0 ? null : ref.year,
    );
  }

  if (!profile.hasScore) return null;
  return (
    category:
        categorizeByScore(profile.placementScore, dept.effectiveBaseScore),
    basis: MatchBasis.score,
    fit: null,
    refRankYear: null,
  );
}

/// Geriye uyumlu ince sarmalayıcı — kategori + sinyal.
({MatchCategory category, MatchBasis basis})? categorizeDepartment(
  StudentScoreProfile profile,
  DepartmentModel dept, {
  RankEstimator? estimator,
}) {
  final eval = evaluateDepartment(profile, dept, estimator: estimator);
  if (eval == null) return null;
  return (category: eval.category, basis: eval.basis);
}

// ═══════════════════════════════════════════════════════════════
//  Sonuç kabı
// ═══════════════════════════════════════════════════════════════

class PreferenceMatchResult {
  final List<UniversityMatch> guaranteed;
  final List<UniversityMatch> target;
  final List<UniversityMatch> dream;

  const PreferenceMatchResult({
    required this.guaranteed,
    required this.target,
    required this.dream,
  });

  int get total => guaranteed.length + target.length + dream.length;

  List<UniversityMatch> forCategory(MatchCategory c) {
    switch (c) {
      case MatchCategory.guaranteed:
        return guaranteed;
      case MatchCategory.target:
        return target;
      case MatchCategory.dream:
        return dream;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  Çok-programlı eşleştirme motoru
// ═══════════════════════════════════════════════════════════════

class PreferenceMatchEngine {
  const PreferenceMatchEngine._();

  /// Öğrenci profilini TÜM programlarla eşleştirir, kategorize sonuç döner.
  ///
  /// Yalnızca profilin puan türüyle aynı türdeki (TYT→TYT) ve taban puanı olan
  /// programlar değerlendirilir — farklı türdeki taban puanı karşılaştırması
  /// anlamsızdır. [estimator] verilirse puanla giren öğrencinin sırası tahmin
  /// edilir ve eşleştirme sıra-bazlı yapılır (birincil yol). [prefs] yumuşak
  /// sinyaldir: uygunluk sıralamasında öne çeker, elemez (bkz. WizardPrefs).
  static PreferenceMatchResult matchAllPrograms({
    required StudentScoreProfile profile,
    required List<DepartmentModel> allDepartments,
    required List<UniversityModel> allUniversities,
    WizardFilter filter = const WizardFilter(),
    RankEstimator? estimator,
    WizardPrefs? prefs,
  }) {
    final uniMap = {for (final u in allUniversities) u.id: u};
    final targetType = profile.scoreType.toUpperCase();
    final query = filter.deptQuery.trim().toLowerCase();

    final guaranteed = <UniversityMatch>[];
    final target = <UniversityMatch>[];
    final dream = <UniversityMatch>[];

    for (final dept in allDepartments) {
      final baseScore = dept.effectiveBaseScore;
      if (baseScore <= 0) continue;

      final deptType = dept.effectiveScoreType?.toUpperCase();
      if (deptType == null || deptType != targetType) continue;

      final uni = uniMap[dept.universityId];
      if (uni == null) continue;

      // ── Filtreler ──
      if (filter.cityIds.isNotEmpty && !filter.cityIds.contains(uni.cityId)) {
        continue;
      }
      if (filter.uniTypes.isNotEmpty && !filter.uniTypes.contains(uni.type)) {
        continue;
      }
      if (filter.languages.isNotEmpty &&
          !filter.languages.contains(dept.language)) {
        continue;
      }
      if (filter.programTypes.isNotEmpty &&
          !filter.programTypes.contains(dept.type)) {
        continue;
      }
      if (filter.onlyScholarship &&
          !(dept.description?.contains('Burslu') ?? false)) {
        continue;
      }
      if (query.isNotEmpty &&
          !dept.name.toLowerCase().contains(query) &&
          !dept.faculty.toLowerCase().contains(query)) {
        continue;
      }

      final eval = evaluateDepartment(profile, dept, estimator: estimator);
      if (eval == null) continue; // hiçbir sinyal kurulamadı
      final match = UniversityMatch(
        department: dept,
        university: uni,
        category: eval.category,
        departmentBaseScore: baseScore,
        departmentRanking: dept.rankingForMatching,
        scoreDifference:
            profile.hasScore ? profile.placementScore - baseScore : 0,
        matchBasis: eval.basis,
        fitScore: eval.fit,
        refRankYear: eval.refRankYear,
      );

      switch (eval.category) {
        case MatchCategory.guaranteed:
          guaranteed.add(match);
          break;
        case MatchCategory.target:
          target.add(match);
          break;
        case MatchCategory.dream:
          dream.add(match);
          break;
      }
    }

    final boost = _prefBoostFor(prefs);
    _sortCategory(guaranteed, filter.sort, isGuaranteed: true, boost: boost);
    _sortCategory(target, filter.sort, isGuaranteed: false, boost: boost);
    _sortCategory(dream, filter.sort, isGuaranteed: false, boost: boost);

    return PreferenceMatchResult(
      guaranteed: guaranteed,
      target: target,
      dream: dream,
    );
  }

  /// Yumuşak tercih bonusu hesaplayıcısı; tercih yoksa null (sıfır maliyet).
  static double Function(UniversityMatch)? _prefBoostFor(WizardPrefs? prefs) {
    if (prefs == null || prefs.isEmpty) return null;
    final interestNames = namesForInterests(prefs.interestKeys);
    return (m) {
      var bonus = 0.0;
      if (prefs.cityIds.contains(m.university.cityId)) {
        bonus += kPrefCityBoost;
      }
      if (prefs.uniTypes.contains(m.university.type)) {
        bonus += kPrefUniTypeBoost;
      }
      if (prefs.languages.contains(m.department.language)) {
        bonus += kPrefLanguageBoost;
      }
      if (interestNames.isNotEmpty &&
          interestNames.contains(normalizeProgramName(m.department.name))) {
        bonus += kPrefInterestBoost;
      }
      return bonus;
    };
  }

  static void _sortCategory(
    List<UniversityMatch> list,
    WizardSort sort, {
    required bool isGuaranteed,
    double Function(UniversityMatch)? boost,
  }) {
    switch (sort) {
      case WizardSort.baseDesc:
        list.sort(
          (a, b) => b.departmentBaseScore.compareTo(a.departmentBaseScore),
        );
        break;
      case WizardSort.rankAsc:
        // İyi (küçük) sıralama önce; sıralaması olmayan programlar sona.
        list.sort((a, b) {
          final ra = a.departmentRanking;
          final rb = b.departmentRanking;
          final va = (ra != null && ra > 0) ? ra : null;
          final vb = (rb != null && rb > 0) ? rb : null;
          if (va == null && vb == null) {
            return b.departmentBaseScore.compareTo(a.departmentBaseScore);
          }
          if (va == null) return 1;
          if (vb == null) return -1;
          return va.compareTo(vb);
        });
        break;
      case WizardSort.fit:
        // Tercih bonusu karşılaştırma başına değil, bir kez hesaplanır.
        final bonusById = boost == null
            ? null
            : {for (final m in list) m.department.id: boost(m)};
        double bonusOf(UniversityMatch m) =>
            bonusById?[m.department.id] ?? 0;

        if (isGuaranteed) {
          // Sınıra yakın (en "değerli" güvenli) tercihler önce; fit'i
          // olmayanlar (puan-farkı yolu) sona, kendi içinde taban desc.
          // Bonus küçük anahtarı daha da küçültür → tercih edilen öne gelir.
          list.sort((a, b) {
            final ka = (a.fitScore?.toDouble() ?? 101) - bonusOf(a);
            final kb = (b.fitScore?.toDouble() ?? 101) - bonusOf(b);
            final c = ka.compareTo(kb);
            if (c != 0) return c;
            return b.departmentBaseScore.compareTo(a.departmentBaseScore);
          });
        } else {
          // En ulaşılabilir olan önce (fit desc); fit yoksa puana en yakın.
          list.sort((a, b) {
            final ka = (a.fitScore?.toDouble() ?? -1) + bonusOf(a);
            final kb = (b.fitScore?.toDouble() ?? -1) + bonusOf(b);
            final c = kb.compareTo(ka);
            if (c != 0) return c;
            final d =
                a.scoreDifference.abs().compareTo(b.scoreDifference.abs());
            if (d != 0) return d;
            return b.departmentBaseScore.compareTo(a.departmentBaseScore);
          });
        }
        break;
    }
  }
}
