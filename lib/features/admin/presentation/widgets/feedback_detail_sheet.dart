import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/admin_feedback_model.dart';
import '../providers/admin_reports_providers.dart';

/// Feedback detay bottom sheet — bir feedback seçildiğinde açılır.
class FeedbackDetailSheet extends ConsumerStatefulWidget {
  final AdminFeedbackModel feedback;
  const FeedbackDetailSheet({super.key, required this.feedback});

  static Future<void> show(BuildContext context, AdminFeedbackModel feedback) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FeedbackDetailSheet(feedback: feedback),
    );
  }

  @override
  ConsumerState<FeedbackDetailSheet> createState() =>
      _FeedbackDetailSheetState();
}

class _FeedbackDetailSheetState extends ConsumerState<FeedbackDetailSheet> {
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.feedback.adminNote != null) {
      _noteCtrl.text = widget.feedback.adminNote!;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiaryFor(
                  context,
                ).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.feedback_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Feedback Detayı',
                          style: AppTextStyles.titleLarge,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundFor(context),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textSecondaryFor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tür + Statü
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_typeIcon, size: 16, color: _typeColor),
                            const SizedBox(width: 6),
                            Text(
                              widget.feedback.type.label,
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _typeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.feedback.status.label,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mesaj
                  Text(
                    'Mesaj',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundFor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.borderLightFor(context),
                      ),
                    ),
                    child: Text(
                      widget.feedback.message,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Kullanıcı bilgileri
                  Text(
                    'Gönderen',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundFor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.borderLightFor(context),
                      ),
                    ),
                    child: Column(
                      children: [
                        _detailRow(
                          Icons.email_outlined,
                          'Email',
                          widget.feedback.userEmail ?? 'Belirtilmemiş',
                        ),
                        _detailRow(
                          Icons.phone_android_rounded,
                          'Platform',
                          widget.feedback.platform ?? '-',
                        ),
                        _detailRow(
                          Icons.info_outline_rounded,
                          'Versiyon',
                          widget.feedback.appVersion ?? '-',
                        ),
                        _detailRow(
                          Icons.access_time_rounded,
                          'Tarih',
                          timeago.format(
                            widget.feedback.createdAt,
                            locale: 'tr',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Admin notu
                  Text(
                    'Admin Notu',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'İsteğe bağlı admin notu...',
                      hintStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiaryFor(context),
                      ),
                      filled: true,
                      fillColor: AppColors.backgroundFor(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: AppColors.borderLightFor(context),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: AppColors.borderLightFor(context),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusMd,
                        ),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Aksiyonlar
                  Text(
                    'Durumu Güncelle',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stackButtons = constraints.maxWidth < 340;
                      final buttons = [
                        _statusBtn(
                          'İnceleniyor',
                          AppColors.warning,
                          FeedbackStatus.inProgress,
                        ),
                        _statusBtn(
                          'Çözüldü',
                          AppColors.success,
                          FeedbackStatus.resolved,
                        ),
                      ];

                      if (stackButtons) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            buttons[0],
                            const SizedBox(height: 8),
                            buttons[1],
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: buttons[0]),
                          const SizedBox(width: 8),
                          Expanded(child: buttons[1]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _doDelete(context),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Feedback\'i Sil'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiaryFor(context)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiaryFor(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBtn(String label, Color color, FeedbackStatus status) {
    final isActive = widget.feedback.status == status;
    return FilledButton(
      onPressed: isActive ? null : () => _doUpdateStatus(status),
      style: FilledButton.styleFrom(
        backgroundColor: isActive ? color.withValues(alpha: 0.3) : color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String? get _note =>
      _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null;

  Future<void> _doUpdateStatus(FeedbackStatus status) async {
    await ref
        .read(feedbackActionControllerProvider.notifier)
        .updateStatus(
          feedbackId: widget.feedback.id,
          status: status,
          adminNote: _note,
        );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statü güncellendi: ${status.label}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _doDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Feedback Sil'),
        content: const Text('Bu feedback kalıcı olarak silinecek.'),
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
    if (ok != true || !context.mounted) return;
    await ref
        .read(feedbackActionControllerProvider.notifier)
        .deleteFeedback(widget.feedback.id);
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feedback silindi'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color get _typeColor => switch (widget.feedback.type) {
    FeedbackType.bug => AppColors.error,
    FeedbackType.suggestion => AppColors.warning,
    FeedbackType.other => AppColors.info,
  };
  IconData get _typeIcon => switch (widget.feedback.type) {
    FeedbackType.bug => Icons.bug_report_rounded,
    FeedbackType.suggestion => Icons.lightbulb_rounded,
    FeedbackType.other => Icons.chat_bubble_outline_rounded,
  };
  Color get _statusColor => switch (widget.feedback.status) {
    FeedbackStatus.newFeedback => AppColors.info,
    FeedbackStatus.inProgress => AppColors.warning,
    FeedbackStatus.resolved => AppColors.success,
  };
}
