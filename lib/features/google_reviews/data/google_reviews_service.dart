import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../domain/models/google_reviews_result.dart';

/// Google yorumları servisinin döndürebileceği hata türleri.
sealed class GoogleReviewsFailure implements Exception {
  const GoogleReviewsFailure();
}

/// Aylık ücretsiz kota doldu — bölüm oturum boyunca gizlenir.
class GoogleReviewsQuotaExhausted extends GoogleReviewsFailure {
  const GoogleReviewsQuotaExhausted();
}

/// Bu üniversite için place_id yok.
class GoogleReviewsNotAvailable extends GoogleReviewsFailure {
  const GoogleReviewsNotAvailable();
}

/// Geçici upstream/ağ hatası.
class GoogleReviewsUnavailable extends GoogleReviewsFailure {
  const GoogleReviewsUnavailable();
}

/// Bir üniversitenin Google puanı ve yorumlarını CANLI çeker.
///
/// Kota, App Check ve Places çağrısı Cloud Function tarafındadır
/// (getGoogleReviews). Yanıt istemcide kalıcı olarak saklanmaz.
class GoogleReviewsService {
  final FirebaseFunctions _functions;

  GoogleReviewsService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<GoogleReviewsResult> fetch(String universityId) async {
    final callable = _functions.httpsCallable(
      'getGoogleReviews',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 20), // Function 15s > Places 10s
      ),
    );

    try {
      final response = await callable.call<Object?>({
        'universityId': universityId,
      });
      final raw = response.data;
      if (raw is! Map) {
        throw const GoogleReviewsUnavailable();
      }
      return GoogleReviewsResult.fromMap(Map<String, dynamic>.from(raw));
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[GoogleReviews] ${e.code} - ${e.message}');
      switch (e.code) {
        case 'resource-exhausted':
          throw const GoogleReviewsQuotaExhausted();
        case 'not-found':
          throw const GoogleReviewsNotAvailable();
        default:
          throw const GoogleReviewsUnavailable();
      }
    } on GoogleReviewsFailure {
      rethrow;
    } catch (e) {
      debugPrint('[GoogleReviews] Unknown error: $e');
      throw const GoogleReviewsUnavailable();
    }
  }
}
