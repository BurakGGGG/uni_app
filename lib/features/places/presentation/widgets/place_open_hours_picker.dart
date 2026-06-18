import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PlaceOpenHoursPicker extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;

  const PlaceOpenHoursPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Çalışma saatleri',
  });

  static final List<String> _timeOptions = List.generate(48, (index) {
    final hour = index ~/ 2;
    final minute = index.isEven ? '00' : '30';
    return '${hour.toString().padLeft(2, '0')}:$minute';
  });

  Future<void> _showPicker(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _OpenHoursSheet(initialValue: value, timeOptions: _timeOptions),
    );
    if (!context.mounted || result == null) return;
    onChanged(result == _OpenHoursSheet.clearValue ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;
    return Material(
      color: AppColors.surfaceFor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.borderLightFor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => _showPicker(context),
        leading: const Icon(Icons.schedule_rounded, color: AppColors.primary),
        title: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(hasValue ? value! : 'Saat seç'),
        trailing: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textSecondaryFor(context),
        ),
      ),
    );
  }
}

class _OpenHoursSheet extends StatefulWidget {
  static const clearValue = '__clear__';

  final String? initialValue;
  final List<String> timeOptions;

  const _OpenHoursSheet({
    required this.initialValue,
    required this.timeOptions,
  });

  @override
  State<_OpenHoursSheet> createState() => _OpenHoursSheetState();
}

class _OpenHoursSheetState extends State<_OpenHoursSheet> {
  late String _opening;
  late String _closing;
  late bool _isOpen24Hours;

  @override
  void initState() {
    super.initState();
    final value = widget.initialValue?.trim() ?? '';
    _isOpen24Hours = value == '24 saat açık';
    final match = RegExp(
      r'^(\d{2}:\d{2})\s*-\s*(\d{2}:\d{2})$',
    ).firstMatch(value);
    _opening = _safeTime(match?.group(1), '08:00');
    _closing = _safeTime(match?.group(2), '22:00');
  }

  String _safeTime(String? value, String fallback) {
    return widget.timeOptions.contains(value) ? value! : fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLightFor(context),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Çalışma Saatleri',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Yazmak yerine listeden açılış ve kapanış saatini seç.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('24 saat açık'),
            value: _isOpen24Hours,
            onChanged: (value) => setState(() => _isOpen24Hours = value),
          ),
          if (!_isOpen24Hours) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _opening,
                    decoration: const InputDecoration(labelText: 'Açılış'),
                    menuMaxHeight: 320,
                    items: widget.timeOptions
                        .map(
                          (time) =>
                              DropdownMenuItem(value: time, child: Text(time)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _opening = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _closing,
                    decoration: const InputDecoration(labelText: 'Kapanış'),
                    menuMaxHeight: 320,
                    items: widget.timeOptions
                        .map(
                          (time) =>
                              DropdownMenuItem(value: time, child: Text(time)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _closing = value);
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, _OpenHoursSheet.clearValue),
                child: const Text('Temizle'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  _isOpen24Hours ? '24 saat açık' : '$_opening - $_closing',
                ),
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
