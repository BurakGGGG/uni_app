import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/admin_report_model.dart';
import '../../domain/models/admin_feedback_model.dart';
import '../../../reviews/domain/models/review_model.dart';

/// Raporlar ekranı üstünde gösterilecek istatistik özet kartı.
class ReportsSummaryCard extends StatelessWidget {
  final List<AdminReportModel> reports;
  final List<AdminFeedbackModel> feedbacks;
  final List<ReviewModel> blockedReviews;

  const ReportsSummaryCard({
    super.key,
    required this.reports,
    required this.feedbacks,
    required this.blockedReviews,
  });

  @override
  Widget build(BuildContext context) {
    final pending = reports
        .where((r) => r.status == ReportStatus.pending)
        .length;
    final actioned = reports
        .where((r) => r.status == ReportStatus.actioned)
        .length;
    final newFb = feedbacks
        .where((f) => f.status == FeedbackStatus.newFeedback)
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final badgeWidth = constraints.maxWidth < 360
              ? (constraints.maxWidth - 12) / 2
              : 64.0;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: badgeWidth,
                child: _StatBadge(
                  label: 'Şikayet',
                  count: reports.length,
                  color: AppColors.error,
                ),
              ),
              SizedBox(
                width: badgeWidth,
                child: _StatBadge(
                  label: 'Bekleyen',
                  count: pending,
                  color: AppColors.warning,
                ),
              ),
              SizedBox(
                width: badgeWidth,
                child: _StatBadge(
                  label: 'Çözülen',
                  count: actioned,
                  color: AppColors.success,
                ),
              ),
              SizedBox(
                width: badgeWidth,
                child: _StatBadge(
                  label: 'Feedback',
                  count: feedbacks.length,
                  color: AppColors.info,
                ),
              ),
              _CompactMetric(
                icon: Icons.block_rounded,
                value: blockedReviews.length,
              ),
              _CompactMetric(icon: Icons.fiber_new_rounded, value: newFb),
            ],
          );
        },
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _CompactMetric extends StatelessWidget {
  final IconData icon;
  final int value;

  const _CompactMetric({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiaryFor(context)),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
