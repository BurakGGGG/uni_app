import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../preference_wizard/domain/models/student_score_profile.dart';
import '../../../preference_wizard/domain/preference_match_engine.dart';
import '../../../preference_wizard/domain/rank_estimator.dart';
import '../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import '../../../score_calculator/presentation/providers/score_calculator_providers.dart';
import '../../../university/domain/models/department_model.dart';
import '../../../university/domain/models/university_model.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../domain/best_programs_engine.dart';
import '../../domain/models/best_programs_query.dart';
import '../../domain/program_category.dart';

/// Aktif filtre + kapsam durumu (Keşfet sekmesi ve liste ekranı paylaşır).
final bestProgramsQueryProvider = StateProvider<BestProgramsQuery>(
  (ref) => const BestProgramsQuery(),
);

/// id → üniversite; liste her programın şehir/tip bilgisini buradan okur.
final universitiesByIdProvider =
    FutureProvider<Map<String, UniversityModel>>((ref) async {
  ref.keepAlive();
  final unis = await ref.watch(allUniversitiesProvider.future);
  return {for (final u in unis) u.id: u};
});

/// Kullanıcının kayıtlı puan/sıra profiline göre program uygunluğu.
///
/// Profil yoksa null döner ve liste rozetsiz çalışır. Sihirbazla BİREBİR
/// aynı yolu kullanır ([evaluateDepartment] + [RankEstimator]), böylece
/// "En iyi bölümler" ekranındaki rozet tercih robotundakiyle çelişmez.
class ProgramEligibility {
  final StudentScoreProfile profile;
  final RankEstimator estimator;

  const ProgramEligibility({required this.profile, required this.estimator});

  /// Programın kullanıcı için kategorisi; puan türü tutmuyorsa ya da hiçbir
  /// sinyal kurulamıyorsa null.
  MatchCategory? categoryFor(DepartmentModel dept) {
    if (dept.effectiveScoreType?.toUpperCase() != profile.scoreType) {
      return null;
    }
    return evaluateDepartment(profile, dept, estimator: estimator)?.category;
  }

  /// Kullanıcının gerçekten girebileceği (garanti veya hedef) programlar.
  bool isReachable(DepartmentModel dept) {
    final category = categoryFor(dept);
    return category == MatchCategory.guaranteed ||
        category == MatchCategory.target;
  }
}

final programEligibilityProvider =
    FutureProvider<ProgramEligibility?>((ref) async {
  final profile = ref.watch(studentScoreProfileProvider);
  if (profile == null) return null;
  final estimator = await ref.watch(rankEstimatorProvider.future);
  return ProgramEligibility(profile: profile, estimator: estimator);
});

/// Sıralı program listesi. Ağır kısım tamamen bellekte çalışır —
/// [allScoredDepartmentsProvider] asset-öncelikli ve `keepAlive`, ek Firestore
/// okuması yok.
final bestProgramsProvider = FutureProvider.autoDispose
    .family<List<RankedProgram>, BestProgramsQuery>((ref, query) async {
  final all = await ref.watch(allScoredDepartmentsProvider.future);
  final unis = await ref.watch(universitiesByIdProvider.future);
  final ranked = BestProgramsEngine.rank(all, unis, query);

  if (!query.onlyEligible) return ranked;

  final eligibility = await ref.watch(programEligibilityProvider.future);
  if (eligibility == null) return ranked; // profil yoksa filtre uygulanamaz
  return [
    for (final program in ranked)
      if (eligibility.isReachable(program.department)) program,
  ];
});

/// Bir alandaki bölüm adları (alan → bölüm ekranı).
/// Boş anahtar → alan seçilmemiş, tüm bölümler.
final departmentsInCategoryProvider = FutureProvider.autoDispose
    .family<List<DepartmentSummary>, String>((ref, categoryKey) async {
  final category = categoryKey.isEmpty ? null : categoryByKey(categoryKey);
  if (categoryKey.isNotEmpty && category == null) return const [];
  final all = await ref.watch(allScoredDepartmentsProvider.future);
  final query = ref.watch(bestProgramsQueryProvider);
  return BestProgramsEngine.departmentsIn(category, all, query);
});

/// Bölüm adı araması (Keşfet → Bölümler sekmesindeki kutu).
final departmentSearchProvider = FutureProvider.autoDispose
    .family<List<DepartmentSummary>, String>((ref, term) async {
  if (term.trim().length < 2) return const [];
  final all = await ref.watch(allScoredDepartmentsProvider.future);
  final query = ref.watch(bestProgramsQueryProvider);
  return BestProgramsEngine.searchDepartments(
    term,
    all,
    programTypes: query.programTypes,
  );
});

/// Alan kartlarındaki program sayıları.
final categoryCountsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final all = await ref.watch(allScoredDepartmentsProvider.future);
  final query = ref.watch(bestProgramsQueryProvider);
  final counts = <String, int>{};
  for (final category in programCategories) {
    counts[category.key] =
        BestProgramsEngine.departmentsIn(category, all, query).length;
  }
  return counts;
});
