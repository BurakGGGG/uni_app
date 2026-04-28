import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PlaceAmenitiesGrid extends StatelessWidget {
  final List<String> amenities;
  final int? maxVisible;

  const PlaceAmenitiesGrid({
    super.key,
    required this.amenities,
    this.maxVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();

    final visible = maxVisible != null && amenities.length > maxVisible!
        ? amenities.take(maxVisible!).toList()
        : amenities;
    final hiddenCount = amenities.length - visible.length;

    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        ...visible.map((a) => _AmenityChip(label: a, icon: _iconFor(a))),
        if (hiddenCount > 0)
          _AmenityChip(label: '+$hiddenCount', icon: Icons.more_horiz_rounded),
      ],
    );
  }

  IconData _iconFor(String amenity) {
    final l = amenity.toLowerCase();
    if (l.contains('wi-fi') || l.contains('wifi')) return Icons.wifi_rounded;
    if (l.contains('priz')) return Icons.power_rounded;
    if (l.contains('sessiz')) return Icons.volume_off_rounded;
    if (l.contains('7/24') || l.contains('açık')) return Icons.schedule_rounded;
    if (l.contains('kız')) return Icons.female_rounded;
    if (l.contains('erkek')) return Icons.male_rounded;
    if (l.contains('karma')) return Icons.people_outline_rounded;
    if (l.contains('kyk')) return Icons.account_balance_rounded;
    if (l.contains('özel')) return Icons.business_rounded;
    if (l.contains('kütüphane')) return Icons.local_library_rounded;
    return Icons.check_circle_outline_rounded;
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _AmenityChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
