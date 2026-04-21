import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/review_model.dart';

/// Sprint 3 — Kişi B (Task B1 Finalize)
/// ReviewCard içinde kullanılan 3-nokta menü widget'ı.
/// Sahip aksiyonları (düzenle/sil) ve şikayet seçeneği sunar.
class ReviewActionsMenu extends ConsumerWidget {
  final ReviewModel review;
  final bool showOwnerActions;
  final bool showReportAction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReviewActionsMenu({
    super.key,
    required this.review,
    this.showOwnerActions = false,
    this.showReportAction = true,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: AppColors.textTertiary,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            final confirmed = await _showDeleteConfirmation(context);
            if (confirmed == true) onDelete?.call();
            break;
          case 'report':
            // Şikayet dialog — Task B6'da eklenecek
            // Şimdilik placeholder
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Şikayet sistemi yakında')),
              );
            }
            break;
        }
      },
      itemBuilder: (context) => [
        if (showOwnerActions)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_rounded, size: 18),
                SizedBox(width: 8),
                Text('Düzenle'),
              ],
            ),
          ),
        if (showOwnerActions)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_rounded, size: 18, color: AppColors.error),
                const SizedBox(width: 8),
                Text('Sil', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ),
        if (showReportAction && !showOwnerActions)
          const PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag_rounded, size: 18),
                SizedBox(width: 8),
                Text('Şikayet Et'),
              ],
            ),
          ),
      ],
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yorumu sil'),
        content: const Text(
          'Bu yorumu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
