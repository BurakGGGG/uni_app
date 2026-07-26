import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SubjectScoreInput extends StatelessWidget {
  final String title;
  final int correct;
  final int wrong;
  final void Function(int) onCorrectChanged;
  final void Function(int) onWrongChanged;
  final int maxQuestions;

  const SubjectScoreInput({
    super.key,
    required this.title,
    required this.correct,
    required this.wrong,
    required this.onCorrectChanged,
    required this.onWrongChanged,
    required this.maxQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final net = correct - (wrong / 4.0);
    final hasError = (correct + wrong) > maxQuestions;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? AppColors.error : AppColors.borderLightFor(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Net: ${net.toStringAsFixed(2)}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NumberInput(
                  label: 'Doğru',
                  value: correct,
                  onChanged: onCorrectChanged,
                  max: maxQuestions,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _NumberInput(
                  label: 'Yanlış',
                  value: wrong,
                  onChanged: onWrongChanged,
                  max: maxQuestions,
                ),
              ),
            ],
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Doğru + yanlış toplamı $maxQuestions soruyu geçemez',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _NumberInput extends StatefulWidget {
  final String label;
  final int value;
  final void Function(int) onChanged;
  final int max;

  const _NumberInput({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.max,
  });

  @override
  State<_NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<_NumberInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value == 0 ? '' : widget.value.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _NumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dışarıdan değer sıfırlanırsa controller'ı güncelle
    if (widget.value != oldWidget.value) {
      final newText = widget.value == 0 ? '' : widget.value.toString();
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderLightFor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderLightFor(context)),
            ),
            hintText: '0',
          ),
          onChanged: (val) {
            if (val.isEmpty) {
              widget.onChanged(0);
              return;
            }
            final parsed = int.tryParse(val);
            if (parsed != null) {
              if (parsed <= widget.max) {
                widget.onChanged(parsed);
              } else {
                // Eğer max değeri aşıyorsa eski haline döndür ve imleci sona al
                final maxStr = widget.max.toString();
                _controller.value = TextEditingValue(
                  text: maxStr,
                  selection: TextSelection.collapsed(offset: maxStr.length),
                );
                widget.onChanged(widget.max);
              }
            }
          },
        ),
      ],
    );
  }
}
