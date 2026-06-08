import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/admin_report_model.dart';

/// Rapor satır widget'ı — Şikayetler ve İncelenenler tablarında kullanılır.
class ReportTile extends StatelessWidget {
  final AdminReportModel report;
  final VoidCallback onTap;

  const ReportTile({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLightFor(context)),
          ),
          child: Row(
            children: [
              // ─── Neden İkonu ─────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _reasonColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_reasonIcon, color: _reasonColor, size: 22),
              ),
              const SizedBox(width: 12),

              // ─── İçerik ──────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.reason.label,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusBadge(status: report.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (report.explanation != null &&
                        report.explanation!.isNotEmpty)
                      Text(
                        report.explanation!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryFor(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.textTertiaryFor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(report.createdAt, locale: 'tr'),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textTertiaryFor(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.article_outlined,
                          size: 12,
                          color: AppColors.textTertiaryFor(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Yorum: ${report.reviewId.length > 8 ? '${report.reviewId.substring(0, 8)}...' : report.reviewId}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiaryFor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textTertiaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _reasonColor {
    switch (report.reason) {
      case AdminReportReason.inappropriate:
        return AppColors.error;
      case AdminReportReason.spam:
        return AppColors.warning;
      case AdminReportReason.offensive:
        return const Color(0xFFDC2626);
      case AdminReportReason.misleading:
        return AppColors.info;
      case AdminReportReason.other:
        return const Color(0xFF6B7280);
    }
  }

  IconData get _reasonIcon {
    switch (report.reason) {
      case AdminReportReason.inappropriate:
        return Icons.block_rounded;
      case AdminReportReason.spam:
        return Icons.report_rounded;
      case AdminReportReason.offensive:
        return Icons.warning_amber_rounded;
      case AdminReportReason.misleading:
        return Icons.info_outline_rounded;
      case AdminReportReason.other:
        return Icons.flag_rounded;
    }
  }
}

/// Rapor durumu rozeti
class _StatusBadge extends StatelessWidget {
  final ReportStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.labelSmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _statusColor,
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (status) {
      case ReportStatus.pending:
        return AppColors.warning;
      case ReportStatus.reviewed:
        return AppColors.success;
      case ReportStatus.dismissed:
        return const Color(0xFF6B7280);
      case ReportStatus.actioned:
        return AppColors.error;
    }
  }
}
