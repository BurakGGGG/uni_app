import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../university/domain/models/university_model.dart';
import '../providers/comparison_providers.dart';
import 'university_logo_box.dart';

/// 3. üniversiteyi seçmek için sade arama + liste bottom sheet.
/// Mevcut 2 üniversite (uniIdA, uniIdB) listeden hariç tutulur.
class TripleThirdUniPicker extends ConsumerStatefulWidget {
  final String excludeIdA;
  final String excludeIdB;
  final void Function(String selectedId) onSelected;

  const TripleThirdUniPicker({
    super.key,
    required this.excludeIdA,
    required this.excludeIdB,
    required this.onSelected,
  });

  static Future<String?> show(
    BuildContext context, {
    required String excludeIdA,
    required String excludeIdB,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => TripleThirdUniPicker(
        excludeIdA: excludeIdA,
        excludeIdB: excludeIdB,
        onSelected: (id) => Navigator.pop(modalContext, id),
      ),
    );
  }

  @override
  ConsumerState<TripleThirdUniPicker> createState() =>
      _TripleThirdUniPickerState();
}

class _TripleThirdUniPickerState extends ConsumerState<TripleThirdUniPicker> {
  String _query = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unisAsync = ref.watch(departmentPickerUniversitiesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_rounded,
                        size: 22, color: AppColors.tierPro),
                    const SizedBox(width: 10),
                    Text(
                      '3. üniversiteyi seç',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Arama
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _ctrl,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Üniversite ara…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: unisAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Yüklenemedi: $e'),
                    ),
                  ),
                  data: (unis) {
                    final filtered = _applyFilter(unis);
                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Sonuç bulunamadı',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiaryFor(context),
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, i) =>
                          _UniRow(uni: filtered[i], onTap: widget.onSelected),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<UniversityModel> _applyFilter(List<UniversityModel> unis) {
    final q = _query.toLowerCase();
    return unis
        .where((u) => u.id != widget.excludeIdA && u.id != widget.excludeIdB)
        .where((u) =>
            q.isEmpty ||
            u.name.toLowerCase().contains(q) ||
            u.aliases.any((a) => a.toLowerCase().contains(q)))
        .toList();
  }
}

class _UniRow extends StatelessWidget {
  final UniversityModel uni;
  final void Function(String id) onTap;
  const _UniRow({required this.uni, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onTap(uni.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Logo (reusable widget — rounded square, BoxFit.contain)
            UniversityLogoBox(
              universityId: uni.id,
              universityName: uni.name,
              accentColor: AppColors.primary,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    uni.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${uni.type} · ${uni.establishedYear}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiaryFor(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiaryFor(context)),
          ],
        ),
      ),
    );
  }
}
