import '../../../university/domain/models/department_model.dart';

class DepartmentComparisonResult {
  final DepartmentModel deptA;
  final DepartmentModel deptB;

  /// scoreDeltas:
  /// - baseScore: A - B (yüksek daha iyi)
  /// - ranking: B - A (pozitifse A daha iyi, düşük sıralama daha iyi)
  /// - fillRate: A - B (yüksek daha iyi)
  /// - quota: A - B (yüksek daha iyi)
  final Map<String, double> scoreDeltas;

  /// null ise berabere.
  final String? winnerId;

  /// Farklı puan türü varsa true.
  final bool hasScoreTypeMismatch;

  const DepartmentComparisonResult({
    required this.deptA,
    required this.deptB,
    required this.scoreDeltas,
    required this.winnerId,
    required this.hasScoreTypeMismatch,
  });

  double get baseScoreDelta => scoreDeltas['baseScore'] ?? 0;
  double get rankingDelta => scoreDeltas['ranking'] ?? 0;
  double get fillRateDelta => scoreDeltas['fillRate'] ?? 0;
  double get quotaDelta => scoreDeltas['quota'] ?? 0;
}
