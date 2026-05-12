import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../university/data/university_repository.dart';
import '../../university/domain/models/department_model.dart';
import '../../places/data/place_repository.dart';
import '../domain/models/comparison_result.dart';
import '../domain/models/triple_comparison_result.dart';
import '../../university/domain/models/university_model.dart';
import '../../places/domain/models/place_model.dart';

class ComparisonRepository {
  final UniversityRepository _uniRepo;
  final PlaceRepository _placeRepo;
  final FirebaseCrashlytics? _crashlytics;

  ComparisonRepository({
    UniversityRepository? uniRepo,
    PlaceRepository? placeRepo,
    FirebaseCrashlytics? crashlytics,
  })  : _uniRepo = uniRepo ?? UniversityRepository(),
        _placeRepo = placeRepo ?? PlaceRepository(),
        _crashlytics = crashlytics;

  Future<ComparisonResult?> compare(String uniIdA, String uniIdB) async {
    if (uniIdA == uniIdB) {
      throw ArgumentError('İki farklı üniversite seçmelisiniz');
    }

    // ─── 1. ZORUNLU veri: üniversiteler ─────────────────────
    // Üniversite verisi yoksa karşılaştırma yapılamaz → null dön
    UniversityModel? uniA;
    UniversityModel? uniB;
    try {
      final unis = await Future.wait([
        _uniRepo.getUniversity(uniIdA),
        _uniRepo.getUniversity(uniIdB),
      ]);
      uniA = unis[0];
      uniB = unis[1];
    } catch (e, st) {
      debugPrint('[ComparisonRepo] University fetch failed: $e');
      _crashlytics?.recordError(e, st, reason: 'compare: university fetch failed');
      return null;
    }
    if (uniA == null || uniB == null) return null;

    // ─── 2. OPSİYONEL veri: places ve departments ─────────
    // Bunlar fail olsa bile karşılaştırma devam edebilir (boş list ile)
    //
    // 6.4 — Denormalize: Üniversite dokümanında placeCount/placeBreakdown varsa
    // Firestore'a ek istek atmadan onları kullan. Yoksa eski yöntemle places sorgula.
    final bool hasDenormA =
        uniA.placeCount != null && uniA.placeBreakdown != null;
    final bool hasDenormB =
        uniB.placeCount != null && uniB.placeBreakdown != null;

    final placesA = hasDenormA
        ? const <PlaceModel>[]
        : await _safelyGet(
            () => _placeRepo.getPlacesByUniversity(uniIdA),
            fallback: const <PlaceModel>[],
            tag: 'placesA',
          );
    final placesB = hasDenormB
        ? const <PlaceModel>[]
        : await _safelyGet(
            () => _placeRepo.getPlacesByUniversity(uniIdB),
            fallback: const <PlaceModel>[],
            tag: 'placesB',
          );
    final deptsA = await _safelyGet(
      () => _uniRepo.getDepartmentsByUniversity(uniIdA),
      fallback: const <DepartmentModel>[],
      tag: 'deptsA',
    );
    final deptsB = await _safelyGet(
      () => _uniRepo.getDepartmentsByUniversity(uniIdB),
      fallback: const <DepartmentModel>[],
      tag: 'deptsB',
    );

    // Yer sayımı ve dağılımı: denormalize varsa onu kullan, yoksa hesapla
    final int placeCountA = uniA.placeCount ?? placesA.length;
    final int placeCountB = uniB.placeCount ?? placesB.length;

    // ─── 3. Kategori karşılaştırmaları yap ─────────────────
    final categories = <String, CategoryComparison>{};
    final allCats = <String>{
      ...uniA.categoryRatings.keys,
      ...uniB.categoryRatings.keys,
    };

    for (final cat in allCats) {
      final valA = (uniA.categoryRatings[cat] ?? 0).toDouble();
      final valB = (uniB.categoryRatings[cat] ?? 0).toDouble();

      String? winnerId;
      if ((valA - valB).abs() < 0.05) {
        winnerId = null; // tie
      } else {
        winnerId = valA > valB ? uniA.id : uniB.id;
      }

      categories[cat] = CategoryComparison(
        categoryName: cat,
        valueA: valA,
        valueB: valB,
        winnerId: winnerId,
      );
    }

    // 4. Bölüm istatistikleri
    double calculateAvgBaseScore(List<DepartmentModel> depts) {
      if (depts.isEmpty) return 0;
      final sum = depts.fold<double>(0, (s, d) => s + (d.baseScore ?? 0));
      return sum / depts.length;
    }

    int countByType(List<DepartmentModel> depts, String type) =>
        depts.where((d) => d.type == type).length;

    // 5. Mekan dağılımı
    Map<String, int> getPlaceBreakdown(List<PlaceModel> places) {
      final map = <String, int>{};
      for (final p in places) {
        final key = p.type.firestoreValue;
        map[key] = (map[key] ?? 0) + 1;
      }
      return map;
    }

    // Mekan dağılımı: denormalize varsa onu kullan, yoksa places listesinden hesapla
    final Map<String, int> placeBreakdownA =
        uniA.placeBreakdown ?? getPlaceBreakdown(placesA);
    final Map<String, int> placeBreakdownB =
        uniB.placeBreakdown ?? getPlaceBreakdown(placesB);

    // 6. Stats hesapla
    final stats = ComparisonStats(
      reviewCountDelta: uniA.reviewCount - uniB.reviewCount,
      placeCountDelta: placeCountA - placeCountB,
      establishedYearDiff: (uniA.establishedYear - uniB.establishedYear).abs(),
      sameType: uniA.type == uniB.type,
      sameCity: uniA.cityId == uniB.cityId,
      sameCampusLayout: uniA.campusLayout == uniB.campusLayout,
      totalDepartmentsA: deptsA.length,
      totalDepartmentsB: deptsB.length,
      avgBaseScoreA: calculateAvgBaseScore(deptsA),
      avgBaseScoreB: calculateAvgBaseScore(deptsB),
      placeBreakdownA: placeBreakdownA,
      placeBreakdownB: placeBreakdownB,
      undergradCountA: countByType(deptsA, 'Lisans'),
      undergradCountB: countByType(deptsB, 'Lisans'),
      associateCountA: countByType(deptsA, 'Önlisans'),
      associateCountB: countByType(deptsB, 'Önlisans'),
    );

    return ComparisonResult(
      uniA: uniA,
      uniB: uniB,
      categoryComparisons: categories,
      stats: stats,
      placeCountA: placeCountA,
      placeCountB: placeCountB,
    );
  }

  /// Üçlü karşılaştırma (Pro feature) — 3 üniversiteyi yan yana karşılaştırır.
  /// İkili `compare` ile aynı pattern: zorunlu uni verisi, opsiyonel
  /// places/departments (fail olursa boş list ile devam).
  Future<TripleComparisonResult?> compareThree(
    String uniIdA,
    String uniIdB,
    String uniIdC,
  ) async {
    final ids = {uniIdA, uniIdB, uniIdC};
    if (ids.length != 3) {
      throw ArgumentError('Üç farklı üniversite seçmelisiniz');
    }

    // ─── 1. ZORUNLU veri: üniversiteler ─────────────────────
    UniversityModel? uniA;
    UniversityModel? uniB;
    UniversityModel? uniC;
    try {
      final unis = await Future.wait([
        _uniRepo.getUniversity(uniIdA),
        _uniRepo.getUniversity(uniIdB),
        _uniRepo.getUniversity(uniIdC),
      ]);
      uniA = unis[0];
      uniB = unis[1];
      uniC = unis[2];
    } catch (e, st) {
      debugPrint('[ComparisonRepo] Triple university fetch failed: $e');
      _crashlytics?.recordError(e, st,
          reason: 'compareThree: university fetch failed');
      return null;
    }
    if (uniA == null || uniB == null || uniC == null) return null;

    // ─── 2. OPSİYONEL veri: places (denormalize varsa Firestore'a hiç gitme) ─
    final bool hasDenormA =
        uniA.placeCount != null && uniA.placeBreakdown != null;
    final bool hasDenormB =
        uniB.placeCount != null && uniB.placeBreakdown != null;
    final bool hasDenormC =
        uniC.placeCount != null && uniC.placeBreakdown != null;

    final placesA = hasDenormA
        ? const <PlaceModel>[]
        : await _safelyGet(
            () => _placeRepo.getPlacesByUniversity(uniIdA),
            fallback: const <PlaceModel>[],
            tag: 'placesA(triple)',
          );
    final placesB = hasDenormB
        ? const <PlaceModel>[]
        : await _safelyGet(
            () => _placeRepo.getPlacesByUniversity(uniIdB),
            fallback: const <PlaceModel>[],
            tag: 'placesB(triple)',
          );
    final placesC = hasDenormC
        ? const <PlaceModel>[]
        : await _safelyGet(
            () => _placeRepo.getPlacesByUniversity(uniIdC),
            fallback: const <PlaceModel>[],
            tag: 'placesC(triple)',
          );
    final deptsA = await _safelyGet(
      () => _uniRepo.getDepartmentsByUniversity(uniIdA),
      fallback: const <DepartmentModel>[],
      tag: 'deptsA(triple)',
    );
    final deptsB = await _safelyGet(
      () => _uniRepo.getDepartmentsByUniversity(uniIdB),
      fallback: const <DepartmentModel>[],
      tag: 'deptsB(triple)',
    );
    final deptsC = await _safelyGet(
      () => _uniRepo.getDepartmentsByUniversity(uniIdC),
      fallback: const <DepartmentModel>[],
      tag: 'deptsC(triple)',
    );

    final placeCountA = uniA.placeCount ?? placesA.length;
    final placeCountB = uniB.placeCount ?? placesB.length;
    final placeCountC = uniC.placeCount ?? placesC.length;

    // ─── 3. Kategori karşılaştırmaları (3 değer) ───────────
    final categories = <String, TripleCategoryComparison>{};
    final allCats = <String>{
      ...uniA.categoryRatings.keys,
      ...uniB.categoryRatings.keys,
      ...uniC.categoryRatings.keys,
    };

    for (final cat in allCats) {
      final valA = (uniA.categoryRatings[cat] ?? 0).toDouble();
      final valB = (uniB.categoryRatings[cat] ?? 0).toDouble();
      final valC = (uniC.categoryRatings[cat] ?? 0).toDouble();
      final maxVal = [valA, valB, valC].reduce((a, b) => a > b ? a : b);

      // En yüksek değere yakın olanlar (0.05 tolerance). Birden çoksa tie.
      final winners = <String>[];
      if ((maxVal - valA).abs() < 0.05) winners.add(uniA.id);
      if ((maxVal - valB).abs() < 0.05) winners.add(uniB.id);
      if ((maxVal - valC).abs() < 0.05) winners.add(uniC.id);
      final winnerId = winners.length == 1 ? winners.first : null;

      categories[cat] = TripleCategoryComparison(
        categoryName: cat,
        valueA: valA,
        valueB: valB,
        valueC: valC,
        winnerId: winnerId,
      );
    }

    double avgBase(List<DepartmentModel> depts) {
      if (depts.isEmpty) return 0;
      final sum = depts.fold<double>(0, (s, d) => s + (d.baseScore ?? 0));
      return sum / depts.length;
    }

    Map<String, int> placeBreakdown(List<PlaceModel> places) {
      final map = <String, int>{};
      for (final p in places) {
        final key = p.type.firestoreValue;
        map[key] = (map[key] ?? 0) + 1;
      }
      return map;
    }

    final placeBreakdownA = uniA.placeBreakdown ?? placeBreakdown(placesA);
    final placeBreakdownB = uniB.placeBreakdown ?? placeBreakdown(placesB);
    final placeBreakdownC = uniC.placeBreakdown ?? placeBreakdown(placesC);

    final stats = TripleComparisonStats(
      totalDepartmentsA: deptsA.length,
      totalDepartmentsB: deptsB.length,
      totalDepartmentsC: deptsC.length,
      avgBaseScoreA: avgBase(deptsA),
      avgBaseScoreB: avgBase(deptsB),
      avgBaseScoreC: avgBase(deptsC),
      placeBreakdownA: placeBreakdownA,
      placeBreakdownB: placeBreakdownB,
      placeBreakdownC: placeBreakdownC,
    );

    return TripleComparisonResult(
      uniA: uniA,
      uniB: uniB,
      uniC: uniC,
      categoryComparisons: categories,
      stats: stats,
      placeCountA: placeCountA,
      placeCountB: placeCountB,
      placeCountC: placeCountC,
    );
  }

  /// Helper: Fetch işlemini try-catch'le sar, hata olursa fallback dön
  Future<T> _safelyGet<T>(
    Future<T> Function() fetcher, {
    required T fallback,
    required String tag,
  }) async {
    try {
      return await fetcher();
    } catch (e, st) {
      debugPrint('[ComparisonRepo] $tag fetch failed: $e');
      _crashlytics?.recordError(
        e,
        st,
        reason: 'compare: $tag fetch failed (non-critical)',
        fatal: false,
      );
      return fallback;
    }
  }
}
