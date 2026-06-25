import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final accentColor = isKyk ? AppColors.info : AppColors.warning;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isKyk ? AppColors.infoLight : AppColors.warningLight,
            AppColors.surfaceFor(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bed_rounded, size: 20, color: accentColor),
              const SizedBox(width: 8),
              Text('Yurt Bilgileri', style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: accentColor,
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
                  color: accentColor,
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.meeting_room_rounded,
                  label: 'Oda Tipi',
                  value: 'Bilinmiyor',
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.access_time_rounded,
                  label: 'Giriş-Çıkış',
                  value: isKyk ? '06:00 - 23:00' : 'Esnek',
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
          // ── Telefon numarası ──
          if (place.phone != null && place.phone!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ContactRow(
              icon: Icons.phone_rounded,
              label: place.phone!,
              color: accentColor,
              onTap: () => _launchPhone(place.phone!),
            ),
          ],
          // ── Adres ──
          if (place.address.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ContactRow(
              icon: Icons.location_on_rounded,
              label: place.address,
              color: AppColors.textSecondaryFor(context),
              onTap: place.mapUrl != null
                  ? () => _launchUrl(place.mapUrl!)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  ({IconData icon, Color color}) _getGenderInfo(String gender) {
    if (gender.contains('kız')) {
      return (icon: Icons.female_rounded, color: AppColors.secondary);
    } else if (gender.contains('erkek')) {
      return (icon: Icons.male_rounded, color: AppColors.info);
    } else if (gender.contains('karma')) {
      return (icon: Icons.people_outline_rounded, color: AppColors.success);
    }
    return (icon: Icons.help_outline_rounded, color: AppColors.textSecondary);
  }

  Future<void> _launchPhone(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
        color: AppColors.surfaceFor(context),
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
                color: AppColors.textTertiaryFor(context),
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

/// Tıklanabilir iletişim satırı (telefon, adres)
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: onTap != null ? color : AppColors.textSecondaryFor(context),
                  fontWeight: onTap != null ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: color.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}
