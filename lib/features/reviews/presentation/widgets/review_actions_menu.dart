import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/review_model.dart';
import 'report_dialog.dart';

/// Sprint 3 — Kişi B (Task B1 Finalize + Task A5)
/// ReviewCard içinde kullanılan bottom sheet menü widget'ı.
/// Sahip aksiyonları (düzenle/sil) ve şikayet seçeneği sunar.
class ReviewActionsMenu extends ConsumerWidget {
  final ReviewModel review;
  final bool showOwnerActions;
  final bool showReportAction;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;

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
    return GestureDetector(
      onTap: () => _showBottomSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.textTertiary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          size: 18,
          color: AppColors.textTertiaryFor(context),
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 20),

              // Başlık
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_rounded,
                      size: 20,
                      color: AppColors.textSecondaryFor(context),
                    ),
                    const SizedBox(width: 8),
                    Text('İşlemler', style: AppTextStyles.titleMedium),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Düzenle
              if (showOwnerActions && onEdit != null)
                _ActionTile(
                  icon: Icons.edit_rounded,
                  label: 'Yorumu Düzenle',
                  subtitle: 'Puanları, metni veya fotoğrafları güncelle',
                  iconColor: AppColors.primary,
                  iconBgColor: AppColors.primary.withValues(alpha: 0.1),
                  onTap: () {
                    Navigator.pop(ctx);
                    onEdit?.call();
                  },
                ),

              // Sil
              if (showOwnerActions && onDelete != null)
                _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Yorumu Sil',
                  subtitle: 'Bu işlem geri alınamaz',
                  iconColor: AppColors.error,
                  iconBgColor: AppColors.error.withValues(alpha: 0.1),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirmed = await _showDeleteConfirmation(context);
                    if (confirmed != true || !context.mounted) return;

                    try {
                      await onDelete?.call();
                    } catch (_) {
                      if (context.mounted) {
                        showAppSnackBar(
                          context,
                          message: 'Yorum silinemedi. Lütfen tekrar deneyin.',
                          isError: true,
                        );
                      }
                    }
                  },
                ),

              // Şikayet
              if (showReportAction && !showOwnerActions)
                _ActionTile(
                  icon: Icons.flag_outlined,
                  label: 'Şikayet Et',
                  subtitle: 'Bu yorumu uygunsuz olarak bildir',
                  iconColor: AppColors.warning,
                  iconBgColor: AppColors.warning.withValues(alpha: 0.1),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleReport(context, ref);
                  },
                ),

              // İptal butonu
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondaryFor(context),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusMd,
                        ),
                        side: BorderSide(
                          color: AppColors.borderLightFor(context),
                        ),
                      ),
                    ),
                    child: const Text('İptal'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        ),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete_forever_rounded,
            size: 32,
            color: AppColors.error,
          ),
        ),
        title: Text('Yorumu Sil', style: AppTextStyles.titleLarge),
        content: Text(
          'Bu yorumu silmek istediğinizden emin misiniz?\nBu işlem geri alınamaz ve tüm beğeniler silinecektir.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondaryFor(context),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              side: BorderSide(color: AppColors.borderLightFor(context)),
            ),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
            ),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );
  }

  /// Şikayet akışı: giriş kontrolü → dialog aç.
  /// Mükerrer şikayet ve rate limit kontrolü callable function tarafında yapılır.
  Future<void> _handleReport(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şikayet etmek için giriş yapın'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => ReportDialog(review: review),
      );
    }
  }
}

// ─── Bottom Sheet Aksiyonu ─────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textTertiary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
