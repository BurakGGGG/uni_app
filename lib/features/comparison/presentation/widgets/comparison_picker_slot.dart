import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Karşılaştırma seçim ekranındaki tek slot (boş veya dolu).
/// 3 ekranda da (uni / bölüm / şehir) aynı görsel pattern.
///
/// Boş ise: gradient + dashed border + büyük + ikonu + "Seçmek için dokun".
/// Dolu ise: logo widget (caller verir) + isim + opsiyonel alt başlık.
class ComparisonPickerSlot extends StatelessWidget {
  final bool isEmpty;
  final String emptyLabel; // "Üniversite A" / "Bölüm A" / "Şehir A"
  final IconData emptyIcon; // örn Icons.add_business_rounded
  final Color accentColor;
  final VoidCallback onTap;

  // Dolu durum için
  final Widget? logo; // UniversityLogoBox, CityLogo, vb.
  final String? title; // Üniversite/bölüm/şehir adı
  final String? subtitle; // Tür, puan, vb.

  const ComparisonPickerSlot({
    super.key,
    required this.isEmpty,
    required this.emptyLabel,
    required this.emptyIcon,
    required this.accentColor,
    required this.onTap,
    this.logo,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 168,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isEmpty
                ? [
                    accentColor.withValues(alpha: isDark ? 0.10 : 0.06),
                    accentColor.withValues(alpha: isDark ? 0.04 : 0.02),
                  ]
                : [
                    accentColor.withValues(alpha: isDark ? 0.14 : 0.08),
                    isDark
                        ? AppColors.darkSurface
                        : AppColors.surface,
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: isEmpty ? 0.35 : 0.5),
            width: isEmpty ? 1.5 : 2,
          ),
          boxShadow: isEmpty
              ? null
              : [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: isEmpty
            ? _buildEmpty(isDark)
            : _buildFilled(isDark),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            emptyIcon,
            color: accentColor,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          emptyLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelMedium.copyWith(
            color: accentColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Seçmek için dokun',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSmall.copyWith(
            color: accentColor.withValues(alpha: 0.7),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilled(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ?logo,
          const SizedBox(height: 10),
          if (title != null)
            Text(
              title!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                height: 1.2,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: accentColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 2 slot arasındaki VS badge — gradient + glow.
class ComparisonVsBadge extends StatelessWidget {
  final double size;
  const ComparisonVsBadge({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'VS',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.32,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// Picker section üst başlığı (alt başlık + dekoratif çizgi).
class ComparisonPickerHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;

  const ComparisonPickerHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withValues(alpha: 0.18),
                    accentColor.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Picker alt ipucu chip'i (motivational).
class ComparisonPickerHint extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accentColor;

  const ComparisonPickerHint({
    super.key,
    required this.icon,
    required this.text,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.10 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.labelSmall.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
