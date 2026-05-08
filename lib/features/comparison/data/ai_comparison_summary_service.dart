import 'package:cloud_functions/cloud_functions.dart';

import '../domain/models/comparison_result.dart';

class AiComparisonSummaryResult {
  final String summary;
  final bool cached;

  const AiComparisonSummaryResult({
    required this.summary,
    required this.cached,
  });
}

/// Üniversite karşılaştırması için AI özet üretir.
///
/// Özet üretimi ve cache/limit kontrolü Cloud Function tarafında yapılır.
class AiComparisonSummaryService {
  final FirebaseFunctions _functions;

  AiComparisonSummaryService({
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<AiComparisonSummaryResult> summarizeUniversityComparison(
    ComparisonResult result,
  ) async {
    final payload = {
      'comparisonType': 'university',
      'entityA': {
        'id': result.uniA.id,
        'name': result.uniA.name,
      },
      'entityB': {
        'id': result.uniB.id,
        'name': result.uniB.name,
      },
      'comparisonData': {
        'overall': {
          'uniA': {
            'avgRating': result.uniA.avgRating,
            'reviewCount': result.uniA.reviewCount,
            'type': result.uniA.type,
            'establishedYear': result.uniA.establishedYear,
          },
          'uniB': {
            'avgRating': result.uniB.avgRating,
            'reviewCount': result.uniB.reviewCount,
            'type': result.uniB.type,
            'establishedYear': result.uniB.establishedYear,
          },
        },
        'categoryComparisons': {
          for (final entry in result.categoryComparisons.entries)
            entry.key: {
              'valueA': entry.value.valueA,
              'valueB': entry.value.valueB,
            },
        },
      },
    };

    final callable = _functions.httpsCallable(
      'generateComparisonSummary',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 20),
      ),
    );

    final response = await callable.call<Map<String, dynamic>>(payload);
    final data = Map<String, dynamic>.from(response.data);

    return AiComparisonSummaryResult(
      summary: (data['summary'] as String? ?? '').trim(),
      cached: data['cached'] as bool? ?? false,
    );
  }
}
