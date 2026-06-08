import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/admin_feedback_model.dart';

/// Feedback satır widget'ı — Feedbackler tabında kullanılır.
class FeedbackTile extends StatelessWidget {
  final AdminFeedbackModel feedback;
  final VoidCallback onTap;

  const FeedbackTile({
    super.key,
    required this.feedback,
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
              // ─── Tür İkonu ───────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon, color: _typeColor, size: 22),
              ),
              const SizedBox(width: 12),

              // ─── İçerik ──────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            feedback.type.label,
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _typeColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _FeedbackStatusBadge(status: feedback.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      feedback.message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimaryFor(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 12,
                          color: AppColors.textTertiaryFor(context),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            feedback.userEmail ?? 'Anonim',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiaryFor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.textTertiaryFor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(feedback.createdAt, locale: 'tr'),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textTertiaryFor(context),
                          ),
                        ),
                        if (feedback.platform != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.phone_android_rounded,
                            size: 12,
                            color: AppColors.textTertiaryFor(context),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            feedback.platform!,
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 10,
                              color: AppColors.textTertiaryFor(context),
                            ),
                          ),
                        ],
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

  Color get _typeColor {
    switch (feedback.type) {
      case FeedbackType.bug:
        return AppColors.error;
      case FeedbackType.suggestion:
        return AppColors.warning;
      case FeedbackType.other:
        return AppColors.info;
    }
  }

  IconData get _typeIcon {
    switch (feedback.type) {
      case FeedbackType.bug:
        return Icons.bug_report_rounded;
      case FeedbackType.suggestion:
        return Icons.lightbulb_rounded;
      case FeedbackType.other:
        return Icons.chat_bubble_outline_rounded;
    }
  }
}

/// Feedback durumu rozeti
class _FeedbackStatusBadge extends StatelessWidget {
  final FeedbackStatus status;

  const _FeedbackStatusBadge({required this.status});

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
      case FeedbackStatus.newFeedback:
        return AppColors.info;
      case FeedbackStatus.inProgress:
        return AppColors.warning;
      case FeedbackStatus.resolved:
        return AppColors.success;
    }
  }
}
