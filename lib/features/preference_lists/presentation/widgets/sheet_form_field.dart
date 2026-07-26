import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Liste sheet'lerinin ortak metin alanı.
///
/// Kurma ve yeniden adlandırma AYNI formu gösteriyor; ikisi ayrı ayrı
/// biçimlendirilirse (biri dolgulu kutu, öteki temanın alt çizgisi) aynı
/// iş iki farklı ekran gibi görünüyor.
class SheetFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool autofocus;
  final int? maxLength;
  final int maxLines;
  final TextCapitalization textCapitalization;

  /// Ana alan (liste adı) daha büyük yazıyla çizilir — sheet'in asıl sorusu o.
  final bool emphasized;

  /// Sağ üstte gösterilecek sayaç; null ise hiç yer kaplamaz.
  final String? counter;

  const SheetFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.autofocus = false,
    this.maxLength,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.emphasized = false,
    this.counter,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.labelSmall.copyWith(
      color: AppColors.textTertiaryFor(context),
      fontWeight: FontWeight.w700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Text(label, style: labelStyle),
              const Spacer(),
              if (counter != null) Text(counter!, style: labelStyle),
            ],
          ),
        ),
        TextField(
          controller: controller,
          autofocus: autofocus,
          maxLength: maxLength,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          style: emphasized
              ? AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)
              : AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: (emphasized
                    ? AppTextStyles.titleSmall
                    : AppTextStyles.bodyMedium)
                .copyWith(
              color: AppColors.textTertiaryFor(context),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor:
                AppColors.surfaceVariantFor(context).withValues(alpha: 0.7),
            // Kendi sayacımız var; Flutter'ınki alanın altında yer kaplıyor.
            counterText: '',
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: emphasized ? 16 : 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.borderLightFor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}
