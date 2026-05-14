import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../domain/models/comparison_result.dart';

/// AI özet servisinin döndürebileceği hata türleri
sealed class AiSummaryFailure implements Exception {
  final String userMessage;
  const AiSummaryFailure(this.userMessage);
}

class AiSummaryQuotaExceeded extends AiSummaryFailure {
  const AiSummaryQuotaExceeded()
      : super('Günlük AI özet hakkın doldu. Yarın tekrar dene.');
}

class AiSummaryUnauthenticated extends AiSummaryFailure {
  const AiSummaryUnauthenticated()
      : super('AI özet için giriş yapman gerekiyor.');
}

class AiSummaryUnavailable extends AiSummaryFailure {
  const AiSummaryUnavailable()
      : super('AI servisi geçici olarak yanıt vermiyor. Birkaç saniye sonra tekrar dene.');
}

class AiSummaryNetworkError extends AiSummaryFailure {
  const AiSummaryNetworkError()
      : super('İnternet bağlantını kontrol et ve tekrar dene.');
}

class AiSummaryUnknownError extends AiSummaryFailure {
  const AiSummaryUnknownError()
      : super('Beklenmeyen bir hata oluştu. Lütfen tekrar dene.');
}

/// Bu karşılaştırma çifti için kullanıcı zaten 1 regenerate hakkını kullanmış.
/// Cloud Function `already-exists` koduyla döner.
class AiSummaryRegenerateAlreadyUsed extends AiSummaryFailure {
  const AiSummaryRegenerateAlreadyUsed()
      : super('Bu karşılaştırma için yeniden üretme hakkını zaten kullandın.');
}

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
  final FirebaseCrashlytics? _crashlytics;

  AiComparisonSummaryService({
    FirebaseFunctions? functions,
    FirebaseCrashlytics? crashlytics,
  })  : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'europe-west1'),
        _crashlytics = crashlytics;

  Future<AiComparisonSummaryResult> summarizeUniversityComparison(
    ComparisonResult result, {
    bool regenerate = false,
  }) async {
    final payload = {
      ..._buildPayload(result),
      if (regenerate) 'regenerate': true,
    };

    final callable = _functions.httpsCallable(
      'generateComparisonSummary',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 25), // Function 20s > Groq 15s
      ),
    );

    try {
      final response = await callable.call<Object?>(payload);
      final raw = response.data;
      if (raw is! Map) {
        throw const AiSummaryUnknownError();
      }
      final data = Map<String, dynamic>.from(raw);
      final summary = (data['summary'] as String? ?? '').trim();
      if (summary.isEmpty) {
        throw const AiSummaryUnavailable();
      }
      return AiComparisonSummaryResult(
        summary: summary,
        cached: data['cached'] as bool? ?? false,
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('[AiSummary] FirebaseFunctionsException: ${e.code} - ${e.message}');
      _crashlytics?.recordError(
        e,
        st,
        reason: 'AI summary call failed',
        information: ['code: ${e.code}', 'message: ${e.message}'],
      );
      throw _mapFirebaseError(e);
    } on AiSummaryFailure {
      rethrow;
    } catch (e, st) {
      debugPrint('[AiSummary] Unknown error: $e');
      _crashlytics?.recordError(e, st, reason: 'AI summary unknown error');
      throw const AiSummaryUnknownError();
    }
  }

  AiSummaryFailure _mapFirebaseError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'resource-exhausted':
        return const AiSummaryQuotaExceeded();
      case 'unauthenticated':
        return const AiSummaryUnauthenticated();
      case 'already-exists':
        return const AiSummaryRegenerateAlreadyUsed();
      case 'unavailable':
      case 'deadline-exceeded':
        return const AiSummaryUnavailable();
      case 'network-request-failed':
      case 'cancelled':
        return const AiSummaryNetworkError();
      default:
        return const AiSummaryUnknownError();
    }
  }

  Map<String, dynamic> _buildPayload(ComparisonResult result) {
    return {
      'comparisonType': 'university',
      'entityA': {'id': result.uniA.id, 'name': result.uniA.name},
      'entityB': {'id': result.uniB.id, 'name': result.uniB.name},
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
  }
}
