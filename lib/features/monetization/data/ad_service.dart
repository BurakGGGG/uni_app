import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum _RewardedAdPlacement { proUnlock, comparison }

/// Rewarded Ad yönetimi (singleton).
class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  static bool _mobileAdsInitialized = false;
  static Future<void>? _mobileAdsInitializationFuture;
  static bool _consentInfoUpdated = false;
  static Future<void>? _consentInfoUpdateFuture;

  final Map<_RewardedAdPlacement, RewardedAd> _rewardedAds = {};
  final Set<_RewardedAdPlacement> _loadingRewardedAds = {};

  Future<void> initialize() => _ensureInitialized();

  Future<void> _ensureInitialized() async {
    if (_mobileAdsInitialized || kIsWeb) return;

    final existingFuture = _mobileAdsInitializationFuture;
    if (existingFuture != null) {
      await existingFuture;
      return;
    }

    _mobileAdsInitializationFuture = () async {
      await _updateConsentInfoIfNeeded();
      await MobileAds.instance.initialize();
      _mobileAdsInitialized = true;
    }();

    try {
      await _mobileAdsInitializationFuture;
    } finally {
      if (!_mobileAdsInitialized) {
        _mobileAdsInitializationFuture = null;
      }
    }
  }

  Future<void> _updateConsentInfoIfNeeded() async {
    if (_consentInfoUpdated || kIsWeb) return;

    final existingFuture = _consentInfoUpdateFuture;
    if (existingFuture != null) {
      await existingFuture;
      return;
    }

    _consentInfoUpdateFuture = () async {
      try {
        final consentUpdateCompleter = Completer<void>();
        ConsentInformation.instance.requestConsentInfoUpdate(
          ConsentRequestParameters(),
          () {
            if (!consentUpdateCompleter.isCompleted) {
              consentUpdateCompleter.complete();
            }
          },
          (error) {
            debugPrint(
              '[AdService] Consent info update failed: '
              '${error.errorCode} ${error.message}',
            );
            if (!consentUpdateCompleter.isCompleted) {
              consentUpdateCompleter.complete();
            }
          },
        );

        await consentUpdateCompleter.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('[AdService] Consent info update timed out');
          },
        );

        await ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) {
            debugPrint(
              '[AdService] Consent form failed: '
              '${error.errorCode} ${error.message}',
            );
          }
        });
      } catch (e) {
        debugPrint('[AdService] Consent flow error: $e');
      } finally {
        _consentInfoUpdated = true;
      }
    }();

    await _consentInfoUpdateFuture;
  }

  /// Ad Unit ID'leri:
  /// Production: flutter build --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-xxx/yyy
  ///                            --dart-define=ADMOB_REWARDED_IOS=ca-app-pub-xxx/zzz
  /// Internal test: ALLOW_TEST_AD_UNITS=true ile Google test ID kullanılabilir.
  /// Debug: otomatik olarak Google test ID kullanılır.
  static const _androidRewardedId = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917', // Test ID
  );
  static const _iosRewardedId = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313', // Test ID
  );

  static const _androidComparisonRewardedId = String.fromEnvironment(
    'ADMOB_COMPARISON_REWARDED_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917', // Test ID
  );
  static const _iosComparisonRewardedId = String.fromEnvironment(
    'ADMOB_COMPARISON_REWARDED_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313', // Test ID
  );

  static const _androidInterstitialId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712', // Test ID
  );
  static const _iosInterstitialId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/4411468910', // Test ID
  );

  static const _androidBannerId = String.fromEnvironment(
    'ADMOB_BANNER_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111', // Test ID
  );
  static const _iosBannerId = String.fromEnvironment(
    'ADMOB_BANNER_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/2934735716', // Test ID
  );

  static const _androidNativeId = String.fromEnvironment(
    'ADMOB_NATIVE_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/2247696110', // Test ID
  );
  static const _iosNativeId = String.fromEnvironment(
    'ADMOB_NATIVE_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/3986624511', // Test ID
  );

  String _rewardedAdUnitIdFor(_RewardedAdPlacement placement) {
    if (Platform.isAndroid) {
      return switch (placement) {
        _RewardedAdPlacement.proUnlock => _androidRewardedId,
        _RewardedAdPlacement.comparison => _androidComparisonRewardedId,
      };
    }

    if (Platform.isIOS) {
      return switch (placement) {
        _RewardedAdPlacement.proUnlock => _iosRewardedId,
        _RewardedAdPlacement.comparison => _iosComparisonRewardedId,
      };
    }

    throw UnsupportedError('Rewarded ad bu platformda desteklenmiyor');
  }

  String _rewardedAdLogNameFor(_RewardedAdPlacement placement) {
    return switch (placement) {
      _RewardedAdPlacement.proUnlock => 'pro_unlock_rewarded',
      _RewardedAdPlacement.comparison => 'comparison_rewarded',
    };
  }

  String get _interstitialAdUnitId {
    if (Platform.isAndroid) return _androidInterstitialId;
    if (Platform.isIOS) return _iosInterstitialId;
    throw UnsupportedError('Interstitial ad bu platformda desteklenmiyor');
  }

  String get bannerAdUnitId {
    if (Platform.isAndroid) return _androidBannerId;
    if (Platform.isIOS) return _iosBannerId;
    throw UnsupportedError('Banner ad bu platformda desteklenmiyor');
  }

  String get nativeAdUnitId {
    if (Platform.isAndroid) return _androidNativeId;
    if (Platform.isIOS) return _iosNativeId;
    throw UnsupportedError('Native ad bu platformda desteklenmiyor');
  }

  Future<void> preloadRewardedAd() {
    return _preloadRewardedAd(_RewardedAdPlacement.proUnlock);
  }

  Future<void> preloadComparisonRewardedAd() {
    return _preloadRewardedAd(_RewardedAdPlacement.comparison);
  }

  Future<void> _preloadRewardedAd(_RewardedAdPlacement placement) async {
    await _ensureInitialized();
    if (kIsWeb ||
        _rewardedAds[placement] != null ||
        _loadingRewardedAds.contains(placement)) {
      return;
    }

    _loadingRewardedAds.add(placement);
    final logName = _rewardedAdLogNameFor(placement);
    try {
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitIdFor(placement),
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAds[placement] = ad;
            _loadingRewardedAds.remove(placement);
            debugPrint('[AdService] $logName loaded');
          },
          onAdFailedToLoad: (error) {
            _rewardedAds.remove(placement);
            _loadingRewardedAds.remove(placement);
            debugPrint('[AdService] $logName load failed: $error');
          },
        ),
      );
    } catch (e) {
      _loadingRewardedAds.remove(placement);
      debugPrint('[AdService] preload $logName error: $e');
    }
  }

  /// Reklam tamamen izlendi ve reward alındıysa true döner.
  /// false dönerse paywall akışı tetiklenebilir.
  Future<bool> showRewardedAd() {
    return _showRewardedAd(_RewardedAdPlacement.proUnlock);
  }

  Future<bool> showComparisonRewardedAd() {
    return _showRewardedAd(_RewardedAdPlacement.comparison);
  }

  Future<bool> _showRewardedAd(_RewardedAdPlacement placement) async {
    await _ensureInitialized();
    if (kIsWeb) return false;

    if (_rewardedAds[placement] == null) {
      await _preloadRewardedAd(placement);
      // İlk yükleme async callback ile geldiği için anlık hazır olmayabilir.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    final ad = _rewardedAds[placement];
    if (ad == null) return false;

    final completer = Completer<bool>();
    bool rewardEarned = false;
    final logName = _rewardedAdLogNameFor(placement);

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAds.remove(placement);
        if (!completer.isCompleted) {
          completer.complete(rewardEarned);
        }
        unawaited(_preloadRewardedAd(placement));
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAds.remove(placement);
        debugPrint('[AdService] $logName show failed: $error');
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        unawaited(_preloadRewardedAd(placement));
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        rewardEarned = true;
      },
    );

    return completer.future;
  }

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  Future<void> preloadInterstitialAd() async {
    await _ensureInitialized();
    if (kIsWeb || _interstitialAd != null || _isInterstitialLoading) return;

    _isInterstitialLoading = true;
    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialLoading = false;
            debugPrint('[AdService] Interstitial ad loaded');
          },
          onAdFailedToLoad: (error) {
            _interstitialAd = null;
            _isInterstitialLoading = false;
            debugPrint('[AdService] Interstitial load failed: $error');
          },
        ),
      );
    } catch (e) {
      _isInterstitialLoading = false;
      debugPrint('[AdService] preloadInterstitialAd error: $e');
    }
  }

  Future<void> showInterstitialAd() async {
    await _ensureInitialized();
    if (kIsWeb) return;

    if (_interstitialAd == null) {
      await preloadInterstitialAd();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    final ad = _interstitialAd;
    if (ad == null) return;

    final completer = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        if (!completer.isCompleted) {
          completer.complete();
        }
        unawaited(preloadInterstitialAd());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        debugPrint('[AdService] Interstitial show failed: $error');
        if (!completer.isCompleted) {
          completer.complete();
        }
        unawaited(preloadInterstitialAd());
      },
    );

    await ad.show();
    return completer.future;
  }
}
