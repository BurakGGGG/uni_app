import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/report_repository.dart';
import '../../domain/models/review_model.dart';
import '../providers/review_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Sprint 3 — Kişi B (Task B6)
/// Yorumu şikayet etme dialog'u.
class ReportDialog extends ConsumerStatefulWidget {
  final ReviewModel review;
  const ReportDialog({super.key, required this.review});

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  ReportReason? _selectedReason;
  final _explanationController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.flag_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 8),
          const Text('Yorumu Şikayet Et'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Şikayet sebebinizi seçin:', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            ...ReportReason.values.map((reason) => RadioListTile<ReportReason>(
              title: Text(reason.label, style: AppTextStyles.bodyMedium),
              value: reason,
              groupValue: _selectedReason,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _selectedReason = v),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
            if (_selectedReason == ReportReason.other) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _explanationController,
                maxLength: 200,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Lütfen kısaca açıklayın',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: (_selectedReason == null || _submitting) ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Gönder'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _submitting = true);

    try {
      await ref.read(reportRepositoryProvider).reportReview(
        reviewId: widget.review.id,
        userId: user.uid,
        reason: _selectedReason!,
        explanation: _selectedReason == ReportReason.other
            ? _explanationController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şikayetiniz alındı. Teşekkür ederiz.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        Navigator.pop(context);

        // permission-denied → büyük ihtimalle bu yorum zaten şikayet edilmiş
        final isDuplicate = e.toString().contains('permission-denied');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDuplicate
                  ? 'Bu yorumu zaten şikayet ettiniz.'
                  : 'Bir hata oluştu. Lütfen tekrar deneyin.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
