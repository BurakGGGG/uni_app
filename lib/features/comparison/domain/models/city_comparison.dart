import '../../../university/domain/models/city_model.dart';

class CityComparisonResult {
  final CityModel cityA;
  final CityModel cityB;

  final int universityCountA;
  final int universityCountB;
  final int stateUniversityCountA;
  final int stateUniversityCountB;
  final int foundationUniversityCountA;
  final int foundationUniversityCountB;

  final double avgRatingA;
  final double avgRatingB;
  final double avgReviewCountA;
  final double avgReviewCountB;
  final int? populationA;
  final int? populationB;
  final List<String> topDepartmentTypesA;
  final List<String> topDepartmentTypesB;
  final double universityDensityPerMillionA;
  final double universityDensityPerMillionB;

  final String? winnerId;

  const CityComparisonResult({
    required this.cityA,
    required this.cityB,
    required this.universityCountA,
    required this.universityCountB,
    required this.stateUniversityCountA,
    required this.stateUniversityCountB,
    required this.foundationUniversityCountA,
    required this.foundationUniversityCountB,
    required this.avgRatingA,
    required this.avgRatingB,
    required this.avgReviewCountA,
    required this.avgReviewCountB,
    this.populationA,
    this.populationB,
    this.topDepartmentTypesA = const [],
    this.topDepartmentTypesB = const [],
    this.universityDensityPerMillionA = 0,
    this.universityDensityPerMillionB = 0,
    required this.winnerId,
  });

  double get avgRatingDelta => avgRatingA - avgRatingB;
  int get universityCountDelta => universityCountA - universityCountB;
  int? get populationDelta {
    if (populationA == null || populationB == null) return null;
    return populationA! - populationB!;
  }
}
