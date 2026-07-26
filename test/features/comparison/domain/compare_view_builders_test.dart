import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/comparison/domain/compare_view_builders.dart';
// `flutter_test` de `ComparisonResult` adında bir tip veriyor (golden
// karşılaştırması) — ön ek olmadan çakışıyor.
import 'package:uni_app/features/comparison/domain/models/comparison_result.dart'
    as cmp;
import 'package:uni_app/features/comparison/domain/models/department_comparison.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';
import 'package:uni_app/features/university/domain/models/university_model.dart';
import 'package:uni_app/l10n/generated/app_localizations_tr.dart';

/// Veri modeli → ortak görünüm dönüşümü.
///
/// Kilitlenen sözleşme: **ÖSYM verisi önce** (kullanıcı kararı — yorum
/// sayısı düşük üniversitelerde ekran bomboş kalıyordu), sıfır ile "veri
/// yok" ayrı, sıralama satırı ters yönlü.
void main() {
  final loc = AppLocalizationsTr();

  UniversityModel uni(
    String id, {
    double rating = 0,
    int reviews = 0,
    int? places,
  }) =>
      UniversityModel(
        id: id,
        cityId: '34',
        name: 'Üniversite $id',
        type: 'Devlet',
        hasCampus: true,
        logoUrl: '',
        photoUrl: '',
        description: '',
        establishedYear: 1990,
        website: '',
        avgRating: rating,
        reviewCount: reviews,
        placeCount: places,
      );

  cmp.ComparisonResult result({
    double ratingA = 0,
    double ratingB = 0,
    int reviewsA = 0,
    int reviewsB = 0,
    cmp.ComparisonStats? stats,
  }) =>
      cmp.ComparisonResult(
        uniA: uni('a', rating: ratingA, reviews: reviewsA),
        uniB: uni('b', rating: ratingB, reviews: reviewsB),
        categoryComparisons: const {},
        stats: stats ??
            const cmp.ComparisonStats(
              reviewCountDelta: 0,
              placeCountDelta: 0,
              establishedYearDiff: 0,
              sameType: true,
              sameCity: true,
              sameCampusLayout: true,
            ),
        placeCountA: 0,
        placeCountB: 0,
      );

  test('sayılar grubu yorumlardan ÖNCE gelir', () {
    final view = universityCompareView(result(), loc);

    expect(view.groups.first.title, loc.cmpGroupNumbers);
    expect(view.groups[1].title, loc.cmpGroupReviews);
  });

  test('yorum yoksa grup boş kalmaz, açıklama taşır', () {
    // Eski ekran bu durumda bomboş görünüyordu.
    final view = universityCompareView(result(), loc);
    final reviews = view.groups[1];

    expect(reviews.isEmpty, isTrue);
    expect(reviews.emptyNote, isNotNull);
    expect(reviews.emptyNote, isNotEmpty);
  });

  test('sıfır "veri yok" demektir, dolu çubuk değil', () {
    final view = universityCompareView(
      result(
        stats: const cmp.ComparisonStats(
          reviewCountDelta: 0,
          placeCountDelta: 0,
          establishedYearDiff: 0,
          sameType: true,
          sameCity: true,
          sameCampusLayout: true,
          totalDepartmentsA: 120,
          totalDepartmentsB: 0,
        ),
      ),
      loc,
    );

    final row = view.groups.first.rows
        .firstWhere((r) => r.label == loc.cmpRowDepartments);
    expect(row.values[1], isNull);
    expect(row.display[1], '—');
    // Tek taraflı veri karşılaştırma sayılmaz.
    expect(row.hasData, isFalse);
  });

  test('yorumlar geldiğinde puan satırı karşılaştırılabilir olur', () {
    final view = universityCompareView(
      result(ratingA: 4.4, ratingB: 4.0, reviewsA: 12, reviewsB: 8),
      loc,
    );
    final reviews = view.groups[1];

    expect(reviews.isEmpty, isFalse);
    expect(view.verdict.leads[0], greaterThan(0));
  });

  group('bölüm', () {
    DepartmentModel dept(
      String id, {
      double? base,
      int? rank,
      int? quota,
    }) =>
        DepartmentModel(
          id: id,
          universityId: 'u$id',
          name: 'Bilgisayar Mühendisliği',
          faculty: 'Mühendislik',
          type: 'Lisans',
          language: 'Türkçe',
          baseScore: base,
          ranking: rank,
          scoreType: 'SAY',
          duration: 4,
          quota: quota,
        );

    test('başarı sırasında KÜÇÜK olan öndedir', () {
      final view = departmentCompareView(
        DepartmentComparisonResult(
          deptA: dept('1', base: 520, rank: 12400, quota: 120),
          deptB: dept('2', base: 505, rank: 18900, quota: 90),
          scoreDeltas: const {},
          winnerId: null,
          hasScoreTypeMismatch: false,
        ),
        loc,
        uniNameA: 'İstanbul Teknik Üniversitesi',
        uniNameB: 'Orta Doğu Teknik Üniversitesi',
      );

      final rank = view.groups.first.rows
          .firstWhere((r) => r.label == loc.cmpRowRanking);
      expect(rank.higherIsBetter, isFalse);
      expect(rank.leader, 0, reason: '12.400 daha zor');
    });

    test('şerit üniversiteyi, alt satır bölümü taşır', () {
      final view = departmentCompareView(
        DepartmentComparisonResult(
          deptA: dept('1', base: 520),
          deptB: dept('2', base: 505),
          scoreDeltas: const {},
          winnerId: null,
          hasScoreTypeMismatch: false,
        ),
        loc,
        uniNameA: 'İstanbul Teknik Üniversitesi',
        uniNameB: 'Orta Doğu Teknik Üniversitesi',
      );

      expect(view.sides[0].title, 'İstanbul Teknik Üniversitesi');
      expect(view.sides[0].subtitle, 'Bilgisayar Mühendisliği');
    });
  });
}
