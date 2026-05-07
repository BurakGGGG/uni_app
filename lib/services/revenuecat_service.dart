import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../features/monetization/domain/enums/subscription_tier.dart';
import '../features/monetization/domain/models/subscription_model.dart';

/// RevenueCat SDK entegrasyonu — FCMService singleton pattern'i.
///
/// Uygulama başlatılırken `RevenueCatService().init()` çağrılır.
/// Kullanıcı login/logout olduğunda `login()` / `logout()` çağrılır.
class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._();
  factory RevenueCatService() => _instance;
  RevenueCatService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _initialized = false;

  // ─── Platform API Key'leri ──────────────────────────────────
  // TODO: Gerçek API key'leri .env veya dart-define ile al
  static const _androidApiKey = 'goog_YOUR_ANDROID_API_KEY';
  static const _iosApiKey = 'appl_YOUR_IOS_API_KEY';

  /// SDK'yı başlat — main.dart'ta bir kez çağrılır.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final apiKey = defaultTargetPlatform == TargetPlatform.iOS
        ? _iosApiKey
        : _androidApiKey;

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
    getCurrentTier().then(controller.add);

    // RC listener — abonelik değişikliklerinde tetiklenir
    Purchases.addCustomerInfoUpdateListener((info) {
      final tier = _tierFromCustomerInfo(info);
      controller.add(tier);
    });

    return controller.stream;
  }

  /// Mevcut offerings'i getir (paywall için).
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('[RevenueCat] getOfferings error: $e');
      return null;
    }
  }

  /// Belirtilen paketi satın al.
  Future<bool> purchasePackage(Package package) async {
    try {
      await Purchases.purchase(PurchaseParams.package(package));
      debugPrint('[RevenueCat] Purchase successful: ${package.identifier}');
      return true;
    } catch (e) {
      if (e is PurchasesErrorCode &&
          e == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('[RevenueCat] Purchase cancelled');
        return false;
      }
      debugPrint('[RevenueCat] Purchase error: $e');
      return false;
    }
  }

  /// Satın almaları geri yükle (restore purchases).
  Future<SubscriptionTier> restorePurchases() async {
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
