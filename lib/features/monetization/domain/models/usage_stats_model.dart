import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Kullanıcının günlük kullanım istatistikleri.
///
/// Firestore path: `users/{uid}/usageStats/current`
/// Client tarafı: dailyComparisons, totalComparisons güncelleyebilir.
/// Cloud Function: dailyAiComparisons, dailyAiRecommendations sıfırlar.
class UsageStatsModel {
  final int dailyComparisons;
  final int dailyAiComparisons;
  final int dailyAiRecommendations;
  final String lastResetDate; // "2026-05-07" formatında
  final int totalComparisons;

  const UsageStatsModel({
    this.dailyComparisons = 0,
    this.dailyAiComparisons = 0,
    this.dailyAiRecommendations = 0,
    required this.lastResetDate,
    this.totalComparisons = 0,
  });

  /// Bugünün tarih string'i (sıfırlama kontrolü için).
  static String get todayString => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Sıfır değerlerle yeni bir model oluştur.
  factory UsageStatsModel.initial() {
    return UsageStatsModel(
      lastResetDate: todayString,
    );
  }

  /// Firestore dokümanından model oluştur.
  factory UsageStatsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return UsageStatsModel(
      dailyComparisons: data['dailyComparisons'] as int? ?? 0,
      dailyAiComparisons: data['dailyAiComparisons'] as int? ?? 0,
      dailyAiRecommendations: data['dailyAiRecommendations'] as int? ?? 0,
      lastResetDate: data['lastResetDate'] as String? ?? todayString,
      totalComparisons: data['totalComparisons'] as int? ?? 0,
    );
  }

  /// Firestore'a yazılacak map.
  Map<String, dynamic> toFirestore() {
    return {
      'dailyComparisons': dailyComparisons,
      'dailyAiComparisons': dailyAiComparisons,
      'dailyAiRecommendations': dailyAiRecommendations,
      'lastResetDate': lastResetDate,
      'totalComparisons': totalComparisons,
    };
  }

  /// Bugün sıfırlama gerekli mi? (lastResetDate != bugün)
  bool get needsReset => lastResetDate != todayString;

  // ─── Free Plan Limitleri ───────────────────────────────────

  /// Free kullanıcılar günde 1 ücretsiz karşılaştırma hakkına sahip.
  static const int freeComparisonLimit = 1;

  /// Free kullanıcı ücretsiz karşılaştırma yapabilir mi?
  bool get canFreeCompare => dailyComparisons < freeComparisonLimit;

  // ─── Pro Plan Limitleri ────────────────────────────────────

  /// Pro kullanıcılar günde 5 AI karşılaştırma özeti alabilir.
  static const int proAiComparisonLimit = 5;

  /// Pro kullanıcılar günde 10 AI öneri sorgusu yapabilir.
  static const int proAiRecommendationLimit = 10;

  /// Pro kullanıcı AI karşılaştırma özeti alabilir mi?
  bool get canAiCompare => dailyAiComparisons < proAiComparisonLimit;

  /// Pro kullanıcı AI öneri sorgulayabilir mi?
  bool get canAiRecommend => dailyAiRecommendations < proAiRecommendationLimit;

  /// Kalan AI karşılaştırma hakkı.
  int get remainingAiComparisons =>
      (proAiComparisonLimit - dailyAiComparisons).clamp(0, proAiComparisonLimit);

  /// Kalan AI öneri hakkı.
  int get remainingAiRecommendations =>
      (proAiRecommendationLimit - dailyAiRecommendations)
          .clamp(0, proAiRecommendationLimit);

  UsageStatsModel copyWith({
    int? dailyComparisons,
    int? dailyAiComparisons,
    int? dailyAiRecommendations,
    String? lastResetDate,
    int? totalComparisons,
  }) {
    return UsageStatsModel(
      dailyComparisons: dailyComparisons ?? this.dailyComparisons,
      dailyAiComparisons: dailyAiComparisons ?? this.dailyAiComparisons,
      dailyAiRecommendations:
          dailyAiRecommendations ?? this.dailyAiRecommendations,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      totalComparisons: totalComparisons ?? this.totalComparisons,
    );
  }
}
