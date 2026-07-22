import '../../preference_wizard/domain/similar_programs.dart';
import '../../university/domain/models/department_model.dart';
import '../../university/domain/models/university_model.dart';
import 'models/best_programs_query.dart';
import 'program_category.dart';

/// Sıralı listedeki tek program.
class RankedProgram {
  /// 1'den başlayan liste sırası (kartın "#3" rozeti).
  final int position;

  final DepartmentModel department;
  final UniversityModel university;

  /// Referans başarı sıralaması ve hangi yıldan geldiği; yoksa null.
  final ({int rank, int year})? reference;

  const RankedProgram({
    required this.position,
    required this.department,
    required this.university,
    required this.reference,
  });

  double get baseScore => department.effectiveBaseScore;

  /// Referans sıra 2025'ten eski bir yıldan geliyorsa liste bunu etiketler.
  bool get referenceIsStale =>
      reference != null && reference!.year > 0 && reference!.year < 2025;
}

/// Bir bölüm adının özeti — alan → bölüm listesi ekranı için.
class DepartmentSummary {
  final String name;
  final String normalizedName;

  /// Programların çoğunluk puan türü (aynı ad farklı üniversitede farklı
  /// türde okutulabiliyor; kart bunu gösterir ki elma-armut olmasın).
  final String? scoreType;

  final int programCount;

  /// En iyi (en küçük) referans sıra; hiçbirinde yoksa null.
  final int? bestRank;

  const DepartmentSummary({
    required this.name,
    required this.normalizedName,
    required this.scoreType,
    required this.programCount,
    required this.bestRank,
  });
}

/// "En iyi X bölümleri" listesini kuran saf fonksiyonlar.
///
/// Veri kaynağı `allScoredDepartmentsProvider` (asset-öncelikli, bellekte,
/// paylaşılan) olduğundan burada I/O yok — hepsi liste dönüşümü.
class BestProgramsEngine {
  const BestProgramsEngine._();

  /// Uzaktan/açıköğretim işaretleri `description` alanında taşınır.
  static bool isDistanceLearning(DepartmentModel d) {
    final desc = d.description ?? '';
    return desc.contains('Açıköğretim') || desc.contains('Uzaktan');
  }

  /// Burs bilgisi de `description`'da: "(Burslu)", "(İngilizce) (Burslu)".
  static bool isScholarship(DepartmentModel d) =>
      (d.description ?? '').contains('Burslu');

  /// [query]'ye uyan programlar, istenen ölçüte göre sıralı.
  static List<RankedProgram> rank(
    List<DepartmentModel> all,
    Map<String, UniversityModel> universities,
    BestProgramsQuery query,
  ) {
    final category =
        query.categoryKey == null ? null : categoryByKey(query.categoryKey!);
    final targetName = query.departmentName?.toLowerCase().trim();
    final search = query.search.toLowerCase().trim();

    final matched = <DepartmentModel>[];
    for (final dept in all) {
      final uni = universities[dept.universityId];
      if (uni == null) continue;

      if (query.programTypes.isNotEmpty &&
          !query.programTypes.contains(dept.type)) {
        continue;
      }
      if (!query.includeDistance && isDistanceLearning(dept)) continue;
      if (query.onlyScholarship && !isScholarship(dept)) continue;
      if (query.languages.isNotEmpty &&
          !query.languages.contains(dept.language)) {
        continue;
      }
      if (query.uniTypes.isNotEmpty && !query.uniTypes.contains(uni.type)) {
        continue;
      }
      if (query.cityIds.isNotEmpty && !query.cityIds.contains(uni.cityId)) {
        continue;
      }

      final lower = dept.name.toLowerCase().trim();
      if (targetName != null && lower != targetName) continue;
      if (search.isNotEmpty && !lower.contains(search)) continue;
      if (category != null &&
          !category.matches(normalizeProgramName(dept.name))) {
        continue;
      }

      matched.add(dept);
    }

    _sort(matched, query.sort);

    return [
      for (var i = 0; i < matched.length; i++)
        RankedProgram(
          position: i + 1,
          department: matched[i],
          university: universities[matched[i].universityId]!,
          reference: matched[i].rankingForMatchingWithYear,
        ),
    ];
  }

  /// Bir alandaki bölüm adları, en iyi programının sırasına göre.
  static List<DepartmentSummary> departmentsIn(
    ProgramCategory category,
    List<DepartmentModel> all,
    BestProgramsQuery query,
  ) {
    final buckets = <String, List<DepartmentModel>>{};
    for (final dept in all) {
      if (query.programTypes.isNotEmpty &&
          !query.programTypes.contains(dept.type)) {
        continue;
      }
      if (!query.includeDistance && isDistanceLearning(dept)) continue;
      final normalized = normalizeProgramName(dept.name);
      if (!category.matches(normalized)) continue;
      (buckets[dept.name] ??= []).add(dept);
    }

    final summaries = <DepartmentSummary>[];
    for (final entry in buckets.entries) {
      int? bestRank;
      for (final dept in entry.value) {
        final ref = dept.rankingForMatching;
        if (ref == null) continue;
        if (bestRank == null || ref < bestRank) bestRank = ref;
      }
      summaries.add(DepartmentSummary(
        name: entry.key,
        normalizedName: normalizeProgramName(entry.key),
        scoreType: _majorityScoreType(entry.value),
        programCount: entry.value.length,
        bestRank: bestRank,
      ));
    }

    summaries.sort((a, b) {
      if (a.bestRank == null && b.bestRank == null) {
        return b.programCount.compareTo(a.programCount);
      }
      if (a.bestRank == null) return 1;
      if (b.bestRank == null) return -1;
      return a.bestRank!.compareTo(b.bestRank!);
    });
    return summaries;
  }

  /// Arama kutusu için: ada göre eşleşen bölüm adları (program sayısıyla).
  static List<DepartmentSummary> searchDepartments(
    String query,
    List<DepartmentModel> all, {
    Set<String> programTypes = const {'Lisans'},
    int limit = 30,
  }) {
    final needle = query.toLowerCase().trim();
    if (needle.isEmpty) return const [];

    final buckets = <String, List<DepartmentModel>>{};
    for (final dept in all) {
      if (programTypes.isNotEmpty && !programTypes.contains(dept.type)) {
        continue;
      }
      if (isDistanceLearning(dept)) continue;
      if (!dept.name.toLowerCase().contains(needle)) continue;
      (buckets[dept.name] ??= []).add(dept);
    }

    final results = [
      for (final entry in buckets.entries)
        DepartmentSummary(
          name: entry.key,
          normalizedName: normalizeProgramName(entry.key),
          scoreType: _majorityScoreType(entry.value),
          programCount: entry.value.length,
          bestRank: _bestRank(entry.value),
        ),
    ];

    // Adı sorguyla başlayanlar önce, sonra program sayısı.
    results.sort((a, b) {
      final aStarts = a.name.toLowerCase().startsWith(needle) ? 0 : 1;
      final bStarts = b.name.toLowerCase().startsWith(needle) ? 0 : 1;
      if (aStarts != bStarts) return aStarts.compareTo(bStarts);
      return b.programCount.compareTo(a.programCount);
    });
    return results.length > limit ? results.sublist(0, limit) : results;
  }

  static int? _bestRank(List<DepartmentModel> depts) {
    int? best;
    for (final d in depts) {
      final r = d.rankingForMatching;
      if (r == null) continue;
      if (best == null || r < best) best = r;
    }
    return best;
  }

  static String? _majorityScoreType(List<DepartmentModel> depts) {
    final counts = <String, int>{};
    for (final d in depts) {
      final t = d.effectiveScoreType;
      if (t == null) continue;
      counts[t] = (counts[t] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Sıralama — `WizardSort.rankAsc` ile aynı null-güvenli davranış:
  /// iyi (küçük) sıra önce, sırasız programlar sona, eşitlikte taban puanı.
  static void _sort(List<DepartmentModel> list, BestProgramsSort sort) {
    switch (sort) {
      case BestProgramsSort.scoreDesc:
        list.sort((a, b) =>
            b.effectiveBaseScore.compareTo(a.effectiveBaseScore));
        break;
      case BestProgramsSort.rankAsc:
        list.sort((a, b) {
          final ra = a.rankingForMatching;
          final rb = b.rankingForMatching;
          if (ra == null && rb == null) {
            return b.effectiveBaseScore.compareTo(a.effectiveBaseScore);
          }
          if (ra == null) return 1;
          if (rb == null) return -1;
          if (ra != rb) return ra.compareTo(rb);
          return b.effectiveBaseScore.compareTo(a.effectiveBaseScore);
        });
        break;
    }
  }
}
