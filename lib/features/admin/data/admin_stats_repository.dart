import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../domain/models/admin_stats_model.dart';

/// Admin istatistik ekranı için Firestore okuma repository'si.
///
/// Zaman filtrelerine göre pre-aggregated counter'ları okur.
class AdminStatsRepository {
  final FirebaseFirestore _firestore;

  AdminStatsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// All-time toplam istatistikleri getir (1 read).
  Future<AdminStatsModel> getAllTimeStats() async {
    try {
      final doc =
          await _firestore.collection('analytics').doc('counters').get();
      if (!doc.exists || doc.data() == null) return AdminStatsModel.empty;
      return AdminStatsModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('[AdminStatsRepository] getAllTimeStats error: $e');
      return AdminStatsModel.empty;
    }
  }

  /// Bugünün istatistiklerini getir (1 read).
  Future<AdminStatsModel> getTodayStats() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _getDailyStats(today);
  }

  /// Son [days] günün istatistiklerini topla.
  /// Bu hafta: days=7, Bu ay: days=30
  Future<AdminStatsModel> getStatsForPeriod(int days) async {
    final now = DateTime.now();
    var combined = AdminStatsModel.empty;

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final daily = await _getDailyStats(dateStr);
      combined = combined + daily;
    }

    return combined;
  }

  /// Tek bir günün istatistiklerini getir.
  Future<AdminStatsModel> _getDailyStats(String dateStr) async {
    try {
      final doc =
          await _firestore.collection('analytics').doc('daily_$dateStr').get();
      if (!doc.exists || doc.data() == null) return AdminStatsModel.empty;
      return AdminStatsModel.fromMap(doc.data()!, isDaily: true);
    } catch (e) {
      debugPrint('[AdminStatsRepository] _getDailyStats($dateStr) error: $e');
      return AdminStatsModel.empty;
    }
  }

  /// Aktif story sayısını getir (stories koleksiyonundan live query).
  Future<int> getActiveStoryCount() async {
    try {
      final snap = await _firestore
          .collection('stories')
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e) {
      debugPrint('[AdminStatsRepository] getActiveStoryCount error: $e');
      return 0;
    }
  }

  /// Toplam kullanıcı sayısını Firestore users koleksiyonundan getir.
  /// Migration sonrası counter ile eşleşmeli ama fallback olarak tutulur.
  Future<int> getLiveUserCount() async {
    try {
      final snap =
          await _firestore.collection('users').count().get();
      return snap.count ?? 0;
    } catch (e) {
      debugPrint('[AdminStatsRepository] getLiveUserCount error: $e');
      return 0;
    }
  }
}
