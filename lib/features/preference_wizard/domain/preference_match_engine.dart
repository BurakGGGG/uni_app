import '../../score_calculator/domain/models/match_result.dart';
import '../../university/domain/models/department_model.dart';
import '../../university/domain/models/university_model.dart';
import 'models/student_score_profile.dart';
import 'models/wizard_filter.dart';

// ═══════════════════════════════════════════════════════════════
//  Saf kategorileme fonksiyonları
//  Hem çok-programlı motor hem de tek-program uygunluk rozeti kullanır.
// ═══════════════════════════════════════════════════════════════

/// Taban puan farkına göre kategori.
/// [placementScore] öğrencinin yerleştirme puanı, [baseScore] programın tabanı.
/// Eşikler `ScoreCalculatorEngine.matchUniversities` ile aynı tutulur.
MatchCategory categorizeByScore(double placementScore, double baseScore) {
  final diff = placementScore - baseScore;
  if (diff >= 2) return MatchCategory.guaranteed;
  if (diff >= -3) return MatchCategory.target;
  return MatchCategory.dream;
}

/// Başarı sıralaması marjına göre kategori (küçük sıralama = daha iyi).
///
/// Öğrenci programın referans sıralamasından belirgin biçimde öndeyse garanti,
/// yakın bandındaysa hedef, gerideyse riskli. Marjlar programın sıralamasına
/// oranlıdır — böylece hem 1.000 hem 300.000 sıralamalı programlarda çalışır.
MatchCategory categorizeByRank(int studentRank, int programRank) {
  if (programRank <= 0) {
    // Referans yoksa kategori verilemez — güvenli taraf: hedef.
    return MatchCategory.target;
  }
  if (studentRank <= programRank * 0.90) return MatchCategory.guaranteed;
  if (studentRank <= programRank * 1.10) return MatchCategory.target;
  return MatchCategory.dream;
}

/// Bir program için öğrenci profiline göre kategori + hangi sinyale dayandığı.
///
/// Rank varsa ve programın kullanılabilir referans sıralaması varsa sıralama
/// birincildir; değilse taban puanına düşer.
({MatchCategory category, MatchBasis basis}) categorizeDepartment(
  StudentScoreProfile profile,
  DepartmentModel dept,
) {
  final programRank = dept.rankingForMatching;
  if (profile.hasRank && programRank != null) {
    return (
      category: categorizeByRank(profile.rank!, programRank),
      basis: MatchBasis.rank,
    );
  }
  return (
    category: categorizeByScore(profile.placementScore, dept.effectiveBaseScore),
    basis: MatchBasis.score,
  );
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
  /// anlamsızdır.
  static PreferenceMatchResult matchAllPrograms({
    required StudentScoreProfile profile,
    required List<DepartmentModel> allDepartments,
    required List<UniversityModel> allUniversities,
    WizardFilter filter = const WizardFilter(),
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
      if (query.isNotEmpty &&
          !dept.name.toLowerCase().contains(query) &&
          !dept.faculty.toLowerCase().contains(query)) {
        continue;
      }

      final result = categorizeDepartment(profile, dept);
      final match = UniversityMatch(
        department: dept,
        university: uni,
        category: result.category,
        departmentBaseScore: baseScore,
        departmentRanking: dept.rankingForMatching,
        scoreDifference: profile.placementScore - baseScore,
        matchBasis: result.basis,
      );

      switch (result.category) {
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

    _sortCategory(guaranteed, filter.sort, isGuaranteed: true);
    _sortCategory(target, filter.sort, isGuaranteed: false);
    _sortCategory(dream, filter.sort, isGuaranteed: false);

    return PreferenceMatchResult(
      guaranteed: guaranteed,
      target: target,
      dream: dream,
    );
  }

  static void _sortCategory(
    List<UniversityMatch> list,
    WizardSort sort, {
    required bool isGuaranteed,
  }) {
    switch (sort) {
      case WizardSort.baseDesc:
        list.sort(
          (a, b) => b.departmentBaseScore.compareTo(a.departmentBaseScore),
        );
        break;
      case WizardSort.fit:
        if (isGuaranteed) {
          // En yüksek tabanlı garantiler önce (en "değerli" güvenli tercihler).
          list.sort(
            (a, b) => b.departmentBaseScore.compareTo(a.departmentBaseScore),
          );
        } else {
          // Puana en yakın olanlar önce.
          list.sort(
            (a, b) =>
                a.scoreDifference.abs().compareTo(b.scoreDifference.abs()),
          );
        }
        break;
    }
  }
}
