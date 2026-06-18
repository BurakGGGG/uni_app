import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Yorum formunda artı/eksi seçim bölümü.
///
/// Preset chip'ler + özel ekleme dialog'u içerir.
/// [title] ve [color] ile artı (yeşil) / eksi (kırmızı) olarak kullanılır.
class ProsConsSection extends StatelessWidget {
  final List<String> presetItems;
  final List<String> selectedItems;
  final String title;
  final IconData icon;
  final Color color;
  final void Function(String item) onToggle;
  final void Function(String item) onAddCustom;

  const ProsConsSection({
    super.key,
    required this.presetItems,
    required this.selectedItems,
    required this.title,
    required this.icon,
    required this.color,
    required this.onToggle,
    required this.onAddCustom,
  });

  @override
  Widget build(BuildContext context) {
    // Özel eklenen öğeler (preset'te olmayan seçilmişler)
    final customItems = selectedItems
        .where((item) => !presetItems.contains(item))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.titleMedium),
            const Spacer(),
            Text(
              '${selectedItems.length} seçildi',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryFor(context)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Hazır seçeneklerden seçin veya kendi ekleyin',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryFor(context)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Preset chip'ler
            ...presetItems.map((item) {
              final isSelected = selectedItems.contains(item);
              return FilterChip(
                label: Text(
                  item,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimaryFor(context),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onToggle(item),
                selectedColor: color,
                checkmarkColor: Colors.white,
                backgroundColor: AppColors.surfaceFor(context),
                side: BorderSide(
                  color: isSelected ? color : AppColors.borderLightFor(context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
              );
            }),
            // Özel eklenen chip'ler
            ...customItems.map((item) {
              return FilterChip(
                label: Text(
                  item,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: true,
                onSelected: (_) => onToggle(item),
                selectedColor: color.withValues(alpha: 0.78),
                checkmarkColor: Colors.white,
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                onDeleted: () => onToggle(item),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
              );
            }),
            // + Ekle butonu
            ActionChip(
              avatar: Icon(Icons.add, size: 18, color: color),
              label: Text(
                'Özel ekle',
                style: AppTextStyles.bodySmall.copyWith(color: color),
              ),
              onPressed: () async {
                final result = await _showAddCustomDialog(context, title);
                if (result != null && result.isNotEmpty) {
                  onAddCustom(result);
                }
              },
              backgroundColor: color.withValues(alpha: 0.08),
              side: BorderSide(color: color.withValues(alpha: 0.31)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<String?> _showAddCustomDialog(BuildContext context, String dialogTitle) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        title: Text('Özel $dialogTitle ekle', style: AppTextStyles.titleMedium),
        content: TextField(
          controller: controller,
          maxLength: 30,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Örn: Renkli kütüphane',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiaryFor(context)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: AppColors.textSecondaryFor(context))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text('Ekle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
