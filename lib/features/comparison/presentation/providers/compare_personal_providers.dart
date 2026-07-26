import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../preference_wizard/domain/preference_match_engine.dart';
import '../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import '../../../score_calculator/presentation/providers/score_calculator_providers.dart';
import '../../../university/presentation/providers/university_providers.dart';

/// Kaydedilmiş profile göre TÜM programların eşleşmesi.
///
/// **Filtresiz** (`wizardFilterProvider` kasten okunmuyor): keşif ekranında
/// bırakılmış bir şehir filtresi karşılaştırmanın cevabını sessizce
/// daraltırdı — "İTÜ'de 2 bölüm uyuyor" derken aslında 40 bölüm uyuyor
/// olurdu. Burada sorulan soru filtreli değil.
final compareMatchProvider =
    FutureProvider.autoDispose<PreferenceMatchResult?>((ref) async {
  final profile = ref.watch(studentScoreProfileProvider);
  if (profile == null || profile.scoreType.isEmpty) return null;

  final allDepts = await ref.watch(allScoredDepartmentsProvider.future);
  final allUnis = await ref.watch(allUniversitiesProvider.future);
  final estimator = await ref.watch(rankEstimatorProvider.future);

  return PreferenceMatchEngine.matchAllPrograms(
    profile: profile,
    allDepartments: allDepts,
    allUniversities: allUnis,
    estimator: estimator,
  );
});

/// Bir üniversitede öğrencinin puanına uyan programlar.
class CompareEligibility {
  /// Gerçekçi olanlar: güvenli + hedef. Zorlayıcılar sayıma girmez —
  /// "uyuyor" derken bir öğrencinin giremeyeceği programı saymak
  /// yanıltıcı olur.
  final List<UniversityMatch> matches;

  /// Zorlayıcı bant — ayrı tutuluyor ki listeye eklemede istenirse
  /// gösterilebilsin.
  final List<UniversityMatch> reach;

  const CompareEligibility({required this.matches, required this.reach});

  int get count => matches.length;

  bool get isEmpty => matches.isEmpty && reach.isEmpty;

  /// Girmesi en zor olan program — "en yükseği" cümlesi bunu söylüyor.
  /// Sırası bilinen programlar arasında en küçük sıra.
  UniversityMatch? get hardest {
    UniversityMatch? best;
    for (final m in matches) {
      final rank = m.departmentRanking;
      if (rank == null || rank <= 0) continue;
      final bestRank = best?.departmentRanking;
      if (bestRank == null || rank < bestRank) best = m;
    }
    return best ?? (matches.isEmpty ? null : matches.first);
  }
}

/// Üniversite kimliğine göre uygunluk dilimi.
final compareEligibilityProvider = FutureProvider.autoDispose
    .family<CompareEligibility?, String>((ref, uniId) async {
  final result = await ref.watch(compareMatchProvider.future);
  if (result == null) return null;

  List<UniversityMatch> forUni(List<UniversityMatch> source) =>
      source.where((m) => m.university.id == uniId).toList();

  return CompareEligibility(
    matches: [...forUni(result.guaranteed), ...forUni(result.target)],
    reach: forUni(result.dream),
  );
});
