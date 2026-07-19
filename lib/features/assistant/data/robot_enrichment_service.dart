import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../../services/rate_limiter.dart';
import '../domain/robot_enrichment.dart';

/// `enrichRecommendations` callable istemcisi (us-central1, App Check'li).
/// Sözleşme: functions/src/recommendations/enrich.ts — sunucu Pro aboneliği,
/// günlük 10 hakkı ve dakikalık pencereyi denetler; aynı girdi 24 saat
/// cache'ten döner ve hak düşmez.
///
/// Balon UI'ı hata görmemeli: her başarısızlık null'a düşer, kaynak kural
/// metnini gösterir. Bu yüzden buradan asla exception sızmaz.
class RobotEnrichmentService implements RobotEnrichmentClient {
  final FirebaseFunctions _functions;

  RobotEnrichmentService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  @override
  Future<RobotEnrichment?> enrich({
    required Map<String, String> userTags,
    required List<RobotEnrichCandidate> candidates,
  }) async {
    if (candidates.isEmpty) return null;
    if (!AppRateLimiters.aiRecommendation.tryAcquire()) {
      debugPrint('[RobotEnrich] Client-side rate limited');
      return null;
    }

    try {
      final callable = _functions.httpsCallable(
        'enrichRecommendations',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 25), // Function 30s > Groq 12s
        ),
      );
      final response = await callable.call<Object?>({
        'userTags': userTags,
        'recommendations': [
          for (final c in candidates)
            {
              'departmentId': c.departmentId,
              'departmentName': c.departmentName,
              'universityId': c.universityId,
              'universityName': c.universityName,
              'totalScore': c.totalScore,
              'reasons': c.reasons,
            },
        ],
      });
      return _parse(response.data);
    } on FirebaseFunctionsException catch (e) {
      // Limit/abonelik/ağ hataları operasyonel — sessiz geri düşüş yeter.
      debugPrint('[RobotEnrich] ${e.code}: ${e.message}');
      return null;
    } catch (e, st) {
      debugPrint('[RobotEnrich] Unknown error: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'robot_enrichRecommendations_unknown_error',
        fatal: false,
      );
      return null;
    }
  }

  RobotEnrichment? _parse(Object? raw) {
    if (raw is! Map) return null;
    final summary = (raw['summary'] as String? ?? '').trim();
    if (summary.isEmpty) return null;

    final notes = <String, String>{};
    final items = raw['items'];
    if (items is List) {
      for (final item in items) {
        if (item is! Map) continue;
        final uniId = item['universityId'];
        final deptId = item['departmentId'];
        final reasoning = item['reasoning'];
        if (uniId is String &&
            deptId is String &&
            reasoning is String &&
            reasoning.trim().isNotEmpty) {
          notes['${uniId}_$deptId'] = reasoning.trim();
        }
      }
    }
    return RobotEnrichment(summary: summary, notes: notes);
  }
}
