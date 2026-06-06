import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Rewarded Ad yönetimi (singleton).
class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  static bool _mobileAdsInitialized = false;

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  Future<void> _ensureInitialized() async {
    if (_mobileAdsInitialized || kIsWeb) return;
    await MobileAds.instance.initialize();
    _mobileAdsInitialized = true;
  }

  /// Ad Unit ID'leri:
  /// Production: flutter build --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-xxx/yyy
  ///                            --dart-define=ADMOB_REWARDED_IOS=ca-app-pub-xxx/zzz
  /// Debug: otomatik olarak Google test ID kullanılır.
  static const _androidRewardedId = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917', // Test ID
  );
  static const _iosRewardedId = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313', // Test ID
  );

  String get _rewardedAdUnitId {
    if (Platform.isAndroid) return _androidRewardedId;
    if (Platform.isIOS) return _iosRewardedId;
    throw UnsupportedError('Rewarded ad bu platformda desteklenmiyor');
  }

  Future<void> preloadRewardedAd() async {
    await _ensureInitialized();
    if (kIsWeb || _rewardedAd != null || _isLoading) return;

    _isLoading = true;
    try {
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isLoading = false;
            debugPrint('[AdService] Rewarded ad loaded');
          },
          onAdFailedToLoad: (error) {
            _rewardedAd = null;
            _isLoading = false;
            debugPrint('[AdService] Rewarded load failed: $error');
          },
        ),
      );
    } catch (e) {
      _isLoading = false;
      debugPrint('[AdService] preloadRewardedAd error: $e');
    }
  }

  /// Reklam tamamen izlendi ve reward alındıysa true döner.
  /// false dönerse paywall akışı tetiklenebilir.
  Future<bool> showRewardedAd() async {
    await _ensureInitialized();
    if (kIsWeb) return false;

    if (_rewardedAd == null) {
      await preloadRewardedAd();
      // İlk yükleme async callback ile geldiği için anlık hazır olmayabilir.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    final ad = _rewardedAd;
    if (ad == null) return false;

    final completer = Completer<bool>();
    bool rewardEarned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        if (!completer.isCompleted) {
          completer.complete(rewardEarned);
        }
        unawaited(preloadRewardedAd());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        debugPrint('[AdService] show failed: $error');
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        unawaited(preloadRewardedAd());
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        rewardEarned = true;
      },
    );

    return completer.future;
  }
}
