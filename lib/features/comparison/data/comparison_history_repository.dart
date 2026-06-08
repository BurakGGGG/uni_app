import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/models/comparison_history_entry.dart';
import '../../admin/data/analytics_service.dart';
import '../../admin/domain/models/analytics_event.dart';

/// Kullanıcı başına en fazla bu kadar geçmiş kaydı tutulur.
/// Aşıldığında en eski kayıtlar otomatik silinir (FIFO).
const int kComparisonHistoryMaxSize = 20;

class ComparisonHistoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ComparisonHistoryRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>? _refForCurrentUser() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('comparisonHistory');
  }

  /// Karşılaştırma sonucu başarılı olduğunda çağrılır.
  /// Aynı çift için varolan kayıt silinir (deduplication), yeni timestamp ile eklenir.
  /// Bu işlem misafirde (auth yok) sessizce no-op döner.
  Future<void> recordComparison({
    required ComparisonHistoryType type,
    required String entityAId,
    required String entityBId,
    required String entityAName,
    required String entityBName,
    String? entityALogo,
    String? entityBLogo,
  }) async {
    final ref = _refForCurrentUser();
    if (ref == null) return;

    try {
      // Aynı çift için (sırasız) varolan kayıtları sil
      final existing = await ref
          .where('type', isEqualTo: type.firestoreValue)
          .where('entityAId', whereIn: [entityAId, entityBId])
          .get();
      for (final doc in existing.docs) {
        final data = doc.data();
        final a = data['entityAId'];
        final b = data['entityBId'];
        if ((a == entityAId && b == entityBId) ||
            (a == entityBId && b == entityAId)) {
          await doc.reference.delete();
        }
      }

      // Yeni kayıt ekle
      await ref.add({
        'type': type.firestoreValue,
        'entityAId': entityAId,
        'entityBId': entityBId,
        'entityAName': entityAName,
        'entityBName': entityBName,
        'entityALogo': ?entityALogo,
        'entityBLogo': ?entityBLogo,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Max boyut aşıldıysa en eskileri sil (FIFO)
      final all = await ref.orderBy('createdAt', descending: true).get();
      if (all.docs.length > kComparisonHistoryMaxSize) {
        for (var i = kComparisonHistoryMaxSize; i < all.docs.length; i++) {
          await all.docs[i].reference.delete();
        }
      }

      // Analytics: karşılaştırma yapıldı
      AnalyticsService.instance.trackEvent(AnalyticsEvent.comparisonMade);
    } catch (e) {
      // Geçmiş kayıt başarısız olsa bile asıl karşılaştırma akışını bozma
      debugPrint('[ComparisonHistory] record failed: $e');
    }
  }

  /// Real-time geçmiş listesi. Misafir kullanıcı için boş stream döner.
  Stream<List<ComparisonHistoryEntry>> watchHistory({int limit = 20}) {
    final ref = _refForCurrentUser();
    if (ref == null) return Stream.value(const []);
    return ref
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ComparisonHistoryEntry.fromDoc).toList());
  }

  /// Tüm geçmişi sil.
  Future<void> clearHistory() async {
    final ref = _refForCurrentUser();
    if (ref == null) return;
    final snap = await ref.get();
    if (snap.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Tek bir geçmiş kaydını sil.
  Future<void> deleteEntry(String historyId) async {
    final ref = _refForCurrentUser();
    if (ref == null) return;
    await ref.doc(historyId).delete();
  }
}
