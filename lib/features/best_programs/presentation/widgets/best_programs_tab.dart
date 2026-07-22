import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../university/presentation/widgets/score_badge.dart';
import '../../domain/best_programs_engine.dart';
import '../../domain/program_category.dart';
import '../providers/best_programs_providers.dart';
import 'best_programs_filter_sheet.dart';

/// Keşfet → "Bölümler" sekmesi: alan seç → bölüm seç → sıralı liste.
///
/// Uygulamada bölüm araması ilk kez burada var; arama kutusu 214 bölüm adı
/// üzerinde çalışır (üniversite araması Keşfet'in ilk sekmesinde kalır).
class BestProgramsTab extends ConsumerStatefulWidget {
  const BestProgramsTab({super.key});

  @override
  ConsumerState<BestProgramsTab> createState() => _BestProgramsTabState();
}

class _BestProgramsTabState extends ConsumerState<BestProgramsTab> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _term = '';
  String _categoryKey = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _term = value);
    });
  }

  void _openDepartment(String name) {
    context.push('/best-programs?dept=${Uri.encodeComponent(name)}');
  }

  @override
  Widget build(BuildContext context) {
    final searching = _term.trim().length >= 2;
    final query = ref.watch(bestProgramsQueryProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: AppSearchBar(
                    controller: _searchController,
                    hintText: 'Bölüm ara (ör. Tıp, Bilgisayar)',
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 8),
                _FilterButton(
                  count: query.activeFilterCount,
                  onTap: () => BestProgramsFilterSheet.show(context),
                ),
              ],
            ),
          ),
        ),
        if (!searching)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: _CategoryChips(
                selected: _categoryKey,
                onSelect: (key) => setState(() => _categoryKey = key),
              ),
            ),
          ),
        if (searching)
          _SearchResults(term: _term, onTap: _openDepartment)
        else
          _DepartmentList(
            categoryKey: _categoryKey,
            onTap: _openDepartment,
            onSeeCategory: _categoryKey.isEmpty
                ? null
                : () => context.push('/best-programs?category=$_categoryKey'),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _FilterButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: count > 0
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceVariantFor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: count > 0
                ? AppColors.primary
                : AppColors.borderLightFor(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded,
                size: 20,
                color: count > 0
                    ? AppColors.primary
                    : AppColors.textSecondaryFor(context)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text('$count',
                  style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(categoryCountsProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(context, '', 'Tümü', null),
        for (final category in programCategories)
          _chip(
            context,
            category.key,
            category.label,
            counts.valueOrNull?[category.key],
          ),
      ],
    );
  }

  Widget _chip(BuildContext context, String key, String label, int? count) {
    final isSelected = selected == key;
    return GestureDetector(
      onTap: () => onSelect(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceVariantFor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.borderLightFor(context),
          ),
        ),
        child: Text(
          count == null ? label : '$label · $count',
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected
                ? AppColors.primary
                : AppColors.textPrimaryFor(context),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DepartmentList extends ConsumerWidget {
  final String categoryKey;
  final ValueChanged<String> onTap;
  final VoidCallback? onSeeCategory;

  const _DepartmentList({
    required this.categoryKey,
    required this.onTap,
    required this.onSeeCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(departmentsInCategoryProvider(categoryKey));

    return async.when(
      loading: () => const SliverToBoxAdapter(child: ListSkeleton()),
      error: (e, _) => SliverToBoxAdapter(
        child: ErrorState(
          message: 'Bölümler yüklenemedi',
          onRetry: () =>
              ref.invalidate(departmentsInCategoryProvider(categoryKey)),
        ),
      ),
      data: (departments) {
        if (departments.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Bu alanda program bulunamadı.')),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: departments.length + (onSeeCategory == null ? 0 : 1),
            itemBuilder: (context, index) {
              if (onSeeCategory != null && index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: onSeeCategory,
                    icon: const Icon(Icons.emoji_events_rounded, size: 18),
                    label: const Text('Bu alanın tüm programlarını sırala'),
                  ),
                );
              }
              final dept =
                  departments[index - (onSeeCategory == null ? 0 : 1)];
              return _DepartmentTile(summary: dept, onTap: onTap);
            },
          ),
        );
      },
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final String term;
  final ValueChanged<String> onTap;

  const _SearchResults({required this.term, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(departmentSearchProvider(term));

    return async.when(
      loading: () => const SliverToBoxAdapter(child: ListSkeleton()),
      error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (results) {
        if (results.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  '"$term" ile eşleşen bölüm bulunamadı.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondaryFor(context)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: results.length,
            itemBuilder: (context, index) =>
                _DepartmentTile(summary: results[index], onTap: onTap),
          ),
        );
      },
    );
  }
}

class _DepartmentTile extends StatelessWidget {
  final DepartmentSummary summary;
  final ValueChanged<String> onTap;

  const _DepartmentTile({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => onTap(summary.name),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.name,
                        style: AppTextStyles.titleSmall
                            .copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${summary.programCount} program'
                        '${summary.bestRank != null ? ' · en iyi ${summary.bestRank}. sıra' : ''}',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondaryFor(context)),
                      ),
                    ],
                  ),
                ),
                if (summary.scoreType != null)
                  ScoreBadge.scoreType(summary.scoreType!, small: true),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiaryFor(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
