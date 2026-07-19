import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/chat_models.dart';

/// Üni sorusunun altındaki tıklanabilir mini balonlar. Tıklanan çip
/// controller'da kullanıcı balonu olarak akışa düşer — serbest yazıyla
/// aynı yol.
class ChatChipRow extends StatelessWidget {
  final List<ChatChip> chips;
  final ValueChanged<ChatChip> onTap;
  const ChatChipRow({super.key, required this.chips, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final chip in chips)
          GestureDetector(
            onTap: () => onTap(chip),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceFor(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                chip.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
