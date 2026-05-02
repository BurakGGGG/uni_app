import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Place verisi olmayan üniversiteleri tespit edip temizleme scripti.
/// Dry-run modunda sadece neyi sileceğini gösterir.
/// Yorum olan üniversiteler asla silinmez.
class CleanupUniversities {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Dry-run: silinecek üniversiteleri listele ama silme.
  /// [execute] = true ise gerçekten sil.
  Future<void> run({bool execute = false}) async {
    debugPrint('🔍 Cleanup başlatılıyor (${execute ? "EXECUTE" : "DRY-RUN"})...');

    // 1. Tüm üniversiteleri çek
    final uniSnap = await _firestore.collection('universities').get();
    final allUniIds = uniSnap.docs.map((d) => d.id).toSet();
    debugPrint('📊 Toplam üniversite: ${allUniIds.length}');

    // 2. Place'i olan üniversiteleri bul
    final placesSnap = await _firestore.collection('places').get();
    final unisWithPlaces = placesSnap.docs
        .map((d) => d.data()['universityId'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toSet();
    debugPrint('📍 Place verisi olan üniversite: ${unisWithPlaces.length}');

    // 3. Place'i olmayan üniversiteleri tespit et
    final orphanUnis = allUniIds.difference(unisWithPlaces);
    if (orphanUnis.isEmpty) {
      debugPrint('✅ Temizlenecek üniversite yok!');
      return;
    }
    debugPrint('🗑️ Place verisi olmayan üniversiteler (${orphanUnis.length}):');

    // 4. Her orphan üniyi kontrol et
    for (final uniId in orphanUnis) {
      final uniDoc = await _firestore.collection('universities').doc(uniId).get();
      final uniName = uniDoc.data()?['name'] ?? uniId;

      // Yorum kontrolü
      final reviewSnap = await _firestore
          .collection('reviews')
          .where('targetId', isEqualTo: uniId)
          .limit(1)
          .get();
      final hasReviews = reviewSnap.docs.isNotEmpty;

      // Bölüm kontrolü
      final deptSnap = await _firestore
          .collection('departments')
          .where('universityId', isEqualTo: uniId)
          .get();
      final deptCount = deptSnap.docs.length;

      if (hasReviews) {
        debugPrint('  ⚠️ ATLANDI: $uniName ($uniId) — Yorumları var, silinmeyecek!');
        continue;
      }

      debugPrint('  🗑️ $uniName ($uniId) — $deptCount bölüm');

      if (execute) {
        // Bölümleri sil
        final batch = _firestore.batch();
        for (final dept in deptSnap.docs) {
          batch.delete(dept.reference);
        }
        // Üniversiteyi sil
        batch.delete(_firestore.collection('universities').doc(uniId));
        await batch.commit();
        debugPrint('     ✅ Silindi ($deptCount bölüm + 1 üniversite)');
      }
    }

    if (!execute) {
      debugPrint('\n💡 Gerçekten silmek için: run(execute: true)');
    } else {
      debugPrint('\n✅ Cleanup tamamlandı!');
    }
  }
}
