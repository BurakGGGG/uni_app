import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_report_repository.dart';
import '../../data/admin_feedback_repository.dart';
import '../../domain/models/admin_report_model.dart';
import '../../domain/models/admin_feedback_model.dart';
import '../../../reviews/domain/models/review_model.dart';

// ═══════════════════════════════════════════════════════════════
//  Repository Providers
// ═══════════════════════════════════════════════════════════════

final adminReportRepositoryProvider = Provider<AdminReportRepository>((ref) {
  return AdminReportRepository();
});

final adminFeedbackRepositoryProvider = Provider<AdminFeedbackRepository>((
  ref,
) {
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

  ReportActionController(this._repo) : super(const AsyncValue.data(null));

  /// Yorumu gizle + rapor durumunu güncelle
  Future<void> hideReview({
    required String reportId,
    required String reviewId,
    String? adminNote,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.hideReportedReview(
        reviewId,
        reportId: reportId,
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
    String? adminNote,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteReportedReview(
        reviewId,
        reportId: reportId,
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
  Future<void> permanentlyDeleteReview({required String reviewId}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteReportedReview(reviewId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final reportActionControllerProvider =
    StateNotifierProvider<ReportActionController, AsyncValue<void>>((ref) {
      final repo = ref.read(adminReportRepositoryProvider);
      return ReportActionController(repo);
    });

// ═══════════════════════════════════════════════════════════════
//  Feedback Action Controller
// ═══════════════════════════════════════════════════════════════

class FeedbackActionController extends StateNotifier<AsyncValue<void>> {
  final AdminFeedbackRepository _repo;

  FeedbackActionController(this._repo) : super(const AsyncValue.data(null));

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
      return FeedbackActionController(repo);
    });
