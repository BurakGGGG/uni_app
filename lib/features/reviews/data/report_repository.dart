import 'package:cloud_functions/cloud_functions.dart';
import '../../admin/data/analytics_service.dart';
import '../../admin/domain/models/analytics_event.dart';

/// Şikayet nedenleri
enum ReportReason { inappropriate, spam, offensive, misleading, other }

extension ReportReasonExt on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.inappropriate:
        return 'Uygunsuz içerik';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.offensive:
        return 'Hakaret / ayrımcılık';
      case ReportReason.misleading:
        return 'Yanıltıcı bilgi';
      case ReportReason.other:
        return 'Diğer';
    }
  }
}

/// Şikayet (Report) veritabanı işlemleri
class ReportRepository {
  final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// Bir yorumu şikayet et
  Future<void> reportReview({
    required String reviewId,
    required ReportReason reason,
    String? explanation,
  }) async {
    try {
      await _functions
          .httpsCallable(
            'submitReviewReport',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
          )
          .call(<String, dynamic>{
            'reviewId': reviewId,
            'reason': reason.name,
            if (explanation != null && explanation.trim().isNotEmpty)
              'explanation': explanation.trim(),
          });
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'already-exists':
          throw const DuplicateReportException();
        case 'resource-exhausted':
          throw const ReportRateLimitedException();
        case 'failed-precondition':
        case 'not-found':
          throw ReportSubmissionException(
            e.message ?? 'Şikayet gönderilemedi.',
          );
        default:
          throw const ReportSubmissionException(
            'Şikayet gönderilirken bir hata oluştu.',
          );
      }
    }

    // Analytics: rapor gönderildi
    AnalyticsService.instance.trackEvent(AnalyticsEvent.reportCreated);
  }
}

class DuplicateReportException implements Exception {
  const DuplicateReportException();
}

class ReportRateLimitedException implements Exception {
  const ReportRateLimitedException();
}

class ReportSubmissionException implements Exception {
  final String message;

  const ReportSubmissionException(this.message);

  @override
  String toString() => message;
}
