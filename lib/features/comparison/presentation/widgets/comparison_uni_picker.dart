import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/university_abbreviations.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/utils/localized_labels.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../providers/compare_pick_providers.dart';
import '../providers/comparison_providers.dart';
import 'compare/compare_pick_stage.dart';
import 'comparison_picker_slot.dart';
import 'university_logo_box.dart';

/// Üniversite karşılaştırma — başlangıç seçim ekranı.
///
/// Ortak `ComparePickStage` iskeleti; bölüm ve şehir ekranları da aynısını
/// kullanıyor.
class ComparisonUniPicker extends ConsumerWidget {
  const ComparisonUniPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(comparisonSelectionProvider);
    final loc = AppLocalizations.of(context);
    final suggestions = ref.watch(comparePickUniversitiesProvider).valueOrNull;

    return ComparePickStage(
      lead: loc.comparisonUniversityPickerSubtitle,
      filledA: selection.uniIdA != null,
      filledB: selection.uniIdB != null,
      nextLabel: selection.uniIdA == null
          ? loc.selectUniversityA
          : loc.selectUniversityB,
      slotA: _UniSlot(
        uniId: selection.uniIdA,
        emptyLabel: loc.selectUniversityA,
        accentColor: AppColors.primary,
        onTap: () => showComparisonUniPicker(context, ref, isA: true),
      ),
      slotB: _UniSlot(
        uniId: selection.uniIdB,
        emptyLabel: loc.selectUniversityB,
        accentColor: AppColors.secondary,
        onTap: () => showComparisonUniPicker(context, ref, isA: false),
      ),
      children: [
        ComparePickSuggestions(
          title: loc.cmpPickSuggestUniversity,
          items: [
            for (final uni in suggestions ?? const [])
              if (uni.id != selection.uniIdA && uni.id != selection.uniIdB)
                ComparePickSuggestion(
                  label: UniversityAbbreviations.shorten(uni.name),
                  sublabel: localizedUniversityType(loc, uni.type),
                  leading: UniversityLogoBox(
                    universityId: uni.id,
                    universityName: uni.name,
                    accentColor: AppColors.primary,
                    size: 36,
                  ),
                  onTap: () => _quickSelect(ref, uni.id),
                ),
          ],
        ),
        const SizedBox(height: 22),
        ComparisonPickerHint(
          icon: Icons.workspace_premium_rounded,
          text: loc.comparisonTripleHint,
          accentColor: AppColors.tierPro,
        ),
      ],
    );
  }

  /// Öneri BOŞ olan tarafa yerleşir — iki taraf da doluysa bu ekran zaten
  /// görünmüyor.
  void _quickSelect(WidgetRef ref, String uniId) {
    final selection = ref.read(comparisonSelectionProvider);
    final notifier = ref.read(comparisonSelectionProvider.notifier);
    if (selection.uniIdA == null) {
      notifier.selectA(uniId);
    } else {
      notifier.selectB(uniId);
    }
  }
}

/// A ya da B tarafı için üniversite seçim sayfası.
///
/// Hem ilk seçim ekranı hem sonuçtaki kompakt şerit bunu açıyor — şerit
/// "dokununca değişsin" diye tasarlandı (kullanıcı kararı) ve seçici iki
/// yerde ayrı kurulsaydı biri diğerinin filtresini kaçırırdı.
void showComparisonUniPicker(
  BuildContext context,
  WidgetRef ref, {
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
        final selection = ref.read(comparisonSelectionProvider);
        final loc = AppLocalizations.of(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Tutamak temadan geliyor (`showDragHandle: true`).
              const SizedBox(height: 8),
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
                          ? loc.comparisonSelectUniversityForA
                          : loc.comparisonSelectUniversityForB,
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
                  loading: () => const ListSkeleton(),
                  error: (e, _) => ErrorState(
                    message: AppLocalizations.of(context).commonError,
                    onRetry: () => ref.invalidate(allUniversitiesProvider),
                  ),
                  data: (unis) {
                    final otherId = isA ? selection.uniIdB : selection.uniIdA;
                    final filtered = unis
                        .where((u) => u.id != otherId)
                        .toList();
                    return ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final uni = filtered[i];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pop(modalContext);
                            final notifier = ref.read(
                              comparisonSelectionProvider.notifier,
                            );
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
                                        '${localizedUniversityType(loc, uni.type)} · ${localizedCampusLayout(loc, uni.campusLayout.name)}',
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              color: AppColors.textTertiaryFor(
                                                context,
                                              ),
                                              fontSize: 11,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textTertiaryFor(context),
                                ),
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
    final loc = AppLocalizations.of(context);
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
        emptyLabel: loc.commonLoading,
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
          subtitle: localizedUniversityType(loc, uni.type),
        );
      },
    );
  }
}
