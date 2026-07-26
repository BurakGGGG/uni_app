import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Seçili olduğu bir bakışta okunan çoktan seçmeli çip.
///
/// Uygulama teması seçili çipe %12 saydam primary veriyor ve kenarlığı
/// kapatıyor (`app_theme.dart` → `chipTheme`). Açık temada bu, gri zeminin
/// üstünde soluk bir lila; koyu temada neredeyse hiç. "Hangi şehirler?" gibi
/// seksen çipin yan yana durduğu bir ızgarada öğrenci neyi seçtiğini
/// ayırt edemiyordu — kullanıcı geri bildirimi.
///
/// Buradaki seçili durum üç sinyal taşır: dolu primary zemin, beyaz kalın
/// etiket ve tik. Tema düzeyinde değil bu widget'ta duruyor: sihirbaz
/// akışındaki üç yüzey (tanışma formu, program türü çipleri, filtre sheet'i)
/// aynı görünümü paylaşsın ama uygulamanın kalan çipleri (yorum etiketleri,
/// puan türü seçicileri) kendi renklerini korusun.
///
/// [FilterChip] sarmalanır, yeniden çizilmez — semantics ve dokunma hedefi
/// Material'ın kendi davranışı olarak kalır.
class WizardSelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const WizardSelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      // Tik, seçili durumun renkten bağımsız ikinci sinyali.
      showCheckmark: true,
      checkmarkColor: Colors.white,
      backgroundColor: AppColors.surfaceVariantFor(context),
      selectedColor: AppColors.primary,
      labelStyle: AppTextStyles.chip.copyWith(
        color: selected ? Colors.white : AppColors.textPrimaryFor(context),
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.borderLightFor(context),
      ),
    );
  }
}
