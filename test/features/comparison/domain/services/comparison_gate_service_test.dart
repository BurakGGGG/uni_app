import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/comparison/domain/services/comparison_gate_service.dart';
import 'package:uni_app/features/monetization/domain/enums/subscription_tier.dart';

class _FakeUsagePort implements UsageComparisonPort {
  bool canCompareValue;
  int incrementCalls = 0;

  _FakeUsagePort({required this.canCompareValue});

  @override
  Future<bool> canCompare() async => canCompareValue;

  @override
  Future<void> incrementDailyComparison() async {
    incrementCalls++;
  }
}

class _FakeAdPort implements RewardedAdPort {
  bool adResult;
  int showCalls = 0;

  _FakeAdPort({required this.adResult});

  @override
  Future<bool> showRewardedAd() async {
    showCalls++;
    return adResult;
  }
}

void main() {
  group('ComparisonGateService', () {
    test('allows paid users without quota/ad checks', () async {
      final usage = _FakeUsagePort(canCompareValue: false);
      final ad = _FakeAdPort(adResult: false);
      final service = ComparisonGateService(usagePort: usage, adPort: ad);

      final decision = await service.checkAndConsumeQuota(SubscriptionTier.plus);

      expect(decision.isAllowed, isTrue);
      expect(usage.incrementCalls, 0);
      expect(ad.showCalls, 0);
    });

    test('free user with quota consumes daily count', () async {
      final usage = _FakeUsagePort(canCompareValue: true);
      final ad = _FakeAdPort(adResult: false);
      final service = ComparisonGateService(usagePort: usage, adPort: ad);

      final decision = await service.checkAndConsumeQuota(SubscriptionTier.free);

      expect(decision.isAllowed, isTrue);
      expect(decision.rewardedAdWatched, isFalse);
      expect(usage.incrementCalls, 1);
      expect(ad.showCalls, 0);
    });

    test('free user without quota and ad watched is allowed', () async {
      final usage = _FakeUsagePort(canCompareValue: false);
      final ad = _FakeAdPort(adResult: true);
      final service = ComparisonGateService(usagePort: usage, adPort: ad);

      final decision = await service.checkAndConsumeQuota(SubscriptionTier.free);

      expect(decision.isAllowed, isTrue);
      expect(decision.rewardedAdWatched, isTrue);
      expect(usage.incrementCalls, 1);
      expect(ad.showCalls, 1);
    });

    test('free user without quota and ad not watched requires paywall', () async {
      final usage = _FakeUsagePort(canCompareValue: false);
      final ad = _FakeAdPort(adResult: false);
      final service = ComparisonGateService(usagePort: usage, adPort: ad);

      final decision = await service.checkAndConsumeQuota(SubscriptionTier.free);

      expect(decision.status, ComparisonGateStatus.paywallRequired);
      expect(usage.incrementCalls, 0);
      expect(ad.showCalls, 1);
    });
  });
}
