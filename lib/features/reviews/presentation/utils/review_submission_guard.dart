import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/snackbar_helper.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/review_repository.dart';
import '../../domain/models/review_model.dart';
import '../providers/review_providers.dart';

Future<void> openWriteReviewIfAllowed({
  required BuildContext context,
  required WidgetRef ref,
  required ReviewType type,
  required String targetId,
  required String universityId,
  String? placeSubType,
}) async {
  final targetRoute = _writeReviewRoute(
    type: type,
    targetId: targetId,
    universityId: universityId,
    placeSubType: placeSubType,
  );

  final profile = await ref.read(currentUserProvider.future);
  if (!context.mounted) return;

  if (profile == null) {
    final encodedPath = Uri.encodeComponent(targetRoute);
    context.push('/login?from=$encodedPath');
    return;
  }

  if (!profile.isVerifiedStudent) {
    showAppSnackBar(
      context,
      message: 'Yorum yazmak için edu.tr hesabınızı doğrulamanız gerekiyor.',
      isError: true,
    );
    return;
  }

  // Doğrulanmış her öğrenci her üniversiteye yorum yazabilir; kendi
  // üniversitesi olup olmadığı server tarafında etiketlenir (isOwnUniversity).
  try {
    final status = await ref
        .read(reviewRepositoryProvider)
        .getSubmissionStatus();
    if (!context.mounted) return;

    if (status.allowed) {
      context.push(targetRoute);
      return;
    }

    showAppSnackBar(
      context,
      message:
          'Kısa sürede yorum limitine ulaştınız. ${_retryText(status.retryAfterSeconds)} tekrar deneyin.',
      isError: true,
      duration: const Duration(seconds: 4),
    );
  } on ReviewSubmissionException catch (e) {
    if (!context.mounted) return;
    showAppSnackBar(context, message: e.message, isError: true);
  } catch (_) {
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      message:
          'Yorum hakkı kontrol edilemedi. Lütfen biraz sonra tekrar deneyin.',
      isError: true,
    );
  }
}

String _writeReviewRoute({
  required ReviewType type,
  required String targetId,
  required String universityId,
  String? placeSubType,
}) {
  final query = <String, String>{};
  if (type != ReviewType.university) {
    query['uni'] = universityId;
  }
  if (placeSubType != null && placeSubType.isNotEmpty) {
    query['pt'] = placeSubType;
  }

  final uri = Uri(
    path: '/write-review/${type.name}/$targetId',
    queryParameters: query.isEmpty ? null : query,
  );
  return uri.toString();
}

String _retryText(int seconds) {
  if (seconds <= 0) return 'Biraz sonra';
  if (seconds < 60) return '$seconds saniye sonra';

  final minutes = (seconds / 60).ceil();
  if (minutes < 60) return '$minutes dakika sonra';

  final hours = (minutes / 60).ceil();
  return '$hours saat sonra';
}
