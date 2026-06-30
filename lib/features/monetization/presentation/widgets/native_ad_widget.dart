import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../data/ad_service.dart';
import '../providers/subscription_providers.dart';
import '../../domain/enums/subscription_tier.dart';
import '../../../../services/analytics_service.dart';

class NativeAdWidget extends ConsumerStatefulWidget {
  const NativeAdWidget({super.key});

  @override
  ConsumerState<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAdIfNeeded();
  }

  Future<void> _loadAdIfNeeded() async {
    if (kIsWeb || _nativeAd != null || _isLoading) return;

    final tierAsync = ref.read(subscriptionTierProvider);
    final showAds = tierAsync.valueOrNull == SubscriptionTier.free;

    if (showAds) {
      _isLoading = true;
      try {
        await AdService().initialize();
      } catch (e) {
        debugPrint('[NativeAdWidget] MobileAds init failed: $e');
        _isLoading = false;
        return;
      }

      if (!mounted) {
        _isLoading = false;
        return;
      }

      final updatedTierAsync = ref.read(subscriptionTierProvider);
      final shouldStillShowAds =
          updatedTierAsync.valueOrNull == SubscriptionTier.free;
      if (!shouldStillShowAds) {
        _isLoading = false;
        _disposeAd();
        return;
      }

      _nativeAd = NativeAd(
        adUnitId: AdService().nativeAdUnitId,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            _isLoading = false;
            if (mounted) {
              setState(() {
                _isLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _nativeAd = null;
            _isLoading = false;
            debugPrint('[NativeAdWidget] NativeAd failed to load: $error');
          },
          onAdImpression: (ad) {
            unawaited(AnalyticsService().logNativeAdImpression());
          },
        ),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.small,
          mainBackgroundColor: Theme.of(context).cardColor,
          cornerRadius: 12.0,
        ),
      )..load();
    } else {
      _disposeAd();
    }
  }

  void _disposeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    if (mounted) {
      setState(() {
        _isLoaded = false;
      });
    }
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();

    final tierAsync = ref.watch(subscriptionTierProvider);
    final showAds = tierAsync.valueOrNull == SubscriptionTier.free;

    if (!showAds || _nativeAd == null || !_isLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      height: 90, // Small template has 90dp height
      alignment: Alignment.center,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
