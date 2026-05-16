import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/score_input.dart';
import '../../domain/models/match_result.dart';
import '../../domain/score_calculator_engine.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../../university/domain/models/department_model.dart';

/// Seçili puan türüne göre filtrelenmiş unique bölüm isimleri
final uniqueDepartmentNamesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final input = ref.watch(scoreInputProvider);
  final scoreType = input.scoreType;
  
  if (scoreType.isEmpty) return [];

  final repo = ref.watch(universityRepositoryProvider);
  final allDepts = await repo.getAllDepartments();

  final uniqueNames = <String>{};
  for (final d in allDepts) {
    if (d.effectiveBaseScore != null && d.effectiveBaseScore! > 0) {
      final deptType = d.effectiveScoreType?.toUpperCase();
      if (deptType != null) {
        // Sadece o puan türünü getir
        if (deptType == scoreType) {
          uniqueNames.add(d.name);
        }
      } else {
        // Puan türü belli değilse şimdilik ekleyelim
        uniqueNames.add(d.name);
      }
    }
  }

  final sorted = uniqueNames.toList()..sort();
  return sorted;
});

/// Tüm bölümler (flat list, taban puanı olan) — hesaplama için
final allScoredDepartmentsProvider =
    FutureProvider<List<DepartmentModel>>((ref) async {
  ref.keepAlive();
  final repo = ref.read(universityRepositoryProvider);

  final allDepts = await repo.getAllDepartments();

  return allDepts
      .where((d) => d.effectiveBaseScore != null && d.effectiveBaseScore! > 0)
      .toList();
});

/// Kullanıcının girdiği sınav verileri
final scoreInputProvider = StateProvider<ScoreInput>((ref) {
  return const ScoreInput(
    scoreType: '',
    obpScore: 80,
    selectedDepartment: '',
  );
});

/// Hesaplama sonucu
final calculationResultProvider =
    FutureProvider.autoDispose<CalculationResult?>((ref) async {
  final input = ref.watch(scoreInputProvider);

  // Yeterli veri yoksa null dön
  if (input.scoreType.isEmpty || input.selectedDepartment.isEmpty) {
    return null;
  }

  final allDepts = await ref.read(allScoredDepartmentsProvider.future);
  final allUnis = await ref.read(allUniversitiesProvider.future);

  return ScoreCalculatorEngine.matchUniversities(
    input: input,
    allDepartments: allDepts,
    allUniversities: allUnis,
  );
});
