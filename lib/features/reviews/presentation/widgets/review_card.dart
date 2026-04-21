import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/review_model.dart';
import 'review_actions_menu.dart';

/// Sprint 3 — Kişi B (Task B1)
/// Tüm yorum gösterimlerinde kullanılacak ortak ReviewCard widget'ı.
class ReviewCard extends ConsumerWidget {
  final ReviewModel review;
  final bool showActions;
  final bool showReportMenu;
  final VoidCallback? onTap;
  final bool compact;
  final VoidCallback? onDeleted;
  final VoidCallback? onEdited;

  const ReviewCard({
    super.key,
    required this.review,
    this.showActions = false,
    this.showReportMenu = true,
    this.onTap,
    this.compact = false,
    this.onDeleted,
    this.onEdited,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildComment(),
              if (review.pros.isNotEmpty || review.cons.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildProsConsChips(),
              ],
              if (!compact && review.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildPhotoGrid(context),
              ],
              const SizedBox(height: 10),
              _buildFooter(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header: avatar + isim + üni + rating + menu ──────────────────

  Widget _buildHeader(BuildContext context) {
    final displayName = review.isAnonymous ? 'Anonim Öğrenci' : review.userName;
    final displayUni = review.isAnonymous ? null : review.userUniversity;
    final photoUrl = review.isAnonymous ? null : review.userPhotoUrl;

    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: compact ? 16 : 20,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Icon(
                  review.isAnonymous ? Icons.person_off_rounded : Icons.person,
                  color: AppColors.primary,
                  size: compact ? 16 : 20,
                )
              : null,
        ),
        const SizedBox(width: 10),

        // İsim + üniversite
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: compact ? AppTextStyles.titleSmall : AppTextStyles.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (displayUni != null)
                Text(
                  displayUni,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),

        // Rating badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.ratingColor(review.rating).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: 14,
                color: AppColors.ratingColor(review.rating),
              ),
              const SizedBox(width: 3),
              Text(
                review.rating.toStringAsFixed(1),
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.ratingColor(review.rating),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        // 3 nokta menü — ReviewActionsMenu widget'ı
        if (showActions || showReportMenu)
          ReviewActionsMenu(
            review: review,
            showOwnerActions: showActions,
            showReportAction: showReportMenu && !showActions,
            onEdit: onEdited,
            onDelete: onDeleted,
          ),
      ],
    );
  }

  // ─── Yorum metni (compact: kısa, normal: expandable) ─────────────

  Widget _buildComment() {
    if (compact) {
      return Text(
        review.comment,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textPrimary,
          height: 1.5,
        ),
      );
    }
    return _CommentExpandable(text: review.comment);
  }

  // ─── Pros / Cons chip'leri ────────────────────────────────────────

  Widget _buildProsConsChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (review.pros.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: review.pros.map((pro) => _buildChip(
              text: pro,
              color: AppColors.success,
              icon: Icons.add_circle_outline_rounded,
            )).toList(),
          ),
        if (review.pros.isNotEmpty && review.cons.isNotEmpty)
          const SizedBox(height: 6),
        if (review.cons.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: review.cons.map((con) => _buildChip(
              text: con,
              color: AppColors.error,
              icon: Icons.remove_circle_outline_rounded,
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildChip({
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Fotoğraf grid ────────────────────────────────────────────────

  Widget _buildPhotoGrid(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: review.imageUrls.length,
        separatorBuilder: (_, _a) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final url = review.imageUrls[index];
          return GestureDetector(
            onTap: () {
              // TODO(B4): PhotoGalleryScreen'e navigate et
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              child: CachedNetworkImage(
                imageUrl: url,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (_, _a) => Container(
                  width: 80,
                  height: 80,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.image, color: AppColors.textTertiary),
                ),
                errorWidget: (_, _a, _b) => Container(
                  width: 80,
                  height: 80,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.broken_image, color: AppColors.textTertiary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Footer: tarih + like ─────────────────────────────────────────

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Tarih (timeago ile)
        Icon(Icons.access_time_rounded, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          timeago.format(review.createdAt, locale: 'tr'),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
        ),
        const Spacer(),
        // Like butonu (placeholder — B3'te LikeButton widget'ı ile değiştirilecek)
        InkWell(
          onTap: () {
            // TODO(B3): LikeButton widget'ı ile değiştirilecek
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.thumb_up_outlined,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${review.likes}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Expandable Yorum Metni (private widget) ──────────────────────────

class _CommentExpandable extends StatefulWidget {
  final String text;
  const _CommentExpandable({required this.text});

  @override
  State<_CommentExpandable> createState() => _CommentExpandableState();
}

class _CommentExpandableState extends State<_CommentExpandable> {
  bool _expanded = false;
  static const _maxChars = 200;

  @override
  Widget build(BuildContext context) {
    final isTooLong = widget.text.length > _maxChars;
    final displayText = isTooLong && !_expanded
        ? '${widget.text.substring(0, _maxChars)}...'
        : widget.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayText,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
        if (isTooLong)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _expanded ? 'Daha az göster' : 'Devamını oku',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
