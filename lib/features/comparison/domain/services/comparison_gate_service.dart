import '../../../monetization/domain/enums/subscription_tier.dart';

abstract class UsageComparisonPort {
  Future<bool> canCompare();
  Future<void> incrementDailyComparison();
}

abstract class RewardedAdPort {
  Future<bool> showRewardedAd();
}

enum ComparisonGateStatus {
  allowed,
  paywallRequired,
}

class ComparisonGateDecision {
  final ComparisonGateStatus status;
  final bool rewardedAdWatched;

  const ComparisonGateDecision({
    required this.status,
    this.rewardedAdWatched = false,
  });

  bool get isAllowed => status == ComparisonGateStatus.allowed;
}

class ComparisonGateService {
  final UsageComparisonPort usagePort;
  final RewardedAdPort adPort;

  const ComparisonGateService({
    required this.usagePort,
    required this.adPort,
  });

  /// Free:
  /// - günlük hak varsa direkt izin + sayaç artır.
  /// - hak doluysa rewarded ad izlemişse izin + sayaç artır.
  /// - ad izlenmezse paywall.
  ///
  /// Plus/Pro:
  /// - her zaman izin.
  Future<ComparisonGateDecision> checkAndConsumeQuota(
    SubscriptionTier tier,
  ) async {
    if (tier != SubscriptionTier.free) {
      return const ComparisonGateDecision(status: ComparisonGateStatus.allowed);
    }

    final canCompare = await usagePort.canCompare();
    if (canCompare) {
      await usagePort.incrementDailyComparison();
      return const ComparisonGateDecision(status: ComparisonGateStatus.allowed);
    }

    final watched = await adPort.showRewardedAd();
    if (!watched) {
      return const ComparisonGateDecision(
        status: ComparisonGateStatus.paywallRequired,
      );
    }

    await usagePort.incrementDailyComparison();
    return const ComparisonGateDecision(
      status: ComparisonGateStatus.allowed,
      rewardedAdWatched: true,
    );
  }
}
