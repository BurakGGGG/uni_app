import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/admin_report_model.dart';
import '../../domain/models/admin_feedback_model.dart';
import '../../../reviews/domain/models/review_model.dart';
import '../providers/admin_reports_providers.dart';
import '../widgets/report_tile.dart';
import '../widgets/feedback_tile.dart';
import '../widgets/blocked_review_tile.dart';
import '../widgets/report_detail_sheet.dart';
import '../widgets/feedback_detail_sheet.dart';
import '../widgets/reports_summary_card.dart';

/// Admin Raporlar Ekranı — 5 tablı yapı.
///
/// Tab 1: Şikayetler (pending)
/// Tab 2: İncelenenler (reviewed/dismissed/actioned)
/// Tab 3: Feedbackler
/// Tab 4: Engellenen Yorumlar
/// Tab 5: Özet
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allReportsAsync = ref.watch(allReportsProvider);
    final allFeedbackAsync = ref.watch(allFeedbackProvider);
    final blockedAsync = ref.watch(blockedReviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        title: Text(
          'Raporlar',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: AppColors.surfaceFor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryFor(context),
          labelStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
          tabAlignment: TabAlignment.start,
          tabs: [
            _buildTab('Şikayetler', allReportsAsync, isPending: true),
            const Tab(text: 'İncelenenler'),
            _buildFeedbackTab('Feedbackler', allFeedbackAsync),
            const Tab(text: 'Engellenenler'),
            const Tab(text: 'Özet'),
          ],
        ),
      ),
      body: allReportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(e),
        data: (allReports) {
          final pending = allReports
              .where((r) => r.status == ReportStatus.pending)
              .toList();
          final reviewed = allReports
              .where((r) => r.status != ReportStatus.pending)
              .toList();

          return allFeedbackAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildError(e),
            data: (allFeedback) {
              return blockedAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _buildError(e),
                data: (blocked) {
                  return Column(
                    children: [
                      // Özet kartı
                      ReportsSummaryCard(
                        reports: allReports,
                        feedbacks: allFeedback,
                        blockedReviews: blocked,
                      ),
                      // Tab içerikleri
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _ReportsTab(
                              reports: pending,
                              emptyTitle: 'Bekleyen şikayet yok',
                              emptySubtitle: 'Tüm şikayetler incelenmiş.',
                              emptyIcon: Icons.check_circle_outline_rounded,
                            ),
                            _ReportsTab(
                              reports: reviewed,
                              emptyTitle: 'İncelenmiş rapor yok',
                              emptySubtitle:
                                  'Henüz incelenen şikayet bulunmuyor.',
                              emptyIcon: Icons.inbox_rounded,
                            ),
                            _FeedbackTab(feedbacks: allFeedback),
                            _BlockedTab(reviews: blocked, ref: ref),
                            _SummaryTab(
                              reports: allReports,
                              feedbacks: allFeedback,
                              blocked: blocked,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTab(
    String label,
    AsyncValue<List<AdminReportModel>> async, {
    bool isPending = false,
  }) {
    return async.when(
      data: (reports) {
        final count = isPending
            ? reports.where((r) => r.status == ReportStatus.pending).length
            : reports.where((r) => r.status != ReportStatus.pending).length;
        if (count > 0) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPending ? AppColors.error : AppColors.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Tab(text: label);
      },
      loading: () => Tab(text: label),
      error: (_, _) => Tab(text: label),
    );
  }

  Widget _buildFeedbackTab(
    String label,
    AsyncValue<List<AdminFeedbackModel>> async,
  ) {
    return async.when(
      data: (feedbacks) {
        final newCount = feedbacks
            .where((f) => f.status == FeedbackStatus.newFeedback)
            .length;
        if (newCount > 0) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$newCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Tab(text: label);
      },
      loading: () => Tab(text: label),
      error: (_, _) => Tab(text: label),
    );
  }

  Widget _buildError(Object e) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            'Veri yüklenirken hata oluştu.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ref.invalidate(allReportsProvider);
              ref.invalidate(allFeedbackProvider);
              ref.invalidate(blockedReviewsProvider);
            },
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Tab 1 & 2: Şikayetler / İncelenenler
// ═══════════════════════════════════════════════════════════════

class _ReportsTab extends StatelessWidget {
  final List<AdminReportModel> reports;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;

  const _ReportsTab({
    required this.reports,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return _EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final report = reports[index];
        return ReportTile(
          report: report,
          onTap: () => ReportDetailSheet.show(context, report),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Tab 3: Feedbackler
// ═══════════════════════════════════════════════════════════════

class _FeedbackTab extends StatelessWidget {
  final List<AdminFeedbackModel> feedbacks;
  const _FeedbackTab({required this.feedbacks});

  @override
  Widget build(BuildContext context) {
    if (feedbacks.isEmpty) {
      return const _EmptyState(
        icon: Icons.feedback_outlined,
        title: 'Henüz feedback yok',
        subtitle: 'Kullanıcılardan geri bildirim bekleniyor.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: feedbacks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final feedback = feedbacks[index];
        return FeedbackTile(
          feedback: feedback,
          onTap: () => FeedbackDetailSheet.show(context, feedback),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Tab 4: Engellenen Yorumlar
// ═══════════════════════════════════════════════════════════════

class _BlockedTab extends StatelessWidget {
  final List<ReviewModel> reviews;
  final WidgetRef ref;
  const _BlockedTab({required this.reviews, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const _EmptyState(
        icon: Icons.block_rounded,
        title: 'Engellenen yorum yok',
        subtitle: 'Gizlenen yorumlar burada görünür.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: reviews.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final review = reviews[index];
        return BlockedReviewTile(
          review: review,
          onUnhide: () => _confirmUnhide(context, review),
          onDelete: () => _confirmDelete(context, review),
        );
      },
    );
  }

  void _confirmUnhide(BuildContext context, ReviewModel review) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Yorumu Geri Aç'),
        content: const Text('Bu yorum tekrar görünür olacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Geri Aç'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(reportActionControllerProvider.notifier)
        .unhideReview(review.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yorum geri açıldı'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, ReviewModel review) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Kalıcı Sil'),
        content: const Text('Bu işlem geri alınamaz!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(reportActionControllerProvider.notifier)
        .permanentlyDeleteReview(
          reviewId: review.id,
          photoUrls: review.imageUrls,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yorum kalıcı olarak silindi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  Tab 5: Özet
// ═══════════════════════════════════════════════════════════════

class _SummaryTab extends StatelessWidget {
  final List<AdminReportModel> reports;
  final List<AdminFeedbackModel> feedbacks;
  final List<ReviewModel> blocked;

  const _SummaryTab({
    required this.reports,
    required this.feedbacks,
    required this.blocked,
  });

  @override
  Widget build(BuildContext context) {
    // Şikayet nedeni dağılımı
    final reasonCounts = <AdminReportReason, int>{};
    for (final r in reports) {
      reasonCounts[r.reason] = (reasonCounts[r.reason] ?? 0) + 1;
    }
    final sortedReasons = reasonCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Feedback tür dağılımı
    final fbTypeCounts = <FeedbackType, int>{};
    for (final f in feedbacks) {
      fbTypeCounts[f.type] = (fbTypeCounts[f.type] ?? 0) + 1;
    }

    // En çok şikayet alan yorumlar
    final reviewReportCounts = <String, int>{};
    for (final r in reports) {
      reviewReportCounts[r.reviewId] =
          (reviewReportCounts[r.reviewId] ?? 0) + 1;
    }
    final topReported = reviewReportCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genel sayılar
          _SectionTitle(title: 'Genel Durum'),
          const SizedBox(height: 8),
          _SummaryGrid(
            items: [
              _SummaryItem('Toplam Şikayet', reports.length, AppColors.error),
              _SummaryItem(
                'Bekleyen',
                reports.where((r) => r.status == ReportStatus.pending).length,
                AppColors.warning,
              ),
              _SummaryItem(
                'Aksiyon Alınan',
                reports.where((r) => r.status == ReportStatus.actioned).length,
                AppColors.success,
              ),
              _SummaryItem(
                'Reddedilen',
                reports.where((r) => r.status == ReportStatus.dismissed).length,
                const Color(0xFF6B7280),
              ),
              _SummaryItem('Toplam Feedback', feedbacks.length, AppColors.info),
              _SummaryItem(
                'Engellenen Yorum',
                blocked.length,
                const Color(0xFFDC2626),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Şikayet nedeni dağılımı
          _SectionTitle(title: 'Şikayet Nedeni Dağılımı'),
          const SizedBox(height: 8),
          if (sortedReasons.isEmpty)
            Text(
              'Henüz veri yok.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiaryFor(context),
              ),
            )
          else
            ...sortedReasons.map(
              (e) => _DistributionBar(
                label: e.key.label,
                count: e.value,
                total: reports.length,
                color: _reasonColor(e.key),
              ),
            ),
          const SizedBox(height: 20),

          // Feedback tür dağılımı
          _SectionTitle(title: 'Feedback Türü Dağılımı'),
          const SizedBox(height: 8),
          if (fbTypeCounts.isEmpty)
            Text(
              'Henüz veri yok.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiaryFor(context),
              ),
            )
          else
            ...fbTypeCounts.entries.map(
              (e) => _DistributionBar(
                label: e.key.label,
                count: e.value,
                total: feedbacks.length,
                color: _fbTypeColor(e.key),
              ),
            ),
          const SizedBox(height: 20),

          // En çok şikayet alan yorumlar (top 5)
          _SectionTitle(title: 'En Çok Şikayet Alan Yorumlar'),
          const SizedBox(height: 8),
          if (topReported.isEmpty)
            Text(
              'Henüz veri yok.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiaryFor(context),
              ),
            )
          else
            ...topReported
                .take(5)
                .toList()
                .asMap()
                .entries
                .map(
                  (e) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceFor(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.borderLightFor(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${e.key + 1}',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.value.key.length > 16
                                ? '${e.value.key.substring(0, 16)}...'
                                : e.value.key,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${e.value.value} şikayet',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Color _reasonColor(AdminReportReason reason) => switch (reason) {
    AdminReportReason.inappropriate => AppColors.error,
    AdminReportReason.spam => AppColors.warning,
    AdminReportReason.offensive => const Color(0xFFDC2626),
    AdminReportReason.misleading => AppColors.info,
    AdminReportReason.other => const Color(0xFF6B7280),
  };
  Color _fbTypeColor(FeedbackType type) => switch (type) {
    FeedbackType.bug => AppColors.error,
    FeedbackType.suggestion => AppColors.warning,
    FeedbackType.other => AppColors.info,
  };
}

// ═══════════════════════════════════════════════════════════════
//  Yardımcı Widget'lar
// ═══════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.textTertiaryFor(context)),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiaryFor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.titleSmall.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondaryFor(context),
      ),
    );
  }
}

class _SummaryItem {
  final String label;
  final int count;
  final Color color;
  _SummaryItem(this.label, this.count, this.color);
}

class _SummaryGrid extends StatelessWidget {
  final List<_SummaryItem> items;
  const _SummaryGrid({required this.items});
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              width: (MediaQuery.of(context).size.width - 48) / 3,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: item.color.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    '${item.count}',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: item.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondaryFor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _DistributionBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '$count (${(pct * 100).toStringAsFixed(0)}%)',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiaryFor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
