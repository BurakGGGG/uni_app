import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/place_model.dart';
import 'place_type_chip.dart';

class PlaceCard extends ConsumerWidget {
  final PlaceModel place;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final EdgeInsets? margin;

  const PlaceCard({
    super.key,
    required this.place,
    this.compact = false,
    this.onTap,
    this.onFavoriteToggle,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImage(),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(child: _buildInfo()),
                if (place.priceRange != null) _buildPriceBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (place.imageUrls.isEmpty) {
      return Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: _typeColor().withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        child: Icon(place.type.icon, color: _typeColor(), size: 32),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      child: CachedNetworkImage(
        imageUrl: place.imageUrls.first,
        width: 72, height: 72, fit: BoxFit.cover,
        memCacheWidth: 144, memCacheHeight: 144,
        placeholder: (_, url) => Container(
          width: 72, height: 72, color: AppColors.surfaceVariant,
        ),
        errorWidget: (_, url, error) => Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: _typeColor().withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: Icon(place.type.icon, color: _typeColor(), size: 32),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(place.name,
          style: AppTextStyles.titleMedium,
          maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(
          children: [
            PlaceTypeChip(type: place.type, small: true),
            if (place.dormGenderType != null) ...[
              const SizedBox(width: 6),
              _buildDormGenderBadge(),
            ],
          ],
        ),
        if (place.address.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(place.address,
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        _buildRatings(),
      ],
    );
  }

  Widget _buildDormGenderBadge() {
    final gender = place.dormGenderType!.toLowerCase();
    IconData icon;
    Color color;
    if (gender.contains('kız')) {
      icon = Icons.female_rounded;
      color = const Color(0xFFEC4899);
    } else if (gender.contains('erkek')) {
      icon = Icons.male_rounded;
      color = const Color(0xFF3B82F6);
    } else {
      icon = Icons.people_outline_rounded;
      color = AppColors.success;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 12, color: color),
    );
  }

  Widget _buildRatings() {
    // ÜniSeç içinden rating
    if (place.avgRating > 0) {
      return Row(
        children: [
          Icon(Icons.star_rounded, size: 14, color: AppColors.ratingStar),
          const SizedBox(width: 3),
          Text(
            place.avgRating.toStringAsFixed(1),
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${place.reviewCount})',
            style: AppTextStyles.labelSmall,
          ),
          if (place.externalRating != null) ...[
            const SizedBox(width: 8),
            _buildExternalRatingBadge(),
          ],
        ],
      );
    }
    // Sadece Google rating varsa
    if (place.externalRating != null) {
      return _buildExternalRatingBadge();
    }
    // Hiçbiri yoksa
    return Text(
      'Henüz değerlendirilmedi',
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textTertiary,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildExternalRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('G ', style: AppTextStyles.labelSmall.copyWith(
            color: const Color(0xFF1B5E20), fontWeight: FontWeight.w700, fontSize: 10)),
          Icon(Icons.star_rounded, size: 11, color: const Color(0xFF1B5E20)),
          const SizedBox(width: 2),
          Text(
            place.externalRating!.toStringAsFixed(1),
            style: AppTextStyles.labelSmall.copyWith(
              color: const Color(0xFF1B5E20),
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        place.priceRange!,
        style: AppTextStyles.titleSmall.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _typeColor() {
    switch (place.type) {
      case PlaceType.cafe: return const Color(0xFFE65100);
      case PlaceType.dorm: return const Color(0xFF0D47A1);
      case PlaceType.library: return const Color(0xFF6A1B9A);
      case PlaceType.studyArea: return AppColors.success;
      case PlaceType.sports: return AppColors.warning;
    }
  }
}
