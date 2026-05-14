import 'dart:async';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../features/monetization/domain/enums/subscription_tier.dart';
import '../features/monetization/domain/models/subscription_model.dart';
import 'analytics_service.dart';

/// RevenueCat SDK entegrasyonu — FCMService singleton pattern'i.
///
/// Uygulama başlatılırken `RevenueCatService().init()` çağrılır.
/// Kullanıcı login/logout olduğunda `login()` / `logout()` çağrılır.
///
/// API key'leri build zamanında inject edilir:
/// ```
/// flutter run --dart-define=REVENUECAT_API_KEY_ANDROID=goog_xxx
/// flutter run --dart-define=REVENUECAT_API_KEY_IOS=appl_xxx
/// ```
class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._();
  factory RevenueCatService() => _instance;
  RevenueCatService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _initialized = false;

  // ─── Platform API Key'leri (dart-define ile inject) ──────────
  static const _androidApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY_ANDROID',
    defaultValue: '',
  );
  static const _iosApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY_IOS',
    defaultValue: '',
  );

  /// Platform'a göre doğru API key'i döndürür.
  /// Debug modda key eksikse assert ile uyarır.
  static String get _publicApiKey {
    if (!kIsWeb && Platform.isIOS) {
      assert(_iosApiKey.isNotEmpty,
          'REVENUECAT_API_KEY_IOS --dart-define ile geçilmeli');
      return _iosApiKey;
    }
    assert(_androidApiKey.isNotEmpty,
        'REVENUECAT_API_KEY_ANDROID --dart-define ile geçilmeli');
    return _androidApiKey;
  }

  /// SDK'yı başlat — main.dart'ta bir kez çağrılır.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final apiKey = _publicApiKey;

    await Purchases.configure(
      PurchasesConfiguration(apiKey)
        ..appUserID = _auth.currentUser?.uid,
    );

    // Debug modunda verbose log
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    debugPrint('[RevenueCat] Service initialized');
  }

  /// Kullanıcı login olduğunda RC'ye bağla.
  Future<void> login(String uid) async {
    try {
      await Purchases.logIn(uid);
      debugPrint('[RevenueCat] Logged in: $uid');
    } catch (e) {
      debugPrint('[RevenueCat] Login error: $e');
    }
  }

  /// Kullanıcı logout olduğunda RC'den çıkar.
  Future<void> logout() async {
    try {
      await Purchases.logOut();
      debugPrint('[RevenueCat] Logged out');
    } catch (e) {
      debugPrint('[RevenueCat] Logout error: $e');
    }
  }

  /// Mevcut müşteri bilgisinden aktif tier'ı tespit et.
  Future<SubscriptionTier> getCurrentTier() async {
    await init();
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _tierFromCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint('[RevenueCat] getCurrentTier error: $e');
      // RC offline — Firestore fallback dene
      return _firestoreFallbackTier();
    }
  }

  /// Müşteri bilgisinden tier çıkar (entitlement bazlı).
  SubscriptionTier _tierFromCustomerInfo(CustomerInfo info) {
    final entitlements = info.entitlements.active;

    if (entitlements.containsKey(RevenueCatEntitlements.pro)) {
      return SubscriptionTier.pro;
    }
    if (entitlements.containsKey(RevenueCatEntitlements.plus)) {
      return SubscriptionTier.plus;
    }
    return SubscriptionTier.free;
  }

  /// RevenueCat offline olduğunda Firestore'dan son bilinen tier'ı oku.
  Future<SubscriptionTier> _firestoreFallbackTier() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return SubscriptionTier.free;

    try {
      final doc = await _firestore.collection('subscriptions').doc(uid).get();
      if (!doc.exists) return SubscriptionTier.free;

      final sub = SubscriptionModel.fromFirestore(doc);
      return sub.effectiveTier;
    } catch (e) {
      debugPrint('[RevenueCat] Firestore fallback error: $e');
      return SubscriptionTier.free;
    }
  }

  /// Müşteri bilgisi değişikliklerini dinle (Stream).
  Stream<SubscriptionTier> get tierStream {
    final controller = StreamController<SubscriptionTier>();

    // İlk değeri hemen gönder
    getCurrentTier().then(controller.add).catchError((Object e) {
      debugPrint('[RevenueCat] tierStream initial error: $e');
      controller.add(SubscriptionTier.free);
    });

    // RC listener — abonelik değişikliklerinde tetiklenir
    Purchases.addCustomerInfoUpdateListener((info) {
      final tier = _tierFromCustomerInfo(info);
      controller.add(tier);
    });

    return controller.stream;
  }

  /// Mevcut offerings'i getir (paywall için).
  Future<Offerings?> getOfferings() async {
    await init();
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('[RevenueCat] getOfferings error: $e');
      return null;
    }
  }

  /// Belirtilen paketi satın al.
  Future<bool> purchasePackage(Package package) async {
    await init();
    try {
      await Purchases.purchase(PurchaseParams.package(package));
      debugPrint('[RevenueCat] Purchase successful: ${package.identifier}');
      final tier = package.storeProduct.identifier.contains('pro')
          ? 'pro'
          : 'plus';
      final billing = package.packageType == PackageType.annual ? 'yearly' : 'monthly';
      await AnalyticsService().logSubscriptionPurchased(
        tier: tier,
        billing: billing,
      );
      return true;
    } catch (e) {
      final errorCode = e is PlatformException
          ? PurchasesErrorHelper.getErrorCode(e)
          : PurchasesErrorCode.unknownError;
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('[RevenueCat] Purchase cancelled');
        return false;
      }
      debugPrint('[RevenueCat] Purchase error: $e');
      return false;
    }
  }

  /// Satın almaları geri yükle (restore purchases).
  Future<SubscriptionTier> restorePurchases() async {
    await init();
    try {
      final info = await Purchases.restorePurchases();
      final tier = _tierFromCustomerInfo(info);
      debugPrint('[RevenueCat] Restore result: $tier');
      return tier;
    } catch (e) {
      debugPrint('[RevenueCat] Restore error: $e');
      return SubscriptionTier.free;
    }
  }

  /// Trial kullanılmış mı kontrolü (Firestore'dan).
  Future<bool> hasUsedTrial() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return true; // Güvenli taraf: trial yok say

    try {
      final doc = await _firestore.collection('subscriptions').doc(uid).get();
      if (!doc.exists) return false;
      return doc.data()?['trialUsed'] as bool? ?? false;
    } catch (e) {
      return true;
    }
  }
}
