import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/place_model.dart';

class PlaceTypeChip extends StatelessWidget {
  final PlaceType type;
  final bool small;

  const PlaceTypeChip({super.key, required this.type, this.small = false});

  @override
  Widget build(BuildContext context) {
    final colors = _typeColors(type);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(small ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: small ? 12 : 14, color: colors.fg),
          SizedBox(width: small ? 4 : 6),
          Text(
            type.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.fg,
              fontWeight: FontWeight.w600,
              fontSize: small ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }

  ({Color bg, Color fg}) _typeColors(PlaceType type) {
    switch (type) {
      case PlaceType.cafe:
        return (bg: const Color(0xFFFFF3E0), fg: const Color(0xFFE65100));
      case PlaceType.dorm:
        return (bg: const Color(0xFFE3F2FD), fg: const Color(0xFF0D47A1));
      case PlaceType.library:
        return (bg: const Color(0xFFF3E5F5), fg: const Color(0xFF6A1B9A));
      case PlaceType.studyArea:
        return (bg: AppColors.successLight, fg: AppColors.success);
      case PlaceType.sports:
        return (bg: AppColors.warningLight, fg: AppColors.warning);
    }
  }
}
