import '../../university/data/university_repository.dart';
import '../../university/domain/models/city_model.dart';
import '../../university/domain/models/department_model.dart';
import '../../university/domain/models/university_model.dart';
import '../domain/models/city_comparison.dart';

class CityComparisonRepository {
  final UniversityRepository _universityRepository;

  CityComparisonRepository({
    UniversityRepository? universityRepository,
  }) : _universityRepository = universityRepository ?? UniversityRepository();

  Future<CityComparisonResult?> compare(
    String cityIdA,
    String cityIdB,
  ) async {
    if (cityIdA == cityIdB) {
      throw ArgumentError('Aynı şehir karşılaştırılamaz');
    }

    final results = await Future.wait([
      _universityRepository.getCity(cityIdA),
      _universityRepository.getCity(cityIdB),
      _universityRepository.getUniversitiesByCity(cityIdA),
      _universityRepository.getUniversitiesByCity(cityIdB),
    ]);

    final cityA = results[0] as CityModel?;
    final cityB = results[1] as CityModel?;
    final universitiesA = results[2] as List<UniversityModel>;
    final universitiesB = results[3] as List<UniversityModel>;

    if (cityA == null || cityB == null) return null;

    final stateA = universitiesA.where((u) => u.type == 'Devlet').length;
    final stateB = universitiesB.where((u) => u.type == 'Devlet').length;
    final foundationA = universitiesA.where((u) => u.type == 'Vakıf').length;
    final foundationB = universitiesB.where((u) => u.type == 'Vakıf').length;

    final avgRatingA = _average(universitiesA.map((u) => u.avgRating));
    final avgRatingB = _average(universitiesB.map((u) => u.avgRating));
    final avgReviewCountA =
        _average(universitiesA.map((u) => u.reviewCount.toDouble()));
    final avgReviewCountB =
        _average(universitiesB.map((u) => u.reviewCount.toDouble()));
    final topDeptTypesA = await _topDepartmentTypes(universitiesA);
    final topDeptTypesB = await _topDepartmentTypes(universitiesB);
    final densityA = _universityDensityPerMillion(
      universityCount: universitiesA.length,
      population: cityA.population,
    );
    final densityB = _universityDensityPerMillion(
      universityCount: universitiesB.length,
      population: cityB.population,
    );

    final pointsA = _metricPoint(universitiesA.length.toDouble(),
            universitiesB.length.toDouble(), higherIsBetter: true) +
        _metricPoint(avgRatingA, avgRatingB, higherIsBetter: true) +
        _metricPoint(avgReviewCountA, avgReviewCountB, higherIsBetter: true) +
        _metricPoint(densityA, densityB, higherIsBetter: true);

    final pointsB = _metricPoint(universitiesB.length.toDouble(),
            universitiesA.length.toDouble(), higherIsBetter: true) +
        _metricPoint(avgRatingB, avgRatingA, higherIsBetter: true) +
        _metricPoint(avgReviewCountB, avgReviewCountA, higherIsBetter: true) +
        _metricPoint(densityB, densityA, higherIsBetter: true);

    String? winnerId;
    if (pointsA > pointsB) {
      winnerId = cityA.id;
    } else if (pointsB > pointsA) {
      winnerId = cityB.id;
    }

    return CityComparisonResult(
      cityA: cityA,
      cityB: cityB,
      universityCountA: universitiesA.length,
      universityCountB: universitiesB.length,
      stateUniversityCountA: stateA,
      stateUniversityCountB: stateB,
      foundationUniversityCountA: foundationA,
      foundationUniversityCountB: foundationB,
      avgRatingA: avgRatingA,
      avgRatingB: avgRatingB,
      avgReviewCountA: avgReviewCountA,
      avgReviewCountB: avgReviewCountB,
      populationA: cityA.population,
      populationB: cityB.population,
      topDepartmentTypesA: topDeptTypesA,
      topDepartmentTypesB: topDeptTypesB,
      universityDensityPerMillionA: densityA,
      universityDensityPerMillionB: densityB,
      winnerId: winnerId,
    );
  }

  double _average(Iterable<double> values) {
    if (values.isEmpty) return 0;
    var sum = 0.0;
    var count = 0;
    for (final v in values) {
      sum += v;
      count++;
    }
    return count == 0 ? 0 : sum / count;
  }

  int _metricPoint(double a, double b, {required bool higherIsBetter}) {
    if ((a - b).abs() < 0.0001) return 0;
    if (higherIsBetter) {
      return a > b ? 1 : 0;
    }
    return a < b ? 1 : 0;
  }

  Future<List<String>> _topDepartmentTypes(
    List<UniversityModel> universities,
  ) async {
    final departmentLists = await Future.wait(
      universities.map((u) => _universityRepository.getDepartmentsByUniversity(u.id)),
    );
    final departments = departmentLists.expand((list) => list);
    final counts = <String, int>{};
    for (final d in departments) {
      final type = _departmentTypeLabel(d);
      counts[type] = (counts[type] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });

    return sorted.take(3).map((e) => e.key).toList();
  }

  String _departmentTypeLabel(DepartmentModel d) {
    final scoreType = (d.scoreData?.scoreType ?? d.scoreType ?? '').trim();
    if (scoreType.isNotEmpty) return scoreType;
    return d.type.isNotEmpty ? d.type : 'Bilinmiyor';
  }

  double _universityDensityPerMillion({
    required int universityCount,
    required int? population,
  }) {
    if (population == null || population <= 0) return 0;
    return (universityCount / population) * 1000000;
  }
}
