import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/score_input.dart';

/// OBP bölümü: diploma notu + canlı katkı etiketi + katsayı indirimi ve
/// meslek lisesi ek puanı seçenekleri.
class ObpSection extends StatelessWidget {
  final TextEditingController controller;
  final ScoreInput input;
  final ValueChanged<double> onObpChanged;
  final ValueChanged<bool> onPlacedLastYearChanged;
  final ValueChanged<bool> onMeslekOwnFieldChanged;

  const ObpSection({
    super.key,
    required this.controller,
    required this.input,
    required this.onObpChanged,
    required this.onPlacedLastYearChanged,
    required this.onMeslekOwnFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            TextInputFormatter.withFunction((oldValue, newValue) {
              final text = newValue.text.replaceAll(',', '.');
              if (text.isNotEmpty && !RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
                return oldValue;
              }
              final parsed = double.tryParse(text);
              if (parsed != null && parsed > 100) {
                return const TextEditingValue(
                  text: '100',
                  selection: TextSelection.collapsed(offset: 3),
                );
              }
              return TextEditingValue(
                text: text,
                selection: newValue.selection,
              );
            }),
          ],
          style: AppTextStyles.titleMedium,
          decoration: InputDecoration(
            hintText: 'Ör: 85.5',
            suffixText: '/ 100',
            suffixStyle: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textTertiaryFor(context)),
            filled: true,
            fillColor: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.surfaceVariant,
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: (val) =>
              onObpChanged(double.tryParse(val.replaceAll(',', '.')) ?? 0),
        ),
        const SizedBox(height: 10),
        // Canlı katkı: "OBP: 400 → yerleştirmeye +48.0 puan"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OBP: ${input.obp.toStringAsFixed(0)} → yerleştirmeye '
                  '+${input.obpContribution.toStringAsFixed(1)} puan'
                  '${input.meslekOwnField ? ' (kendi alanında +${(input.obpContribution + input.ekPuanContribution).toStringAsFixed(1)})' : ''}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Kart dekorunun üstünde ListTile mürekkebi için şeffaf Material.
        Material(
          color: Colors.transparent,
          child: Column(
            children: [
              CheckboxListTile(
                value: input.placedLastYear,
                onChanged: (v) => onPlacedLastYearChanged(v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                title: Text(
                  'Geçen yıl bir yükseköğretim programına yerleştim',
                  style: AppTextStyles.bodyMedium,
                ),
                subtitle: Text(
                  'OBP katsayısı yarıya iner (0.12 → 0.06)',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondaryFor(context)),
                ),
              ),
              CheckboxListTile(
                value: input.meslekOwnField,
                onChanged: (v) => onMeslekOwnFieldChanged(v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                title: Text(
                  'Meslek lisesi mezunuyum, kendi alanımda tercih yapacağım',
                  style: AppTextStyles.bodyMedium,
                ),
                subtitle: Text(
                  'Kendi alanındaki programlar için ek OBP katkısı (+0.06)',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondaryFor(context)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
