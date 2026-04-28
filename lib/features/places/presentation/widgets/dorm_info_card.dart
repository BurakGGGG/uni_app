import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/place_model.dart';

class DormInfoCard extends StatelessWidget {
  final PlaceModel place;

  const DormInfoCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final isKyk = (place.dormType ?? '').toUpperCase().contains('KYK');
    final genderType = place.dormGenderType?.toLowerCase() ?? '';
    final genderInfo = _getGenderInfo(genderType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isKyk ? const Color(0xFFE3F2FD) : const Color(0xFFFFF3E0),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: (isKyk ? const Color(0xFF0D47A1) : const Color(0xFFE65100))
              .withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bed_rounded, size: 20,
                color: isKyk ? const Color(0xFF0D47A1) : const Color(0xFFE65100)),
              const SizedBox(width: 8),
              Text('Yurt Bilgileri', style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isKyk ? const Color(0xFF0D47A1) : const Color(0xFFE65100),
              )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.business_rounded,
                  label: 'Tür',
                  value: place.dormType ?? '-',
                  color: isKyk ? const Color(0xFF0D47A1) : const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: genderInfo.icon,
                  label: 'Kontenjan',
                  value: place.dormGenderType ?? '-',
                  color: genderInfo.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ({IconData icon, Color color}) _getGenderInfo(String gender) {
    if (gender.contains('kız')) {
      return (icon: Icons.female_rounded, color: const Color(0xFFEC4899));
    } else if (gender.contains('erkek')) {
      return (icon: Icons.male_rounded, color: const Color(0xFF3B82F6));
    } else if (gender.contains('karma')) {
      return (icon: Icons.people_outline_rounded, color: AppColors.success);
    }
    return (icon: Icons.help_outline_rounded, color: AppColors.textSecondary);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
              )),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
