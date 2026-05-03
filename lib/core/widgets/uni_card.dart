import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_constants.dart';

/// Üniversite/Bölüm/Mekan için kullanılan ana kart widget'ı
class UniCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String? subtitle;
  final double? rating;
  final int? reviewCount;
  final List<String>? tags;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? badge;
  final EdgeInsets? margin;
  final Color? brandPrimaryColor;
  final String? logoAssetPath;

  const UniCard({
    super.key,
    this.imageUrl,
    required this.title,
    this.subtitle,
    this.rating,
    this.reviewCount,
    this.tags,
    this.onTap,
    this.trailing,
    this.badge,
    this.margin,
    this.brandPrimaryColor,
    this.logoAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Row(
              children: [
                // Edge Accent
                Container(
                  width: 4,
                  height: 64,
                  decoration: BoxDecoration(
                    color: brandPrimaryColor ?? AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Mini Logo
                if (logoAssetPath != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Image.asset(
                      logoAssetPath!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 24, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                // Görsel
                if (imageUrl != null) ...[
                  _buildImage(),
                  const SizedBox(width: AppConstants.spacingMd),
                ],
                // İçerik
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık + Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTextStyles.titleLarge,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ?badge,
                        ],
                      ),
                      // Alt başlık
                      if (subtitle != null) ...[
                        const SizedBox(height: AppConstants.spacingXs),
                        Text(
                          subtitle!,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Rating
                      if (rating != null) ...[
                        const SizedBox(height: AppConstants.spacingSm),
                        _buildRating(),
                      ],
                      // Tags
                      if (tags?.isNotEmpty ?? false) ...[
                        const SizedBox(height: AppConstants.spacingSm),
                        _buildTags(),
                      ],
                    ],
                  ),
                ),
                // Trailing
                if (trailing != null) ...[
                  const SizedBox(width: AppConstants.spacingSm),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          memCacheWidth: 128,
          memCacheHeight: 128,
          placeholder: (context, url) => Container(
            width: 64,
            height: 64,
            color: AppColors.surfaceVariant,
          ),
          errorWidget: (context, url, error) => Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              color: AppColors.surfaceVariant,
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.textTertiary,
              size: 28,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        color: AppColors.surfaceVariant,
      ),
      child: const Icon(
        Icons.school_rounded,
        color: AppColors.textTertiary,
        size: 28,
      ),
    );
  }

  Widget _buildRating() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.ratingColor(rating!).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: 14,
                color: AppColors.ratingColor(rating!),
              ),
              const SizedBox(width: 3),
              Text(
                rating!.toStringAsFixed(1),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.ratingColor(rating!),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 6),
          Text(
            '$reviewCount yorum',
            style: AppTextStyles.labelSmall,
          ),
        ],
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags!.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tag,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontSize: 10,
            ),
          ),
        );
      }).toList(),
    );
  }
}
