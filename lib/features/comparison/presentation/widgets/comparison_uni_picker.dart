import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../providers/comparison_providers.dart';
import 'comparison_picker_slot.dart';
import 'university_logo_box.dart';

/// Üniversite karşılaştırma — başlangıç seçim ekranı.
/// Header + 2 büyük slot + VS badge + ipucu chip.
class ComparisonUniPicker extends ConsumerWidget {
  const ComparisonUniPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(comparisonSelectionProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık + alt başlık
          const ComparisonPickerHeader(
            icon: Icons.account_balance_rounded,
            title: 'Üniversite Karşılaştır',
            subtitle: 'Karşılaştırmak istediğin iki üniversiteyi seç. '
                'Puanlar, kategoriler ve istatistikler yan yana gelsin.',
            accentColor: AppColors.primary,
          ),
          const SizedBox(height: 24),

          // 2 slot + VS
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _UniSlot(
                  uniId: selection.uniIdA,
                  emptyLabel: 'Üniversite A',
                  accentColor: AppColors.primary,
                  onTap: () =>
                      _showPicker(context, ref, selection, isA: true),
                ),
              ),
              const SizedBox(width: 10),
              const ComparisonVsBadge(),
              const SizedBox(width: 10),
              Expanded(
                child: _UniSlot(
                  uniId: selection.uniIdB,
                  emptyLabel: 'Üniversite B',
                  accentColor: AppColors.secondary,
                  onTap: () =>
                      _showPicker(context, ref, selection, isA: false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // İpucu (Pro feature reklamı)
          const ComparisonPickerHint(
            icon: Icons.workspace_premium_rounded,
            text: 'Pro ile 3. üniversiteyi ekleyip üçlü karşılaştırma yapabilirsin.',
            accentColor: AppColors.tierPro,
          ),
        ],
      ),
    );
  }

  void _showPicker(
    BuildContext context,
    WidgetRef ref,
    ComparisonSelection selection, {
    required bool isA,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, controller) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final uniListAsync = ref.watch(allUniversitiesProvider);
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
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
                      Icon(
                        Icons.account_balance_rounded,
                        size: 20,
                        color: isA ? AppColors.primary : AppColors.secondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isA
                            ? 'A için üniversite seç'
                            : 'B için üniversite seç',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: uniListAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (unis) {
                      final otherId =
                          isA ? selection.uniIdB : selection.uniIdA;
                      final filtered =
                          unis.where((u) => u.id != otherId).toList();
                      return ListView.separated(
                        controller: controller,
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final uni = filtered[i];
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.pop(modalContext);
                              final notifier = ref.read(
                                  comparisonSelectionProvider.notifier);
                              if (isA) {
                                notifier.selectA(uni.id);
                              } else {
                                notifier.selectB(uni.id);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  UniversityLogoBox(
                                    universityId: uni.id,
                                    universityName: uni.name,
                                    accentColor: isA
                                        ? AppColors.primary
                                        : AppColors.secondary,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          uni.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${uni.type} · ${uni.campusLayout.label}',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                            color: AppColors.textTertiary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded,
                                      color: AppColors.textTertiary),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UniSlot extends ConsumerWidget {
  final String? uniId;
  final String emptyLabel;
  final Color accentColor;
  final VoidCallback onTap;

  const _UniSlot({
    required this.uniId,
    required this.emptyLabel,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (uniId == null) {
      return ComparisonPickerSlot(
        isEmpty: true,
        emptyLabel: emptyLabel,
        emptyIcon: Icons.school_rounded,
        accentColor: accentColor,
        onTap: onTap,
      );
    }
    final uniAsync = ref.watch(universityDetailProvider(uniId!));
    return uniAsync.when(
      loading: () => ComparisonPickerSlot(
        isEmpty: true,
        emptyLabel: 'Yükleniyor…',
        emptyIcon: Icons.hourglass_top_rounded,
        accentColor: accentColor,
        onTap: onTap,
      ),
      error: (_, _) => ComparisonPickerSlot(
        isEmpty: true,
        emptyLabel: emptyLabel,
        emptyIcon: Icons.error_outline_rounded,
        accentColor: accentColor,
        onTap: onTap,
      ),
      data: (uni) {
        if (uni == null) {
          return ComparisonPickerSlot(
            isEmpty: true,
            emptyLabel: emptyLabel,
            emptyIcon: Icons.school_rounded,
            accentColor: accentColor,
            onTap: onTap,
          );
        }
        return ComparisonPickerSlot(
          isEmpty: false,
          emptyLabel: emptyLabel,
          emptyIcon: Icons.school_rounded,
          accentColor: accentColor,
          onTap: onTap,
          logo: Hero(
            tag: 'uni_${uni.id}_compare',
            child: Material(
              color: Colors.transparent,
              child: UniversityLogoBox(
                universityId: uni.id,
                universityName: uni.name,
                accentColor: accentColor,
                size: 64,
              ),
            ),
          ),
          title: uni.name,
          subtitle: uni.type,
        );
      },
    );
  }
}
