import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Yurt oda planı semantic renkleri.
/// 30+ hardcoded color yerine semantic enum kullanılır.
enum DormRoomZoneType {
  bed,
  desk,
  wardrobe,
  bathroom,
  kitchen,
  common,
  window,
  door,
  empty,
}

extension DormRoomZoneColors on DormRoomZoneType {
  Color get fillColor {
    switch (this) {
      case DormRoomZoneType.bed:
        return AppColors.primary.withValues(alpha: 0.15);
      case DormRoomZoneType.desk:
        return AppColors.secondary.withValues(alpha: 0.15);
      case DormRoomZoneType.wardrobe:
        return AppColors.warning.withValues(alpha: 0.15);
      case DormRoomZoneType.bathroom:
        return AppColors.info.withValues(alpha: 0.15);
      case DormRoomZoneType.kitchen:
        return AppColors.success.withValues(alpha: 0.15);
      case DormRoomZoneType.common:
        return AppColors.surfaceVariant;
      case DormRoomZoneType.window:
        return AppColors.accentLight.withValues(alpha: 0.3);
      case DormRoomZoneType.door:
        return AppColors.textTertiary.withValues(alpha: 0.2);
      case DormRoomZoneType.empty:
        return Colors.transparent;
    }
  }

  Color get borderColor {
    switch (this) {
      case DormRoomZoneType.bed:
        return AppColors.primary;
      case DormRoomZoneType.desk:
        return AppColors.secondary;
      case DormRoomZoneType.wardrobe:
        return AppColors.warning;
      case DormRoomZoneType.bathroom:
        return AppColors.info;
      case DormRoomZoneType.kitchen:
        return AppColors.success;
      default:
        return AppColors.border;
    }
  }

  IconData get icon {
    switch (this) {
      case DormRoomZoneType.bed:
        return Icons.bed_rounded;
      case DormRoomZoneType.desk:
        return Icons.chair_alt_rounded;
      case DormRoomZoneType.wardrobe:
        return Icons.checkroom_rounded;
      case DormRoomZoneType.bathroom:
        return Icons.bathtub_rounded;
      case DormRoomZoneType.kitchen:
        return Icons.kitchen_rounded;
      case DormRoomZoneType.common:
        return Icons.weekend_rounded;
      case DormRoomZoneType.window:
        return Icons.window_rounded;
      case DormRoomZoneType.door:
        return Icons.door_front_door_rounded;
      case DormRoomZoneType.empty:
        return Icons.crop_din_rounded;
    }
  }

  String get label {
    switch (this) {
      case DormRoomZoneType.bed:
        return 'Yatak';
      case DormRoomZoneType.desk:
        return 'Çalışma masası';
      case DormRoomZoneType.wardrobe:
        return 'Dolap';
      case DormRoomZoneType.bathroom:
        return 'Banyo';
      case DormRoomZoneType.kitchen:
        return 'Mutfak';
      case DormRoomZoneType.common:
        return 'Ortak alan';
      case DormRoomZoneType.window:
        return 'Pencere';
      case DormRoomZoneType.door:
        return 'Kapı';
      case DormRoomZoneType.empty:
        return '';
    }
  }
}
