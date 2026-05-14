import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/comparison_note.dart';

/// Not ekleme/düzenleme için bottom sheet.
/// [existingNote] verilirse edit modunda açılır ve alanlar pre-fill edilir.
class ComparisonNoteBottomSheet extends StatefulWidget {
  final ComparisonNote? existingNote;

  const ComparisonNoteBottomSheet({
    super.key,
    this.existingNote,
  });

  /// Bottom sheet'i açar ve sonucu döndürür.
  /// Dönen map: { note, pros, cons, rating } — null ise iptal edildi.
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    ComparisonNote? existingNote,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ComparisonNoteBottomSheet(existingNote: existingNote),
    );
  }

  @override
  State<ComparisonNoteBottomSheet> createState() =>
      _ComparisonNoteBottomSheetState();
}

class _ComparisonNoteBottomSheetState extends State<ComparisonNoteBottomSheet> {
  late TextEditingController _noteController;
  late TextEditingController _proController;
  late TextEditingController _conController;
  late List<String> _pros;
  late List<String> _cons;
  int? _rating;

  // ─── UX Validation State ─────────────────────────────────────
  bool _isInvalid = false;
  bool _isOverLimit = false;
  bool _isSaving = false;

  bool get _isEdit => widget.existingNote != null;
  bool get _isValid =>
      _noteController.text.trim().isNotEmpty && !_isOverLimit;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingNote;
    _noteController = TextEditingController(text: existing?.note ?? '');
    _proController = TextEditingController();
    _conController = TextEditingController();
    _pros = List<String>.from(existing?.pros ?? []);
    _cons = List<String>.from(existing?.cons ?? []);
    _rating = existing?.rating;
    // İlk state — edit modunda geçerli not zaten var
    _isInvalid = _noteController.text.trim().isEmpty && !_isEdit;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _proController.dispose();
    _conController.dispose();
    super.dispose();
  }

  void _addPro() {
    final text = _proController.text.trim();
    if (text.isEmpty || _pros.length >= 5) return;
    setState(() {
      _pros.add(text);
      _proController.clear();
    });
  }

  void _addCon() {
    final text = _conController.text.trim();
    if (text.isEmpty || _cons.length >= 5) return;
    setState(() {
      _cons.add(text);
      _conController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_isValid || _isSaving) return;
    setState(() => _isSaving = true);
    // Pop ile sonucu döndür — caller save işlemini yapar
    Navigator.of(context).pop({
      'note': _noteController.text.trim(),
      'pros': _pros,
      'cons': _cons,
      'rating': _rating,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Handle ─────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Title ──────────────────────────────────────
            Text(
              _isEdit ? 'Notu Düzenle' : 'Not Ekle',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Karşılaştırma hakkındaki düşüncelerini kaydet',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // ─── Rating ─────────────────────────────────────
            Text(
              'Tercih Puanın',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _RatingSelector(
              rating: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 20),

            // ─── Note TextField ─────────────────────────────
            Text(
              'Not',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLength: 500,
              maxLines: 5,
              minLines: 2,
              textInputAction: TextInputAction.done,
              onChanged: (val) {
                setState(() {
                  _isInvalid = val.trim().isEmpty;
                  _isOverLimit = val.length > 500;
                });
              },
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Örn: İTÜ bana daha yakın, kampüsü çok güzel...',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
                errorText: _isInvalid ? 'Not boş bırakılamaz' : null,
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
                counterStyle: AppTextStyles.labelSmall.copyWith(
                  color: _isOverLimit ? AppColors.error : AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Pros ───────────────────────────────────────
            _ChipInputSection(
              label: 'Artılar',
              icon: Icons.add_circle_outline_rounded,
              color: AppColors.success,
              items: _pros,
              controller: _proController,
              onAdd: _addPro,
              onRemove: (i) => setState(() => _pros.removeAt(i)),
              isDark: isDark,
              maxItems: 5,
            ),
            const SizedBox(height: 14),

            // ─── Cons ───────────────────────────────────────
            _ChipInputSection(
              label: 'Eksiler',
              icon: Icons.remove_circle_outline_rounded,
              color: AppColors.error,
              items: _cons,
              controller: _conController,
              onAdd: _addCon,
              onRemove: (i) => setState(() => _cons.removeAt(i)),
              isDark: isDark,
              maxItems: 5,
            ),
            const SizedBox(height: 24),

            // ─── Actions ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Text(
                      'İptal',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: (_isInvalid || _isOverLimit || _isSaving || !_isValid)
                        ? null
                        : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isEdit ? Icons.check_rounded : Icons.note_add_rounded,
                            size: 18,
                          ),
                    label: Text(_isEdit ? 'Güncelle' : 'Kaydet'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Rating Selector ────────────────────────────────────────────────

class _RatingSelector extends StatelessWidget {
  final int? rating;
  final ValueChanged<int?> onChanged;

  const _RatingSelector({
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final value = i + 1;
        final selected = rating != null && value <= rating!;
        return GestureDetector(
          onTap: () {
            // Aynı yıldıza tekrar basarsa rating'i kaldır
            onChanged(rating == value ? null : value);
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: AnimatedScale(
              scale: selected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                selected ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 32,
                color: selected ? AppColors.tierPro : AppColors.textTertiary,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Chip Input Section ─────────────────────────────────────────────

class _ChipInputSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final List<String> items;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final bool isDark;
  final int maxItems;

  const _ChipInputSection({
    required this.label,
    required this.icon,
    required this.color,
    required this.items,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
    required this.isDark,
    required this.maxItems,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              '$label (${items.length}/$maxItems)',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(items.length, (i) {
              return Chip(
                label: Text(
                  items[i],
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                deleteIcon: Icon(Icons.close, size: 14, color: color),
                onDeleted: () => onRemove(i),
                backgroundColor: color.withValues(alpha: isDark ? 0.15 : 0.08),
                side: BorderSide(color: color.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }),
          ),
          const SizedBox(height: 8),
        ],
        if (items.length < maxItems)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Yeni ${label.toLowerCase().replaceAll('lar', '').replaceAll('ler', '')} ekle...',
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => onAdd(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: color.withValues(alpha: 0.15),
                  foregroundColor: color,
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
