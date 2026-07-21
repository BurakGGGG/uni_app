import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../monetization/domain/enums/subscription_tier.dart';
import '../../monetization/presentation/providers/subscription_providers.dart';
import '../../score_calculator/domain/models/match_result.dart';
import '../domain/models/student_score_profile.dart';
import '../domain/preference_match_engine.dart';
import 'providers/preference_wizard_providers.dart';

/// Tek bir programın kullanıcıya uygunluğunun UI durumu.
///
/// [FeasibilityChip] (renkli rozet) ve `UniDepartmentVerdict` (Üni'nin
/// cümlesi) AYNI karardan beslensin diye burada tek kaynak var — ikisi
/// birbiriyle çelişemez.
sealed class FeasibilityView {
  const FeasibilityView();
}

/// Kullanıcının puan profili hiç yok — sıralamasını isteyebiliriz.
class FeasibilityNoProfile extends FeasibilityView {
  const FeasibilityNoProfile();
}

/// Profil var ama kıyaslanamıyor: farklı puan türü ya da hiç sinyal yok.
/// Bu durumda hiçbir şey söylenmez — yanlış yönlendirmektense sessizlik.
class FeasibilityIncomparable extends FeasibilityView {
  const FeasibilityIncomparable();
}

/// Hesaplanabilir ama Plus gerekiyor.
class FeasibilityLocked extends FeasibilityView {
  const FeasibilityLocked();
}

/// Karar hazır.
class FeasibilityVerdict extends FeasibilityView {
  final MatchCategory category;
  final MatchBasis basis;

  /// Tooltip/açıklama için ham sayılar; sıra yoluyla gelmediyse null.
  final int? studentRank;
  final int? referenceRank;
  final double? placementScore;
  final double? baseScore;

  const FeasibilityVerdict({
    required this.category,
    required this.basis,
    this.studentRank,
    this.referenceRank,
    this.placementScore,
    this.baseScore,
  });

  /// Sıra puandan tahmin edildiyse Üni bunu saklamaz.
  bool get isEstimated => basis == MatchBasis.estimatedRank;
}

/// Programdan BAĞIMSIZ kapı: profil + abonelik + sıra tahmincisi.
///
/// Bir listedeki her program için ayrı ayrı okunmasın diye ayrıldı —
/// [FeasibilityReady] dönerse üstünde istediğin kadar [categorize]
/// çağırabilirsin, tek provider aramasıyla.
class FeasibilityReady extends FeasibilityView {
  final StudentScoreProfile profile;
  final ({int rank, MatchBasis basis})? student;

  /// Plus kapısı kapalıysa true. Kilit kararı [categorize] içinde, KIYAS
  /// yapılabildiği anlaşıldıktan SONRA verilir — kıyaslanamayan bir
  /// programda kullanıcıya kilit göstermek yanıltıcı olurdu.
  final bool locked;

  const FeasibilityReady({
    required this.profile,
    required this.student,
    required this.locked,
  });

  /// Tek bir programın kategorisi.
  FeasibilityView categorize({
    required String? scoreType,
    required double? baseScore,
    required int? ranking,
  }) {
    final st = scoreType?.toUpperCase();
    if (st == null || st != profile.scoreType.toUpperCase()) {
      return const FeasibilityIncomparable();
    }

    final base = baseScore ?? 0;
    final refRank = (ranking != null && ranking > 0) ? ranking : null;
    final canUseRank = student != null && refRank != null;
    final canUseScore = profile.hasScore && base > 0;
    if (!canUseRank && !canUseScore) return const FeasibilityIncomparable();

    if (locked) return const FeasibilityLocked();

    if (canUseRank) {
      return FeasibilityVerdict(
        category: categorizeByRank(student!.rank, refRank),
        basis: student!.basis,
        studentRank: student!.rank,
        referenceRank: refRank,
      );
    }
    return FeasibilityVerdict(
      category: categorizeByScore(profile.placementScore, base),
      basis: MatchBasis.score,
      placementScore: profile.placementScore,
      baseScore: base,
    );
  }
}

/// Programdan bağımsız kapıyı bir kez okur.
///
/// Profil yoksa [FeasibilityNoProfile]; varsa [FeasibilityReady] — kilit
/// bilgisi onun içinde taşınır (bkz. [FeasibilityReady.locked]).
FeasibilityView watchFeasibilityContext(
  WidgetRef ref, {
  bool enforceGate = true,
}) {
  final profile = ref.watch(studentScoreProfileProvider);
  if (profile == null || profile.scoreType.isEmpty) {
    return const FeasibilityNoProfile();
  }

  var locked = false;
  if (enforceGate) {
    final tier = ref.watch(subscriptionTierProvider).valueOrNull;
    locked = !(tier != null && tier.satisfies(SubscriptionTier.plus));
  }

  // Öğrenci sırası: gerçek sıra > puandan tahmin (eğri hazırsa) > yok.
  final estimator = ref.watch(rankEstimatorProvider).valueOrNull;
  return FeasibilityReady(
    profile: profile,
    student: resolveStudentRank(profile, estimator: estimator),
    locked: locked,
  );
}

/// Tek bir programın uygunluk kararı. [enforceGate] false iken Plus kapısı
/// atlanır (robot sonuç kartlarında kategori zaten grup başlığından belli).
FeasibilityView watchFeasibility(
  WidgetRef ref, {
  required String? scoreType,
  required double? baseScore,
  required int? ranking,
  bool enforceGate = true,
}) {
  final gate = watchFeasibilityContext(ref, enforceGate: enforceGate);
  if (gate is! FeasibilityReady) return gate;
  return gate.categorize(
    scoreType: scoreType,
    baseScore: baseScore,
    ranking: ranking,
  );
}
