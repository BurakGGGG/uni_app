import '../../university/data/university_repository.dart';
import '../../university/domain/models/city_model.dart';
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

    final pointsA = _metricPoint(universitiesA.length.toDouble(),
            universitiesB.length.toDouble(), higherIsBetter: true) +
        _metricPoint(avgRatingA, avgRatingB, higherIsBetter: true) +
        _metricPoint(avgReviewCountA, avgReviewCountB, higherIsBetter: true);

    final pointsB = _metricPoint(universitiesB.length.toDouble(),
            universitiesA.length.toDouble(), higherIsBetter: true) +
        _metricPoint(avgRatingB, avgRatingA, higherIsBetter: true) +
        _metricPoint(avgReviewCountB, avgReviewCountA, higherIsBetter: true);

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
}
