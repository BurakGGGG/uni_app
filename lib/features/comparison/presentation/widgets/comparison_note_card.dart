import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/comparison_note.dart';

/// Tek bir karşılaştırma notunu gösteren kart widget'ı.
class ComparisonNoteCard extends StatelessWidget {
  final ComparisonNote note;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ComparisonNoteCard({
    super.key,
    required this.note,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Üst Row: Rating + Actions ────────────────────
          Row(
            children: [
              if (note.rating != null) ...[
                _RatingStars(rating: note.rating!),
                const Spacer(),
              ] else
                const Spacer(),
              if (onEdit != null)
                _ActionButton(
                  icon: Icons.edit_rounded,
                  onTap: onEdit!,
                  isDark: isDark,
                ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  onTap: onDelete!,
                  isDark: isDark,
                  isDestructive: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // ─── Not Metni ────────────────────────────────────
          Text(
            note.note,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.textPrimary,
              height: 1.5,
            ),
          ),

          // ─── Pros ─────────────────────────────────────────
          if (note.pros.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: note.pros
                  .map((pro) => _ProConChip(
                        text: pro,
                        isPro: true,
                        isDark: isDark,
                      ))
                  .toList(),
            ),
          ],

          // ─── Cons ─────────────────────────────────────────
          if (note.cons.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: note.cons
                  .map((con) => _ProConChip(
                        text: con,
                        isPro: false,
                        isDark: isDark,
                      ))
                  .toList(),
            ),
          ],

          // ─── Zaman Damgası ────────────────────────────────
          const SizedBox(height: 10),
          Text(
            _formatRelativeTime(note.updatedAt),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} hafta önce';
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
  }
}

// ─── Rating Yıldızları ──────────────────────────────────────────────

class _RatingStars extends StatelessWidget {
  final int rating;
  const _RatingStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: filled ? AppColors.tierPro : AppColors.textTertiary,
        );
      }),
    );
  }
}

// ─── Pro/Con Chip ───────────────────────────────────────────────────

class _ProConChip extends StatelessWidget {
  final String text;
  final bool isPro;
  final bool isDark;

  const _ProConChip({
    required this.text,
    required this.isPro,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPro ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPro ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button ──────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.error
        : (isDark ? Colors.white54 : AppColors.textTertiary);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
