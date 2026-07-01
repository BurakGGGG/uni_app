import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Sekme kökü / ekran başlıkları için markalı başlık bileşeni.
///
/// Başlığın soluna, kartlardaki edge-accent motifiyle uyumlu ince bir
/// gradient aksent çubuğu koyar. Böylece düz metin başlıklar yerine tüm
/// ekranlarda tutarlı, tanınabilir bir marka dokunuşu olur.
class BrandedScreenHeader extends StatelessWidget {
  const BrandedScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleStyle,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 0),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final TextStyle? titleStyle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Marka aksent çubuğu — edge-accent motifiyle uyumlu.
            Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: (titleStyle ?? AppTextStyles.displaySmall).copyWith(
                      color: AppColors.textOnSurfaceFor(context),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTextStyles.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              Center(child: trailing!),
            ],
          ],
        ),
      ),
    );
  }
}
