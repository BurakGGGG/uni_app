import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Direkt net giriş satırı: tek küsuratlı alan (0 – maxQuestions).
class SubjectNetInput extends StatefulWidget {
  final String title;
  final int maxQuestions;
  final double value;
  final ValueChanged<double> onChanged;

  const SubjectNetInput({
    super.key,
    required this.title,
    required this.maxQuestions,
    required this.value,
    required this.onChanged,
  });

  @override
  State<SubjectNetInput> createState() => _SubjectNetInputState();
}

class _SubjectNetInputState extends State<SubjectNetInput> {
  late final TextEditingController _controller;

  static String _format(double v) {
    if (v == 0) return '';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(covariant SubjectNetInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dışarıdan sıfırlama (mod geçişi, geçmişten yükleme) alanı da günceller.
    if (widget.value != oldWidget.value) {
      final newText = _format(widget.value);
      if (double.tryParse(_controller.text.replaceAll(',', '.')) !=
          widget.value) {
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(widget.title, style: AppTextStyles.titleMedium),
          ),
          SizedBox(
            width: 110,
            child: TextFormField(
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text.replaceAll(',', '.');
                  if (text.isNotEmpty &&
                      !RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
                    return oldValue;
                  }
                  final parsed = double.tryParse(text);
                  if (parsed != null && parsed > widget.maxQuestions) {
                    final maxStr = widget.maxQuestions.toString();
                    return TextEditingValue(
                      text: maxStr,
                      selection:
                          TextSelection.collapsed(offset: maxStr.length),
                    );
                  }
                  return TextEditingValue(
                    text: text,
                    selection: newValue.selection,
                  );
                }),
              ],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                hintText: '0',
                suffixText: '/ ${widget.maxQuestions}',
                suffixStyle: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryFor(context)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.borderLightFor(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.borderLightFor(context)),
                ),
              ),
              onChanged: (val) {
                final parsed =
                    double.tryParse(val.replaceAll(',', '.')) ?? 0;
                widget.onChanged(
                    parsed.clamp(0, widget.maxQuestions.toDouble()));
              },
            ),
          ),
        ],
      ),
    );
  }
}
