import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../monetization/domain/enums/subscription_tier.dart';
import '../../monetization/presentation/providers/subscription_providers.dart';
import '../../score_calculator/domain/models/match_result.dart';
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

/// Uygunluk kararını hesaplar. [enforceGate] false iken Plus kapısı
/// atlanır (robot sonuç kartlarında kategori zaten grup başlığından belli).
FeasibilityView watchFeasibility(
  WidgetRef ref, {
  required String? scoreType,
  required double? baseScore,
  required int? ranking,
  bool enforceGate = true,
}) {
  final profile = ref.watch(studentScoreProfileProvider);
  if (profile == null || profile.scoreType.isEmpty) {
    return const FeasibilityNoProfile();
  }

  final st = scoreType?.toUpperCase();
  if (st == null || st != profile.scoreType.toUpperCase()) {
    return const FeasibilityIncomparable();
  }

  final base = baseScore ?? 0;
  final refRank = (ranking != null && ranking > 0) ? ranking : null;
  // Öğrenci sırası: gerçek sıra > puandan tahmin (eğri hazırsa) > yok.
  final estimator = ref.watch(rankEstimatorProvider).valueOrNull;
  final student = resolveStudentRank(profile, estimator: estimator);
  final canUseRank = student != null && refRank != null;
  final canUseScore = profile.hasScore && base > 0;
  if (!canUseRank && !canUseScore) return const FeasibilityIncomparable();

  if (enforceGate) {
    final tier = ref.watch(subscriptionTierProvider).valueOrNull;
    final hasPlus = tier != null && tier.satisfies(SubscriptionTier.plus);
    if (!hasPlus) return const FeasibilityLocked();
  }

  if (canUseRank) {
    return FeasibilityVerdict(
      category: categorizeByRank(student.rank, refRank),
      basis: student.basis,
      studentRank: student.rank,
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
