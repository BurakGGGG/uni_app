import '../../university/data/university_repository.dart';
import '../../university/domain/models/department_model.dart';
import '../domain/models/department_comparison.dart';

class DepartmentComparisonRepository {
  final UniversityRepository? _universityRepository;
  final Future<DepartmentModel?> Function(String departmentId)? _getDepartmentById;

  DepartmentComparisonRepository({
    UniversityRepository? universityRepository,
    Future<DepartmentModel?> Function(String departmentId)? getDepartmentById,
  })  : _universityRepository =
            getDepartmentById == null ? (universityRepository ?? UniversityRepository()) : universityRepository,
        _getDepartmentById = getDepartmentById;

  Future<DepartmentComparisonResult?> compare(
    String departmentIdA,
    String departmentIdB,
  ) async {
    if (departmentIdA == departmentIdB) {
      throw ArgumentError('Aynı bölüm karşılaştırılamaz');
    }

    final results = await Future.wait([
      _readDepartment(departmentIdA),
      _readDepartment(departmentIdB),
    ]);

    final deptA = results[0];
    final deptB = results[1];
    if (deptA == null || deptB == null) return null;

    final baseA = deptA.baseScore ?? deptA.scoreData?.baseScore ?? 0;
    final baseB = deptB.baseScore ?? deptB.scoreData?.baseScore ?? 0;

    final rankA = (deptA.ranking ?? deptA.scoreData?.ranking)?.toDouble() ?? 0;
    final rankB = (deptB.ranking ?? deptB.scoreData?.ranking)?.toDouble() ?? 0;

    final quotaA = (deptA.quota ?? deptA.scoreData?.quota)?.toDouble() ?? 0;
    final quotaB = (deptB.quota ?? deptB.scoreData?.quota)?.toDouble() ?? 0;

    final fillA = _fillRate(
      quota: deptA.scoreData?.quota ?? deptA.quota,
      placed: deptA.scoreData?.placedCount,
    );
    final fillB = _fillRate(
      quota: deptB.scoreData?.quota ?? deptB.quota,
      placed: deptB.scoreData?.placedCount,
    );

    final scoreDeltas = <String, double>{
      'baseScore': baseA - baseB,
      'ranking': rankB - rankA,
      'fillRate': fillA - fillB,
      'quota': quotaA - quotaB,
    };

    final pointsA = _metricPoint(baseA, baseB, higherIsBetter: true) +
        _metricPoint(rankA, rankB, higherIsBetter: false) +
        _metricPoint(fillA, fillB, higherIsBetter: true) +
        _metricPoint(quotaA, quotaB, higherIsBetter: true);

    final pointsB = _metricPoint(baseB, baseA, higherIsBetter: true) +
        _metricPoint(rankB, rankA, higherIsBetter: false) +
        _metricPoint(fillB, fillA, higherIsBetter: true) +
        _metricPoint(quotaB, quotaA, higherIsBetter: true);

    String? winnerId;
    if (pointsA > pointsB) {
      winnerId = deptA.id;
    } else if (pointsB > pointsA) {
      winnerId = deptB.id;
    }

    final scoreTypeA = deptA.scoreType ?? deptA.scoreData?.scoreType;
    final scoreTypeB = deptB.scoreType ?? deptB.scoreData?.scoreType;
    final hasScoreTypeMismatch = scoreTypeA != null &&
        scoreTypeB != null &&
        scoreTypeA.isNotEmpty &&
        scoreTypeB.isNotEmpty &&
        scoreTypeA != scoreTypeB;

    return DepartmentComparisonResult(
      deptA: deptA,
      deptB: deptB,
      scoreDeltas: scoreDeltas,
      winnerId: winnerId,
      hasScoreTypeMismatch: hasScoreTypeMismatch,
    );
  }

  int _metricPoint(double a, double b, {required bool higherIsBetter}) {
    if ((a - b).abs() < 0.0001) return 0;
    if (higherIsBetter) {
      return a > b ? 1 : 0;
    }
    return a < b ? 1 : 0;
  }

  double _fillRate({int? quota, int? placed}) {
    if (quota == null || placed == null || quota <= 0) return 0;
    return placed / quota;
  }

  Future<DepartmentModel?> _readDepartment(String departmentId) {
    final getDepartmentById = _getDepartmentById;
    if (getDepartmentById != null) {
      return getDepartmentById(departmentId);
    }
    final universityRepository = _universityRepository;
    if (universityRepository == null) return Future.value(null);
    return universityRepository.getDepartment(departmentId);
  }
}
