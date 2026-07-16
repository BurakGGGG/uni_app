import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../places/presentation/providers/place_providers.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../domain/models/review_model.dart';
import '../providers/review_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'review_actions_menu.dart';
import 'like_button.dart';
import '../screens/photo_gallery_screen.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Sprint 3 — Kişi B (Task B1)
/// Tüm yorum gösterimlerinde kullanılacak ortak ReviewCard widget'ı.
class ReviewCard extends ConsumerWidget {
  // Static decorations — only things that DON'T need context
  static const _cardBorderRadius = BorderRadius.all(
    Radius.circular(AppConstants.radiusLg),
  );

  final ReviewModel review;
  final bool showActions;
  final bool showReportMenu;
  final bool showTargetInfo;
  final VoidCallback? onTap;
  final bool compact;
  final Future<void> Function()? onDeleted;
  final VoidCallback? onEdited;

  const ReviewCard({
    super.key,
    required this.review,
    this.showActions = false,
    this.showReportMenu = true,
    this.showTargetInfo = false,
    this.onTap,
    this.compact = false,
    this.onDeleted,
    this.onEdited,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final cardDecoration = BoxDecoration(
      color: AppColors.surfaceFor(context),
      borderRadius: _cardBorderRadius,
      border: Border.fromBorderSide(
        BorderSide(color: AppColors.borderLightFor(context)),
      ),
      boxShadow: AppColors.softShadowFor(context),
    );
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: cardDecoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: _cardBorderRadius,
          child: Stack(
            children: [
              // İçerik — kartın yüksekliğini bu belirler
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.spacingLg + 4,
                    AppConstants.spacingLg,
                    AppConstants.spacingLg,
                    AppConstants.spacingLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // YENİ — Hedef bilgisi (ana sayfa, tüm yorumlar, yorumlarım için)
                      if (showTargetInfo) _buildTargetHeader(ref),
                      if (showTargetInfo) const SizedBox(height: 10),

                      // Onay bekliyor banner'ı (sadece sahibine ve onaylanmamışsa)
                      if (!review.isApproved && showActions)
                        _buildPendingApprovalBanner(loc),
                      if (!review.isApproved && showActions)
                        const SizedBox(height: 12),
                      _buildHeader(context, ref, loc),
                      const SizedBox(height: 12),
                      _buildComment(),
                      if (!compact &&
                          (review.pros.isNotEmpty ||
                              review.cons.isNotEmpty)) ...[
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
              // Edge Accent — yorum puanı rengine göre marka imzası (tam yükseklik)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.ratingColor(review.rating),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppConstants.radiusLg),
                      bottomLeft: Radius.circular(AppConstants.radiusLg),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── YENİ — Hedef Header (üni/bölüm/mekan adı) ─────────────────
  Widget _buildTargetHeader(WidgetRef ref) {
    // Internal: l10n applied in _buildHeader; target labels are data-driven
    switch (review.type) {
      case ReviewType.university:
        final uniAsync = ref.watch(universityDetailProvider(review.targetId));
        return _TargetChip(
          icon: Icons.school_rounded,
          label: uniAsync.when(
            data: (u) => u?.name ?? 'Üniversite',
            loading: () => 'Yükleniyor...',
            error: (err, stack) => 'Üniversite',
          ),
          subtitle: 'Üniversite Yorumu',
          color: AppColors.primary,
        );

      case ReviewType.department:
        final deptAsync = ref.watch(departmentDetailProvider(review.targetId));
        final uniAsync = ref.watch(
          universityDetailProvider(review.universityId),
        );
        return _TargetChip(
          icon: Icons.menu_book_rounded,
          label: deptAsync.when(
            data: (d) => d?.name ?? 'Bölüm',
            loading: () => 'Yükleniyor...',
            error: (err, stack) => 'Bölüm',
          ),
          subtitle: uniAsync.when(
            data: (u) => '${u?.name ?? ""} • Bölüm Yorumu',
            loading: () => 'Bölüm Yorumu',
            error: (err, stack) => 'Bölüm Yorumu',
          ),
          color: AppColors.accent,
        );

      case ReviewType.place:
        final placeAsync = ref.watch(placeDetailProvider(review.targetId));
        final uniAsync = ref.watch(
          universityDetailProvider(review.universityId),
        );
        return placeAsync.when(
          data: (place) {
            return _TargetChip(
              icon: place?.type.icon ?? Icons.place_rounded,
              label: place?.name ?? 'Mekan',
              subtitle: uniAsync.when(
                data: (u) =>
                    '${place?.type.label ?? "Mekan"} • ${u?.name ?? ""}',
                loading: () => place?.type.label ?? 'Mekan Yorumu',
                error: (err, stack) => 'Mekan Yorumu',
              ),
              color: _placeColor(place?.type),
            );
          },
          loading: () => _TargetChip(
            icon: Icons.place_rounded,
            label: 'Yükleniyor...',
            subtitle: 'Mekan Yorumu',
            color: AppColors.textTertiary,
          ),
          error: (err, stack) => _TargetChip(
            icon: Icons.place_rounded,
            label: 'Mekan',
            subtitle: 'Mekan Yorumu',
            color: AppColors.textTertiary,
          ),
        );
    }
  }

  Color _placeColor(dynamic placeType) {
    if (placeType == null) return AppColors.textSecondary;
    switch (placeType.toString()) {
      case 'PlaceType.cafe':
        return const Color(0xFFE65100);
      case 'PlaceType.dorm':
        return const Color(0xFF0D47A1);
      case 'PlaceType.library':
        return const Color(0xFF6A1B9A);
      default:
        return AppColors.textSecondary;
    }
  }

  // ─── Header: avatar + isim + üni + rating + menu ──────────────────

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations loc,
  ) {
    final currentUser = ref.watch(authStateProvider).value;
    final isOwner = currentUser != null && currentUser.uid == review.userId;
    final displayActions = isOwner;
    final displayName = review.isAnonymous
        ? loc.reviewAnonymousStudent
        : review.userName;
    final displayUni = review.isAnonymous ? null : review.userUniversity;
    final photoUrl = review.isAnonymous ? null : review.userPhotoUrl;

    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: review.isAnonymous
              ? null
              : () => context.push('/user/${review.userId}'),
          child: Opacity(
            opacity: review.isAnonymous ? 0.5 : 1.0,
            child: CircleAvatar(
              radius: compact ? 16 : 20,
              backgroundColor: review.isAnonymous
                  ? AppColors.textTertiary.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: photoUrl != null
                  ? CachedNetworkImageProvider(
                      photoUrl,
                      maxWidth: 80,
                      maxHeight: 80,
                    )
                  : null,
              child: photoUrl == null
                  ? Icon(
                      review.isAnonymous
                          ? Icons.person_off_rounded
                          : Icons.person,
                      color: review.isAnonymous
                          ? AppColors.textTertiary
                          : AppColors.primary,
                      size: compact ? 16 : 20,
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // İsim + üniversite
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: compact
                    ? AppTextStyles.bodyMedium
                    : AppTextStyles.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (displayUni != null)
                Text(
                  displayUni,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryFor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (!compact) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      review.isOwnUniversity
                          ? Icons.verified_rounded
                          : Icons.school_outlined,
                      size: 12,
                      color: review.isOwnUniversity
                          ? AppColors.success
                          : AppColors.textTertiaryFor(context),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        review.isOwnUniversity
                            ? loc.reviewBadgeOwnUniversity
                            : loc.reviewBadgeOtherUniversity,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 10,
                          color: review.isOwnUniversity
                              ? AppColors.success
                              : AppColors.textTertiaryFor(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
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
        if (displayActions || showReportMenu) ...[
          const SizedBox(width: 8),
          ReviewActionsMenu(
            review: review,
            showOwnerActions: displayActions,
            showReportAction: showReportMenu && !displayActions,
            onEdit: displayActions
                ? (onEdited ?? () => context.push('/edit-review/${review.id}'))
                : null,
            onDelete: displayActions
                ? (onDeleted ?? () => _deleteReview(context, ref))
                : null,
          ),
        ],
      ],
    );
  }

  Future<void> _deleteReview(BuildContext context, WidgetRef ref) async {
    await ref
        .read(reviewActionControllerProvider.notifier)
        .deleteReview(review);
    invalidateUserProfileAfterReviewChange(ref);

    if (context.mounted) {
      showAppSnackBar(
        context,
        message: 'Yorumunuz başarıyla silindi',
        isSuccess: true,
      );
    }
  }

  // ─── Yorum metni (compact: kısa, normal: expandable) ─────────────

  Widget _buildComment() {
    if (compact) {
      return Text(
        review.comment,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySmall,
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
            children: review.pros
                .map(
                  (pro) => _buildChip(
                    text: pro,
                    color: AppColors.success,
                    icon: Icons.add_circle_outline_rounded,
                  ),
                )
                .toList(),
          ),
        if (review.pros.isNotEmpty && review.cons.isNotEmpty)
          const SizedBox(height: 6),
        if (review.cons.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: review.cons
                .map(
                  (con) => _buildChip(
                    text: con,
                    color: AppColors.error,
                    icon: Icons.remove_circle_outline_rounded,
                  ),
                )
                .toList(),
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
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final url = review.imageUrls[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoGalleryScreen(
                    imageUrls: review.imageUrls,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              child: CachedNetworkImage(
                imageUrl: url,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                memCacheWidth: 160,
                memCacheHeight: 160,
                placeholder: (_, url) => Container(
                  width: 80,
                  height: 80,
                  color: AppColors.surfaceVariantFor(context),
                  child: Icon(
                    Icons.image,
                    color: AppColors.textTertiaryFor(context),
                  ),
                ),
                errorWidget: (_, err, stack) => Container(
                  width: 80,
                  height: 80,
                  color: AppColors.surfaceVariantFor(context),
                  child: Icon(
                    Icons.broken_image,
                    color: AppColors.textTertiaryFor(context),
                  ),
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
        Icon(
          Icons.access_time_rounded,
          size: 13,
          color: AppColors.textTertiaryFor(context),
        ),
        const SizedBox(width: 4),
        Text(
          timeago.format(review.createdAt, locale: 'tr'),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
            fontSize: 11,
          ),
        ),
        const Spacer(),
        // Like butonu — LikeButton widget'ı (optimistic UI)
        LikeButton(review: review),
      ],
    );
  }

  // ─── Onay Bekliyor Banner'ı ──────────────────────────────────────────

  Widget _buildPendingApprovalBanner(AppLocalizations loc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.pending_actions_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.reviewPendingTitle,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.reviewPendingDesc,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── YENİ — Hedef Chip Widget'ı ──────────────────────────────────
class _TargetChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  const _TargetChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: color.withValues(alpha: 0.6),
          ),
        ],
      ),
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
    final loc = AppLocalizations.of(context);
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
            color: AppColors.textPrimaryFor(context),
            height: 1.5,
          ),
        ),
        if (isTooLong)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _expanded ? loc.reviewShowLess : loc.reviewReadMore,
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
