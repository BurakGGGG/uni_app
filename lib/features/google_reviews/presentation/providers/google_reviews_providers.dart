import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/google_reviews_service.dart';
import '../../domain/models/google_reviews_result.dart';

final googleReviewsServiceProvider = Provider<GoogleReviewsService>((ref) {
  return GoogleReviewsService();
});

/// Kota dolduğunda (resource-exhausted) true olur; bölüm oturumun geri
/// kalanında hiç render edilmez — yeni CF çağrısı da yapılmaz.
final googleReviewsDisabledProvider = StateProvider<bool>((ref) => false);

/// Üniversite başına oturum içi bellek önbelleği: aynı üniversite için
/// oturum boyunca en fazla 1 CF çağrısı yapılır (keepAlive, süresiz).
/// Places politikası gereği kalıcı önbellek YOK — uygulama kapanınca uçar.
final googleReviewsProvider = FutureProvider.autoDispose
    .family<GoogleReviewsResult, String>((ref, universityId) async {
      final link = ref.keepAlive();

      try {
        return await ref
            .read(googleReviewsServiceProvider)
            .fetch(universityId);
      } on GoogleReviewsQuotaExhausted {
        ref.read(googleReviewsDisabledProvider.notifier).state = true;
        link.close(); // hatayı cache'leme
        rethrow;
      } on GoogleReviewsFailure {
        link.close();
        rethrow;
      }
    });
