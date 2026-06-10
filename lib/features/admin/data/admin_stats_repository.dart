import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../domain/models/admin_stats_model.dart';

/// Admin istatistik ekranı için Firestore okuma repository'si.
class AdminStatsRepository {
  final FirebaseFirestore _firestore;

  AdminStatsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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

  Future<AdminStatsModel> getTodayStats() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _getDailyStats(today);
  }

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

  /// Son [days] günün günlük trend verisini getir (en eski → en yeni).
  Future<List<DailyTrendPoint>> getDailyTrend(int days) async {
    final now = DateTime.now();
    final points = <DailyTrendPoint>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final daily = await _getDailyStats(dateStr);
      points.add(
        DailyTrendPoint(
          date: dateStr,
          label: DateFormat('d MMM', 'tr').format(date),
          newUsers: daily.totalUsers,
          logins: daily.totalLogins,
        ),
      );
    }

    return points;
  }

  /// Bu hafta (7 gün) vs geçen hafta (önceki 7 gün) karşılaştırması.
  Future<PeriodComparisonModel> getWeekOverWeekComparison() async {
    final thisWeek = await getStatsForPeriod(7);
    final lastWeek = await _getStatsForDayRange(7, 14);
    return PeriodComparisonModel(
      thisPeriodNewUsers: thisWeek.totalUsers,
      lastPeriodNewUsers: lastWeek.totalUsers,
      thisPeriodLogins: thisWeek.totalLogins,
      lastPeriodLogins: lastWeek.totalLogins,
    );
  }

  Future<AdminStatsModel> _getStatsForDayRange(int startDaysAgo, int endDaysAgo) async {
    var combined = AdminStatsModel.empty;
    final now = DateTime.now();

    for (int i = startDaysAgo; i < endDaysAgo; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      combined = combined + await _getDailyStats(dateStr);
    }

    return combined;
  }

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

  Future<int> getLiveUserCount() async {
    try {
      final snap = await _firestore.collection('users').count().get();
      return snap.count ?? 0;
    } catch (e) {
      debugPrint('[AdminStatsRepository] getLiveUserCount error: $e');
      return 0;
    }
  }

  Future<AdminLiveStatsModel> getLiveStats() async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = Timestamp.fromDate(now.subtract(const Duration(days: 7)));
      final thirtyDaysAgo = Timestamp.fromDate(now.subtract(const Duration(days: 30)));

      final results = await Future.wait([
        _firestore.collection('users').count().get(),
        _firestore
            .collection('users')
            .where('isVerifiedStudent', isEqualTo: true)
            .count()
            .get(),
        _firestore
            .collection('users')
            .where('lastLoginAt', isGreaterThanOrEqualTo: sevenDaysAgo)
            .count()
            .get(),
        _firestore
            .collection('users')
            .where('lastLoginAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
            .count()
            .get(),
        _firestore
            .collection('subscriptions')
            .where('tier', isEqualTo: 'pro')
            .where('status', whereIn: ['active', 'trial'])
            .count()
            .get(),
        _firestore
            .collection('subscriptions')
            .where('tier', isEqualTo: 'plus')
            .where('status', whereIn: ['active', 'trial'])
            .count()
            .get(),
      ]);

      return AdminLiveStatsModel(
        totalUsers: results[0].count ?? 0,
        verifiedStudents: results[1].count ?? 0,
        activeUsers7d: results[2].count ?? 0,
        activeUsers30d: results[3].count ?? 0,
        proSubscribers: results[4].count ?? 0,
        plusSubscribers: results[5].count ?? 0,
      );
    } catch (e) {
      debugPrint('[AdminStatsRepository] getLiveStats error: $e');
      return AdminLiveStatsModel.empty;
    }
  }

  /// En çok görüntülenen üniversiteler (top 5).
  Future<List<TopUniversityStat>> getTopUniversities({int limit = 5}) async {
    try {
      final snap = await _firestore
          .collection('analytics')
          .doc('topUniversities')
          .collection('items')
          .orderBy('viewCount', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((doc) {
        final data = doc.data();
        return TopUniversityStat(
          universityId: doc.id,
          name: data['name'] as String? ?? doc.id,
          viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('[AdminStatsRepository] getTopUniversities error: $e');
      return [];
    }
  }
}
