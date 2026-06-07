import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/score_input.dart';
import '../../domain/models/match_result.dart';
import '../../domain/score_calculator_engine.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../../university/domain/models/department_model.dart';

/// Tüm unique bölüm isimleri (puan türünden bağımsız)
final uniqueDepartmentNamesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final repo = ref.watch(universityRepositoryProvider);
  final allDepts = await repo.getAllDepartments();

  final uniqueNames = <String>{};
  for (final d in allDepts) {
    if (d.effectiveBaseScore > 0) {
      uniqueNames.add(d.name);
    }
  }

  final sorted = uniqueNames.toList()..sort();
  return sorted;
});

/// Seçilen bölüm adına göre puan türlerini belirler
/// Örn: "Tıp" → ['SAY'],  "Hukuk" → ['EA', 'SÖZ']
final departmentScoreTypesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final input = ref.watch(scoreInputProvider);
  if (input.selectedDepartment.isEmpty) return [];

  final repo = ref.read(universityRepositoryProvider);
  final allDepts = await repo.getAllDepartments();

  final scoreTypes = <String>{};
  for (final d in allDepts) {
    if (d.name.toLowerCase().trim() ==
            input.selectedDepartment.toLowerCase().trim() &&
        d.effectiveBaseScore > 0) {
      final st = d.effectiveScoreType?.toUpperCase();
      if (st != null && st.isNotEmpty) {
        scoreTypes.add(st);
      }
    }
  }

  // Eğer tek bir puan türü varsa otomatik seç
  if (scoreTypes.length == 1) {
    final type = scoreTypes.first;
    final current = ref.read(scoreInputProvider);
    if (current.scoreType != type) {
      // Bir sonraki frame'de state'i güncelle
      Future.microtask(() {
        ref.read(scoreInputProvider.notifier).state =
            current.copyWith(scoreType: type);
      });
    }
  }

  return scoreTypes.toList()..sort();
});

/// Tüm bölümler (flat list, taban puanı olan) — hesaplama için
final allScoredDepartmentsProvider =
    FutureProvider<List<DepartmentModel>>((ref) async {
  ref.keepAlive();
  final repo = ref.read(universityRepositoryProvider);

  final allDepts = await repo.getAllDepartments();

  return allDepts.where((d) => d.effectiveBaseScore > 0).toList();
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
