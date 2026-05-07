import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/enums/subscription_tier.dart';
import '../domain/models/subscription_model.dart';

/// Firestore `subscriptions/{uid}` collection üzerinde okuma/yazma.
///
/// Yazma normalde Cloud Function (RevenueCat webhook) tarafından yapılır.
/// Bu repository client tarafında sadece okuma ve fallback kontrolü sağlar.
class SubscriptionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SubscriptionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Koleksiyon referansı.
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('subscriptions');

  /// Mevcut kullanıcının UID'si.
  String? get _uid => _auth.currentUser?.uid;

  // ─── Okuma ─────────────────────────────────────────────────

  /// Mevcut kullanıcının abonelik bilgisini getir.
  /// Doküman yoksa `SubscriptionModel.free()` döner.
  Future<SubscriptionModel> getSubscription() async {
    final uid = _uid;
    if (uid == null) return SubscriptionModel.free('anonymous');

    try {
      final doc = await _collection.doc(uid).get();
      if (!doc.exists) return SubscriptionModel.free(uid);
      return SubscriptionModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[SubscriptionRepo] getSubscription error: $e');
      return SubscriptionModel.free(uid);
    }
  }

  /// Mevcut kullanıcının abonelik bilgisini stream olarak dinle.
  Stream<SubscriptionModel> watchSubscription() {
    final uid = _uid;
    if (uid == null) {
      return Stream.value(SubscriptionModel.free('anonymous'));
    }

    return _collection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return SubscriptionModel.free(uid);
      return SubscriptionModel.fromFirestore(doc);
    }).handleError((e) {
      debugPrint('[SubscriptionRepo] watchSubscription error: $e');
      return SubscriptionModel.free(uid);
    });
  }

  /// Mevcut kullanıcının efektif tier'ını getir.
  Future<SubscriptionTier> getEffectiveTier() async {
    final sub = await getSubscription();
    return sub.effectiveTier;
  }

  /// Efektif tier'ı stream olarak dinle.
  Stream<SubscriptionTier> watchEffectiveTier() {
    return watchSubscription().map((sub) => sub.effectiveTier);
  }

  // ─── Yazma (Admin / Debug) ─────────────────────────────────
  // Normalde Cloud Function yapar, ancak debug/test için tutuyoruz.

  /// Abonelik dokümanını oluştur veya güncelle (debug amaçlı).
  /// Production'da bu metod kullanılmamalı — webhook yapar.
  Future<void> setSubscription(SubscriptionModel model) async {
    try {
      await _collection.doc(model.uid).set(
            model.toFirestore(),
            SetOptions(merge: true),
          );
      debugPrint('[SubscriptionRepo] Subscription set for: ${model.uid}');
    } catch (e) {
      debugPrint('[SubscriptionRepo] setSubscription error: $e');
      rethrow;
    }
  }
}
