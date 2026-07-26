/// Veri modelleri → ortak `ComparisonView`.
///
/// Ekranların hiçbiri `ComparisonResult`/`CityComparisonResult` çizmez;
/// hepsi buradan çıkan görünümü çizer. Yeni bir ölçüt eklemek = buraya bir
/// `CompareRow` eklemek; üç ekran da kendiliğinden öğrenir.
///
/// **Sıra bilinçli:** "Sayılarla" grubu önce geliyor (kullanıcı kararı).
/// Yorum sayısı düşük üniversitelerde puan grubu boş kalıyor ve ekran
/// bomboş görünüyordu; ÖSYM verisi her zaman dolu.
library;

import '../../../core/utils/formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../university/domain/models/department_model.dart';
import '../../university/domain/models/university_model.dart';
import 'compare_view.dart';
import 'models/city_comparison.dart';
import 'models/comparison_result.dart';
import 'models/department_comparison.dart';
import 'models/triple_comparison_result.dart';


const double _kRatingTie = 0.05;

// ── Üniversite ────────────────────────────────────────────────────

ComparisonView universityCompareView(
  ComparisonResult result,
  AppLocalizations loc,
) {
  final a = result.uniA;
  final b = result.uniB;
  final stats = result.stats;

  return ComparisonView(
    sides: [_uniSide(a), _uniSide(b)],
    groups: [
      CompareGroup(
        title: loc.cmpGroupNumbers,
        rows: [
          _intRow(
            loc.cmpRowDepartments,
            [stats.totalDepartmentsA, stats.totalDepartmentsB],
          ),
          // Lisans/önlisans bölüm sayısının kırılımı — tabloda dururlar
          // ama öne çıkanlarda aynı bilginin üç türevi olmasınlar.
          _intRow(
            loc.cmpRowUndergrad,
            [stats.undergradCountA, stats.undergradCountB],
            secondary: true,
          ),
          _intRow(
            loc.cmpRowAssociate,
            [stats.associateCountA, stats.associateCountB],
            secondary: true,
          ),
          _scoreRow(
            loc.cmpRowAvgBase,
            [stats.avgBaseScoreA, stats.avgBaseScoreB],
            hint: loc.cmpHintLastYear,
          ),
          _intRow(loc.cmpRowQuota, [a.placeCount ?? 0, b.placeCount ?? 0]),
          _intRow(
            loc.cmpRowPlaces,
            [result.placeCountA, result.placeCountB],
          ),
          _plainRow(
            loc.cmpRowType,
            [a.type, b.type],
          ),
          _yearRow(
            loc.cmpRowFounded,
            [a.establishedYear, b.establishedYear],
          ),
        ],
      ),
      CompareGroup(
        title: loc.cmpGroupReviews,
        emptyNote: loc.cmpReviewsEmpty,
        rows: [
          _ratingRow(
            loc.cmpRowRating,
            [a.avgRating, b.avgRating],
          ),
          _intRow(
            loc.cmpRowReviews,
            [a.reviewCount, b.reviewCount],
            secondary: true,
          ),
          for (final category in result.categoryComparisons.values)
            _ratingRow(
              category.categoryName,
              [category.valueA, category.valueB],
            ),
        ],
      ),
    ],
  );
}

/// Üçlü karşılaştırma — podyum yerine aynı satırların üç sütunlusu
/// (kullanıcı kararı). İkili ve üçlü mod böylece tek iskeleti paylaşır.
ComparisonView tripleCompareView(
  TripleComparisonResult result,
  AppLocalizations loc,
) {
  final unis = [result.uniA, result.uniB, result.uniC];

  return ComparisonView(
    sides: unis.map(_uniSide).toList(),
    groups: [
      CompareGroup(
        title: loc.cmpGroupNumbers,
        rows: [
          _intRow(
            loc.cmpRowQuota,
            unis.map((u) => u.placeCount ?? 0).toList(),
          ),
          _plainRow(loc.cmpRowType, unis.map((u) => u.type).toList()),
          _yearRow(
            loc.cmpRowFounded,
            unis.map((u) => u.establishedYear).toList(),
          ),
        ],
      ),
      CompareGroup(
        title: loc.cmpGroupReviews,
        emptyNote: loc.cmpReviewsEmpty,
        rows: [
          _ratingRow(
            loc.cmpRowRating,
            unis.map((u) => u.avgRating).toList(),
          ),
          _intRow(
            loc.cmpRowReviews,
            unis.map((u) => u.reviewCount).toList(),
            secondary: true,
          ),
          for (final category in result.categoryComparisons.values)
            _ratingRow(
              category.categoryName,
              [category.valueA, category.valueB, category.valueC],
            ),
        ],
      ),
    ],
  );
}

CompareSide _uniSide(UniversityModel uni) => CompareSide(
      id: uni.id,
      title: uni.name,
      subtitle: uni.type,
      logoUrl: uni.logoUrl,
      brandHex: uni.brandPrimaryHex,
    );

// ── Bölüm ─────────────────────────────────────────────────────────

ComparisonView departmentCompareView(
  DepartmentComparisonResult result,
  AppLocalizations loc, {
  required String uniNameA,
  required String uniNameB,
  String? logoA,
  String? logoB,
}) {
  final a = result.deptA;
  final b = result.deptB;

  return ComparisonView(
    sides: [
      CompareSide(
        id: a.id,
        title: uniNameA,
        subtitle: a.name,
        logoUrl: logoA,
      ),
      CompareSide(
        id: b.id,
        title: uniNameB,
        subtitle: b.name,
        logoUrl: logoB,
      ),
    ],
    groups: [
      CompareGroup(
        title: loc.cmpGroupPlacement,
        rows: [
          _scoreRow(
            loc.cmpRowBaseScore,
            [a.effectiveBaseScore, b.effectiveBaseScore],
            hint: loc.cmpHintLastYear,
          ),
          // Sıralamada KÜÇÜK olan daha zor/başarılı — çubuk buna göre.
          _rankRow(
            loc.cmpRowRanking,
            [a.effectiveRanking, b.effectiveRanking],
          ),
          _intRow(loc.cmpRowQuota, [
            a.quota ?? a.scoreData?.quota ?? 0,
            b.quota ?? b.scoreData?.quota ?? 0,
          ]),
          CompareRow(
            label: loc.cmpRowFillRate,
            values: [_fill(a), _fill(b)],
            display: [_fillText(a), _fillText(b)],
            tieThreshold: 0.01,
          ),
          _plainRow(
            loc.cmpRowScoreType,
            [_scoreType(a), _scoreType(b)],
          ),
          _plainRow(
            loc.cmpRowDuration,
            [_years(loc, a.duration), _years(loc, b.duration)],
          ),
        ],
      ),
    ],
  );
}

/// Doluluk oranı (0–1). Kontenjan ya da yerleşen bilinmiyorsa null —
/// sıfır göstermek "hiç kimse yerleşmedi" demek olurdu.
double? _fill(DepartmentModel dept) {
  final rate = dept.scoreData?.fillRate;
  return rate == null || rate <= 0 ? null : rate;
}

String _fillText(DepartmentModel dept) {
  final rate = _fill(dept);
  return rate == null ? '—' : '%${(rate * 100).round()}';
}

String _scoreType(DepartmentModel dept) =>
    dept.scoreType ?? dept.scoreData?.scoreType ?? '—';

String _years(AppLocalizations loc, int? duration) =>
    duration == null || duration <= 0 ? '—' : loc.cmpYears('$duration');

// ── Şehir ─────────────────────────────────────────────────────────

ComparisonView cityCompareView(
  CityComparisonResult result,
  AppLocalizations loc,
) {
  final a = result.cityA;
  final b = result.cityB;

  return ComparisonView(
    sides: [
      CompareSide(
        id: a.id,
        title: a.name,
        subtitle: loc.cmpCityPlate(a.plateCode),
      ),
      CompareSide(
        id: b.id,
        title: b.name,
        subtitle: loc.cmpCityPlate(b.plateCode),
      ),
    ],
    groups: [
      CompareGroup(
        title: loc.cmpGroupNumbers,
        rows: [
          _intRow(
            loc.cmpRowUniCount,
            [result.universityCountA, result.universityCountB],
          ),
          // Devlet/vakıf sayıları toplam üniversite sayısının kırılımı.
          _intRow(
            loc.cmpRowStateUni,
            [result.stateUniversityCountA, result.stateUniversityCountB],
            secondary: true,
          ),
          _intRow(
            loc.cmpRowFoundationUni,
            [
              result.foundationUniversityCountA,
              result.foundationUniversityCountB,
            ],
            secondary: true,
          ),
          CompareRow(
            label: loc.cmpRowDensity,
            values: [
              result.universityDensityPerMillionA,
              result.universityDensityPerMillionB,
            ],
            display: [
              AppFormatters.rating(result.universityDensityPerMillionA),
              AppFormatters.rating(result.universityDensityPerMillionB),
            ],
            hint: loc.cmpHintPerMillion,
            tieThreshold: 0.1,
          ),
          _plainRow(
            loc.cmpRowPopulation,
            [_population(result.populationA), _population(result.populationB)],
          ),
        ],
      ),
      CompareGroup(
        title: loc.cmpGroupReviews,
        emptyNote: loc.cmpReviewsEmpty,
        rows: [
          _ratingRow(
            loc.cmpRowRating,
            [result.avgRatingA, result.avgRatingB],
          ),
          CompareRow(
            label: loc.cmpRowAvgReviews,
            values: [result.avgReviewCountA, result.avgReviewCountB],
            display: [
              AppFormatters.rating(result.avgReviewCountA),
              AppFormatters.rating(result.avgReviewCountB),
            ],
            tieThreshold: 0.5,
          ),
        ],
      ),
    ],
  );
}

String _population(int? value) =>
    value == null || value <= 0 ? '—' : AppFormatters.integer(value);

// ── Satır kurucuları ──────────────────────────────────────────────
//
// Sıfır ile "veri yok" ayrımı burada yapılıyor: 0 bölümü olan bir
// üniversite yok, o yüzden 0 = veri gelmemiş demek ve satır null taşımalı.
// Aksi hâlde çubuk sıfırda dolu, karşılaştırma yanlış görünüyordu.

CompareRow _intRow(
  String label,
  List<int> values, {
  String? hint,
  bool secondary = false,
}) {
  return CompareRow(
    label: label,
    values: values.map((v) => v > 0 ? v.toDouble() : null).toList(),
    display: values.map((v) => v > 0 ? AppFormatters.integer(v) : '—').toList(),
    hint: hint,
    secondary: secondary,
  );
}

CompareRow _scoreRow(String label, List<double> values, {String? hint}) {
  return CompareRow(
    label: label,
    values: values.map((v) => v > 0 ? v : null).toList(),
    display: values.map((v) => v > 0 ? AppFormatters.score(v) : '—').toList(),
    hint: hint,
    tieThreshold: 0.5,
  );
}

CompareRow _ratingRow(String label, List<double> values, {String? hint}) {
  return CompareRow(
    label: label,
    values: values.map((v) => v > 0 ? v : null).toList(),
    display: values.map((v) => v > 0 ? AppFormatters.rating(v) : '—').toList(),
    hint: hint,
    tieThreshold: _kRatingTie,
  );
}

/// Başarı sırası: küçük olan daha iyi.
CompareRow _rankRow(String label, List<int> values) {
  return CompareRow(
    label: label,
    values: values.map((v) => v > 0 ? v.toDouble() : null).toList(),
    display: values.map((v) => v > 0 ? AppFormatters.ranking(v) : '—').toList(),
    higherIsBetter: false,
  );
}

/// Künye satırı — yarışmaz, yalnız yan yana yazılır.
CompareRow _plainRow(String label, List<String> values) {
  return CompareRow(
    label: label,
    values: List<double?>.filled(values.length, 0),
    display: values,
    comparable: false,
  );
}

CompareRow _yearRow(String label, List<int> values) {
  return CompareRow(
    label: label,
    values: List<double?>.filled(values.length, 0),
    display: values.map((v) => v > 0 ? '$v' : '—').toList(),
    comparable: false,
  );
}
