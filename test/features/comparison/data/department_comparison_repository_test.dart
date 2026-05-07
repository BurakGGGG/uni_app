import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/comparison/data/department_comparison_repository.dart';
import 'package:uni_app/features/monetization/domain/enums/subscription_tier.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';

DepartmentModel _department({
  required String id,
  required String universityId,
  required String name,
  String? scoreType,
  double? baseScore,
  int? ranking,
  int? quota,
}) {
  return DepartmentModel(
    id: id,
    universityId: universityId,
    name: name,
    faculty: 'Mühendislik',
    type: 'Lisans',
    language: 'Türkçe',
    scoreType: scoreType,
    baseScore: baseScore,
    ranking: ranking,
    quota: quota,
  );
}

void main() {
  group('DepartmentComparisonRepository.compare', () {
    test('compares same department name from different universities', () async {
      final data = <String, DepartmentModel?>{
        'a': _department(
          id: 'a',
          universityId: 'u1',
          name: 'Bilgisayar Mühendisliği',
          scoreType: 'SAY',
          baseScore: 490,
          ranking: 1500,
          quota: 80,
        ),
        'b': _department(
          id: 'b',
          universityId: 'u2',
          name: 'Bilgisayar Mühendisliği',
          scoreType: 'SAY',
          baseScore: 470,
          ranking: 3500,
          quota: 70,
        ),
      };
      final repo = DepartmentComparisonRepository(
        getDepartmentById: (id) async => data[id],
      );

      final result = await repo.compare('a', 'b');

      expect(result, isNotNull);
      expect(result!.deptA.name, result.deptB.name);
      expect(result.deptA.universityId, isNot(result.deptB.universityId));
      expect(result.hasScoreTypeMismatch, isFalse);
      expect(result.winnerId, 'a');
    });

    test('flags mismatch when departments have different score types', () async {
      final data = <String, DepartmentModel?>{
        'a': _department(
          id: 'a',
          universityId: 'u1',
          name: 'Hukuk',
          scoreType: 'EA',
          baseScore: 440,
          ranking: 9000,
          quota: 100,
        ),
        'b': _department(
          id: 'b',
          universityId: 'u2',
          name: 'Hukuk',
          scoreType: 'SAY',
          baseScore: 430,
          ranking: 12000,
          quota: 90,
        ),
      };
      final repo = DepartmentComparisonRepository(
        getDepartmentById: (id) async => data[id],
      );

      final result = await repo.compare('a', 'b');
      expect(result, isNotNull);
      expect(result!.hasScoreTypeMismatch, isTrue);
    });

    test('handles departments without scoreData/baseScore safely', () async {
      final data = <String, DepartmentModel?>{
        'a': _department(
          id: 'a',
          universityId: 'u1',
          name: 'Fizik',
          scoreType: null,
          baseScore: null,
          ranking: null,
          quota: null,
        ),
        'b': _department(
          id: 'b',
          universityId: 'u2',
          name: 'Fizik',
          scoreType: null,
          baseScore: null,
          ranking: null,
          quota: null,
        ),
      };
      final repo = DepartmentComparisonRepository(
        getDepartmentById: (id) async => data[id],
      );

      final result = await repo.compare('a', 'b');
      expect(result, isNotNull);
      expect(result!.scoreDeltas['baseScore'], 0);
      expect(result.scoreDeltas['ranking'], 0);
      expect(result.scoreDeltas['fillRate'], 0);
      expect(result.scoreDeltas['quota'], 0);
    });

    test('canCompareDepartments gate allows only plus/pro', () {
      expect(canCompareDepartments(SubscriptionTier.free), isFalse);
      expect(canCompareDepartments(SubscriptionTier.plus), isTrue);
      expect(canCompareDepartments(SubscriptionTier.pro), isTrue);
    });
  });
}
