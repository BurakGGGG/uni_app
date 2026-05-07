import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/models/usage_stats_model.dart';

/// Firestore `users/{uid}/usageStats/current` dokümanı üzerinde işlemler.
///
/// Günlük karşılaştırma sayacı artırma, sıfırlama kontrolü ve
/// limit sorgulaması bu repository üzerinden yapılır.
class UsageStatsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UsageStatsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Kullanıcının usageStats doküman referansı.
  DocumentReference<Map<String, dynamic>>? get _docRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('usageStats')
        .doc('current');
  }

  // ─── Okuma ─────────────────────────────────────────────────

  /// Mevcut kullanım istatistiklerini getir.
  /// Doküman yoksa veya gün değişmişse otomatik sıfırla.
  Future<UsageStatsModel> getUsageStats() async {
    final ref = _docRef;
    if (ref == null) return UsageStatsModel.initial();

    try {
      final doc = await ref.get();
      if (!doc.exists) {
        final initial = UsageStatsModel.initial();
        await ref.set(initial.toFirestore());
        return initial;
      }

      var stats = UsageStatsModel.fromFirestore(doc);

      // Gün değişmişse client-side sıfırla
      if (stats.needsReset) {
        stats = await _resetDailyStats(stats);
      }

      return stats;
    } catch (e) {
      debugPrint('[UsageStatsRepo] getUsageStats error: $e');
      return UsageStatsModel.initial();
    }
  }

  /// Kullanım istatistiklerini stream olarak dinle.
  Stream<UsageStatsModel> watchUsageStats() {
    final ref = _docRef;
    if (ref == null) {
      return Stream.value(UsageStatsModel.initial());
    }

    return ref.snapshots().map((doc) {
      if (!doc.exists) return UsageStatsModel.initial();

      final stats = UsageStatsModel.fromFirestore(doc);

      // Gün değişmişse sıfırlama tetikle (async — fire and forget)
      if (stats.needsReset) {
        _resetDailyStats(stats);
      }

      return stats;
    }).handleError((e) {
      debugPrint('[UsageStatsRepo] watchUsageStats error: $e');
      return UsageStatsModel.initial();
    });
  }

  // ─── Yazma ─────────────────────────────────────────────────

  /// Günlük karşılaştırma sayacını 1 artır + toplam sayacı artır.
  Future<void> incrementDailyComparison() async {
    final ref = _docRef;
    if (ref == null) return;

    try {
      // Önce güncel stats'ı al, gün değişmişse sıfırla
      await getUsageStats();

      await ref.update({
        'dailyComparisons': FieldValue.increment(1),
        'totalComparisons': FieldValue.increment(1),
      });
      debugPrint('[UsageStatsRepo] Daily comparison incremented');
    } catch (e) {
      debugPrint('[UsageStatsRepo] incrementDailyComparison error: $e');
    }
  }

  /// Free kullanıcı şu an karşılaştırma yapabilir mi?
  Future<bool> canCompare() async {
    final stats = await getUsageStats();
    return stats.canFreeCompare;
  }

  /// Pro kullanıcı AI karşılaştırma özeti alabilir mi?
  Future<bool> canAiCompare() async {
    final stats = await getUsageStats();
    return stats.canAiCompare;
  }

  /// Pro kullanıcı AI öneri yapabilir mi?
  Future<bool> canAiRecommend() async {
    final stats = await getUsageStats();
    return stats.canAiRecommend;
  }

  // ─── Dahili ────────────────────────────────────────────────

  /// Günlük sayaçları sıfırla (client-side gün değişikliği kontrolü).
  /// AI sayaçları Cloud Function tarafından sıfırlanır, burada sadece
  /// dailyComparisons sıfırlanır.
  Future<UsageStatsModel> _resetDailyStats(UsageStatsModel current) async {
    final ref = _docRef;
    if (ref == null) return current;

    final resetted = current.copyWith(
      dailyComparisons: 0,
      lastResetDate: UsageStatsModel.todayString,
    );

    try {
      // Client sadece izin verilen alanları günceller
      await ref.update({
        'dailyComparisons': 0,
        'lastResetDate': UsageStatsModel.todayString,
      });
      debugPrint('[UsageStatsRepo] Daily stats reset for new day');
    } catch (e) {
      // Doküman yoksa oluştur
      if (e is FirebaseException && e.code == 'not-found') {
        await ref.set(resetted.toFirestore());
      }
      debugPrint('[UsageStatsRepo] resetDailyStats error: $e');
    }

    return resetted;
  }
}
