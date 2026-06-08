import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_report_repository.dart';
import '../../data/admin_feedback_repository.dart';
import '../../domain/models/admin_report_model.dart';
import '../../domain/models/admin_feedback_model.dart';
import '../../../reviews/domain/models/review_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

// ═══════════════════════════════════════════════════════════════
//  Repository Providers
// ═══════════════════════════════════════════════════════════════

final adminReportRepositoryProvider = Provider<AdminReportRepository>((ref) {
  return AdminReportRepository();
});

final adminFeedbackRepositoryProvider =
    Provider<AdminFeedbackRepository>((ref) {
  return AdminFeedbackRepository();
});

// ═══════════════════════════════════════════════════════════════
//  Report Stream Providers
// ═══════════════════════════════════════════════════════════════

/// Tüm raporları dinle (real-time)
final allReportsProvider = StreamProvider<List<AdminReportModel>>((ref) {
  ref.keepAlive();
  return ref.watch(adminReportRepositoryProvider).watchAllReports();
});

/// Bekleyen rapor sayısı (badge için)
final pendingReportCountProvider = StreamProvider<int>((ref) {
  ref.keepAlive();
  return ref.watch(adminReportRepositoryProvider).watchPendingReportCount();
});

/// Engellenen (isApproved=false) yorumları dinle
final blockedReviewsProvider = StreamProvider<List<ReviewModel>>((ref) {
  ref.keepAlive();
  return ref.watch(adminReportRepositoryProvider).watchBlockedReviews();
});

/// Belirli bir yoruma ait raporları dinle
final reportsForReviewProvider =
    StreamProvider.family<List<AdminReportModel>, String>((ref, reviewId) {
  return ref
      .watch(adminReportRepositoryProvider)
      .watchReportsForReview(reviewId);
});

// ═══════════════════════════════════════════════════════════════
//  Feedback Stream Providers
// ═══════════════════════════════════════════════════════════════

/// Tüm feedbackleri dinle (real-time)
final allFeedbackProvider = StreamProvider<List<AdminFeedbackModel>>((ref) {
  ref.keepAlive();
  return ref.watch(adminFeedbackRepositoryProvider).watchAllFeedback();
});

/// Yeni feedback sayısı (badge için)
final newFeedbackCountProvider = StreamProvider<int>((ref) {
  ref.keepAlive();
  return ref.watch(adminFeedbackRepositoryProvider).watchNewFeedbackCount();
});

// ═══════════════════════════════════════════════════════════════
//  Report Action Controller
// ═══════════════════════════════════════════════════════════════

class ReportActionController extends StateNotifier<AsyncValue<void>> {
  final AdminReportRepository _repo;
  final String _adminUserId;

  ReportActionController(this._repo, this._adminUserId)
      : super(const AsyncValue.data(null));

  /// Yorumu gizle + rapor durumunu güncelle
  Future<void> hideReview({
    required String reportId,
    required String reviewId,
    required String reviewOwnerId,
    String? adminNote,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. Yorumu gizle
      await _repo.hideReportedReview(reviewId);
      // 2. Rapor durumunu güncelle
      await _repo.updateReportStatus(
        reportId,
        status: ReportStatus.actioned,
        adminNote: adminNote,
        adminUserId: _adminUserId,
      );
      // 3. Yorum sahibine bildirim gönder
      await _repo.sendReportActionNotification(
        reviewOwnerId: reviewOwnerId,
        action: 'hidden',
        adminNote: adminNote,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Yorumu kalıcı sil + rapor durumunu güncelle
  Future<void> deleteReview({
    required String reportId,
    required String reviewId,
    required String reviewOwnerId,
    required List<String> photoUrls,
    String? adminNote,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. Yorumu sil
      await _repo.deleteReportedReview(reviewId, reviewOwnerId, photoUrls);
      // 2. Rapor durumunu güncelle
      await _repo.updateReportStatus(
        reportId,
        status: ReportStatus.actioned,
        adminNote: adminNote,
        adminUserId: _adminUserId,
      );
      // 3. Yorum sahibine bildirim gönder
      await _repo.sendReportActionNotification(
        reviewOwnerId: reviewOwnerId,
        action: 'deleted',
        adminNote: adminNote,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Şikayeti reddet (yorum korunur)
  Future<void> dismissReport({
    required String reportId,
    String? adminNote,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateReportStatus(
        reportId,
        status: ReportStatus.dismissed,
        adminNote: adminNote,
        adminUserId: _adminUserId,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Gizlenen yorumu geri aç
  Future<void> unhideReview(String reviewId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.unhideReview(reviewId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Engellenen yorumu kalıcı sil
  Future<void> permanentlyDeleteReview({
    required String reviewId,
    required String userId,
    required List<String> photoUrls,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteReportedReview(reviewId, userId, photoUrls);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final reportActionControllerProvider =
    StateNotifierProvider<ReportActionController, AsyncValue<void>>((ref) {
  final repo = ref.read(adminReportRepositoryProvider);
  final user = ref.watch(authStateProvider).value;
  final adminUserId = user?.uid ?? '';
  return ReportActionController(repo, adminUserId);
});

// ═══════════════════════════════════════════════════════════════
//  Feedback Action Controller
// ═══════════════════════════════════════════════════════════════

class FeedbackActionController extends StateNotifier<AsyncValue<void>> {
  final AdminFeedbackRepository _repo;
  final String _adminUserId;

  FeedbackActionController(this._repo, this._adminUserId)
      : super(const AsyncValue.data(null));

  /// Feedback statüsünü güncelle
  Future<void> updateStatus({
    required String feedbackId,
    required FeedbackStatus status,
    String? adminNote,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateFeedbackStatus(
        feedbackId,
        status: status,
        adminNote: adminNote,
        adminUserId: _adminUserId,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Feedback sil
  Future<void> deleteFeedback(String feedbackId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteFeedback(feedbackId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final feedbackActionControllerProvider =
    StateNotifierProvider<FeedbackActionController, AsyncValue<void>>((ref) {
  final repo = ref.read(adminFeedbackRepositoryProvider);
  final user = ref.watch(authStateProvider).value;
  final adminUserId = user?.uid ?? '';
  return FeedbackActionController(repo, adminUserId);
});
