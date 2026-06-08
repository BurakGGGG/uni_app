import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Mevcut Firestore verilerinden analytics counter'larını dolduran
/// tek seferlik migration scripti.
///
/// Bu script admin panelinden çalıştırılabilir veya bir kerelik
/// elle tetiklenebilir. `analytics/counters` dokümanını mevcut
/// koleksiyon sayılarıyla doldurur.
class AnalyticsMigrationService {
  final FirebaseFirestore _firestore;

  AnalyticsMigrationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Mevcut koleksiyonlardan count'ları çekip counter dokümanını doldurur.
  /// İdempotent: Birden fazla çalıştırılabilir, her seferinde üzerine yazar.
  Future<Map<String, int>> runMigration() async {
    debugPrint('[AnalyticsMigration] Migration başlatılıyor...');

    final results = <String, int>{};

    try {
      // 1. Toplam kullanıcı sayısı
      final usersCount = await _getCollectionCount('users');
      results['totalUsers'] = usersCount;
      debugPrint('  → Kullanıcılar: $usersCount');

      // 2. Toplam yorum sayısı (sadece onaylı — security rules filtresi)
      final reviewsCount = await _getFilteredCount(
        'reviews',
        field: 'isApproved',
        value: true,
      );
      results['totalReviews'] = reviewsCount;
      debugPrint('  → Yorumlar: $reviewsCount');

      // 3. Toplam beğeni sayısı
      //    Security rules filtreli sum query kullan
      final totalLikes = await _sumFieldFiltered(
        'reviews',
        'likes',
        filterField: 'isApproved',
        filterValue: true,
      );
      results['totalLikes'] = totalLikes;
      debugPrint('  → Beğeniler: $totalLikes');

      // 4. Toplam story sayısı
      final storiesCount = await _getCollectionCount('stories');
      results['totalStories'] = storiesCount;
      debugPrint('  → Story\'ler: $storiesCount');

      // 5. Toplam rapor sayısı
      final reportsCount = await _safeCount('reports');
      results['totalReports'] = reportsCount;
      debugPrint('  → Raporlar: $reportsCount');

      // Counter dokümanını güncelle
      await _firestore.collection('analytics').doc('counters').set(
        {
          'totalUsers': usersCount,
          'totalReviews': reviewsCount,
          'totalLikes': totalLikes,
          'totalReports': reportsCount,
          // Bunları 0'dan başlatabiliriz çünkü geçmiş verisi yok:
          'totalLogins': 0,
          'totalStoryViews': 0,
          'totalComparisons': 0,
          'totalScoreCalculations': 0,
          'totalFavorites': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
          'migrationDate': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint('[AnalyticsMigration] ✅ Migration tamamlandı!');
    } catch (e) {
      debugPrint('[AnalyticsMigration] ❌ Migration hatası: $e');
      rethrow;
    }

    return results;
  }

  /// Koleksiyon toplam doküman sayısı
  Future<int> _getCollectionCount(String collectionPath) async {
    final snap =
        await _firestore.collection(collectionPath).count().get();
    return snap.count ?? 0;
  }

  /// Güvenli count — permission hatası olursa 0 döner
  Future<int> _safeCount(String collectionPath) async {
    try {
      return await _getCollectionCount(collectionPath);
    } catch (e) {
      debugPrint('[AnalyticsMigration] count($collectionPath) failed: $e');
      return 0;
    }
  }

  /// Filtrelenmiş doküman sayısı
  Future<int> _getFilteredCount(
    String collectionPath, {
    required String field,
    required dynamic value,
  }) async {
    final snap = await _firestore
        .collection(collectionPath)
        .where(field, isEqualTo: value)
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Filtrelenmiş bir koleksiyonda bir alanın toplamını hesapla.
  /// Security rules'a uygun filtre ile çalışır.
  Future<int> _sumFieldFiltered(
    String collectionPath,
    String field, {
    required String filterField,
    required dynamic filterValue,
  }) async {
    try {
      // Önce filtreli aggregate sum dene
      final snap = await _firestore
          .collection(collectionPath)
          .where(filterField, isEqualTo: filterValue)
          .aggregate(sum(field))
          .get();
      return snap.getSum(field)?.toInt() ?? 0;
    } catch (e) {
      debugPrint(
          '[AnalyticsMigration] filteredSum($field) failed, trying fallback: $e');

      // Fallback: filtreli dokümanları çekip elle topla
      try {
        final querySnap = await _firestore
            .collection(collectionPath)
            .where(filterField, isEqualTo: filterValue)
            .get();
        int total = 0;
        for (final doc in querySnap.docs) {
          total += (doc.data()[field] as num?)?.toInt() ?? 0;
        }
        return total;
      } catch (e2) {
        debugPrint('[AnalyticsMigration] fallback also failed: $e2');
        return 0;
      }
    }
  }
}
