import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/localized_labels.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../university/domain/models/department_model.dart';
import '../../../university/domain/models/university_model.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../../university/presentation/widgets/score_badge.dart';

class DepartmentPickResult {
  final UniversityModel university;
  final DepartmentModel department;
  const DepartmentPickResult({required this.university, required this.department});
}

/// Comparison flow için 2 aşamalı picker:
/// 1) Üniversite seç
/// 2) Bölüm seç (seçilen üniversiteye göre)
class DepartmentPickerBottomSheet {
  static Future<DepartmentPickResult?> show(
    BuildContext context, {
    String? departmentNameFilter,
    String? excludeUniversityId,
  }) {
    return showModalBottomSheet<DepartmentPickResult?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _Shell(
        departmentNameFilter: departmentNameFilter,
        excludeUniversityId: excludeUniversityId,
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  final String? departmentNameFilter;
  final String? excludeUniversityId;
  const _Shell({this.departmentNameFilter, this.excludeUniversityId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => _Body(
            scrollController: scrollController,
            departmentNameFilter: departmentNameFilter,
            excludeUniversityId: excludeUniversityId,
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final String? departmentNameFilter;
  final String? excludeUniversityId;
  const _Body({
    required this.scrollController,
    this.departmentNameFilter,
    this.excludeUniversityId,
  });

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  UniversityModel? _selectedUni;
  String _uniQuery = '';
  String _deptQuery = '';
  final _uniSearchCtrl = TextEditingController();
  final _deptSearchCtrl = TextEditingController();

  @override
  void dispose() {
    _uniSearchCtrl.dispose();
    _deptSearchCtrl.dispose();
    super.dispose();
  }

  void _resetToUniList() {
    setState(() {
      _selectedUni = null;
      _deptQuery = '';
      _deptSearchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 4),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderLightFor(context),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _selectedUni == null
                      ? Icons.close_rounded
                      : Icons.arrow_back_rounded,
                  color: AppColors.textPrimaryFor(context),
                ),
                onPressed: () {
                  if (_selectedUni == null) {
                    Navigator.pop(context);
                  } else {
                    _resetToUniList();
                  }
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedUni == null
                          ? loc.prefDeptSelectUniversity
                          : loc.prefDeptSelectDepartment,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (widget.departmentNameFilter != null && _selectedUni == null)
                      Text(
                        loc.prefDeptUniversitiesWithDepartment(
                          widget.departmentNameFilter!,
                        ),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondaryFor(context),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Selected uni strip (only on dept screen)
        if (_selectedUni != null) _SelectedUniStrip(uni: _selectedUni!),

        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _selectedUni == null
              ? AppSearchBar(
                  controller: _uniSearchCtrl,
                  hintText: loc.prefDeptSearchUniversity,
                  onChanged: (v) => setState(() => _uniQuery = v),
                  trailing: _uniQuery.isNotEmpty
                      ? _ClearBtn(onTap: () {
                          _uniSearchCtrl.clear();
                          setState(() => _uniQuery = '');
                        })
                      : null,
                )
              : AppSearchBar(
                  controller: _deptSearchCtrl,
                  hintText: loc.prefDeptSearchDepartment,
                  onChanged: (v) => setState(() => _deptQuery = v),
                  trailing: _deptQuery.isNotEmpty
                      ? _ClearBtn(onTap: () {
                          _deptSearchCtrl.clear();
                          setState(() => _deptQuery = '');
                        })
                      : null,
                ),
        ),

        Divider(height: 1, color: AppColors.borderLightFor(context)),

        Expanded(
          child: _selectedUni == null
              ? _UniList(
                  query: _uniQuery,
                  scrollController: widget.scrollController,
                  onSelect: (uni) => setState(() => _selectedUni = uni),
                  departmentNameFilter: widget.departmentNameFilter,
                  excludeUniversityId: widget.excludeUniversityId,
                )
              : _DeptList(
                  uni: _selectedUni!,
                  query: _deptQuery,
                  scrollController: widget.scrollController,
                  departmentNameFilter: widget.departmentNameFilter,
                ),
        ),
      ],
    );
  }
}

class _ClearBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _ClearBtn({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(Icons.close_rounded, size: 18, color: AppColors.textTertiaryFor(context)),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
    );
  }
}

class _SelectedUniStrip extends StatelessWidget {
  final UniversityModel uni;
  const _SelectedUniStrip({required this.uni});

  @override
  Widget build(BuildContext context) {
    final brand = uni.brandColor ?? AppColors.primary;
    final loc = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: brand.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: brand.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLightFor(context)),
            ),
            child: Image.asset(
              uni.logoAssetPath,
              fit: BoxFit.contain,
              semanticLabel: loc.semanticUniversityLogo,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.account_balance_rounded, color: brand, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  uni.name,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${localizedUniversityType(loc, uni.type)} • ${uni.establishedYear}',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondaryFor(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UniList extends ConsumerWidget {
  final String query;
  final ScrollController scrollController;
  final ValueChanged<UniversityModel> onSelect;
  final String? departmentNameFilter;
  final String? excludeUniversityId;
  const _UniList({
    required this.query,
    required this.scrollController,
    required this.onSelect,
    this.departmentNameFilter,
    this.excludeUniversityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final unisAsync = ref.watch(allUniversitiesProvider);
    return unisAsync.when(
      loading: () => const _PickerSkeleton(isUniList: true),
      error: (e, _) => ErrorStateWidget(message: loc.commonError),
      data: (unis) {
        // Zaten seçili üniversiteyi hariç tut
        var pool = excludeUniversityId != null
            ? unis.where((u) => u.id != excludeUniversityId).toList()
            : unis;
        final q = query.trim().toLowerCase();
        var filtered = q.isEmpty
            ? pool
            : pool
                .where((u) =>
                    u.name.toLowerCase().contains(q) ||
                    u.aliases.any((a) => a.toLowerCase().contains(q)))
                .toList();

        // Bölüm adı filtresi: sadece bu bölüme sahip üniversiteleri göster
        if (departmentNameFilter != null && departmentNameFilter!.isNotEmpty) {
          final filterName = departmentNameFilter!.toLowerCase();
          final filteredByDept = <UniversityModel>[];
          bool anyLoading = false;

          for (final uni in filtered) {
            final deptsAsync = ref.watch(departmentsByUniversityProvider(uni.id));
            if (deptsAsync.isLoading) {
              anyLoading = true;
            }
            final hasDept = deptsAsync.whenOrNull(
              data: (depts) => depts.any(
                (d) => d.name.toLowerCase() == filterName,
              ),
            );
            if (hasDept == true) {
              filteredByDept.add(uni);
            }
          }
          
          if (anyLoading && filteredByDept.isEmpty) {
            return const _PickerSkeleton(isUniList: true);
          }
          
          filtered = filteredByDept;
        }

        if (filtered.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.search_off_rounded,
            title: departmentNameFilter != null
                ? loc.prefDeptNoUniversityForDepartment
                : loc.prefNoSearchResults,
            description: departmentNameFilter != null
                ? loc.prefDeptNoOtherUniversityForDepartment(
                    departmentNameFilter!,
                  )
                : loc.prefNoSearchResultsDesc,
          );
        }
        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _UniTile(
            uni: filtered[i],
            onTap: () => onSelect(filtered[i]),
          ),
        );
      },
    );
  }
}

class _UniTile extends StatelessWidget {
  final UniversityModel uni;
  final VoidCallback onTap;
  const _UniTile({required this.uni, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brand = uni.brandColor ?? AppColors.primary;
    final loc = AppLocalizations.of(context);
    return Material(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLightFor(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: brand,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantFor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  uni.logoAssetPath,
                  fit: BoxFit.contain,
                  semanticLabel: loc.semanticUniversityLogo,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.account_balance_rounded, color: brand, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uni.name,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${localizedUniversityType(loc, uni.type)} • ${uni.establishedYear}',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondaryFor(context)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryFor(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeptList extends ConsumerWidget {
  final UniversityModel uni;
  final String query;
  final ScrollController scrollController;
  final String? departmentNameFilter;
  const _DeptList({
    required this.uni,
    required this.query,
    required this.scrollController,
    this.departmentNameFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final deptsAsync = ref.watch(departmentsByUniversityProvider(uni.id));
    return deptsAsync.when(
      loading: () => const _PickerSkeleton(isUniList: false),
      error: (e, _) => ErrorStateWidget(message: loc.errorDepartmentsLoad),
      data: (depts) {
        if (depts.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.school_outlined,
            title: loc.prefNoDepartmentsTitle,
            description: loc.prefNoDepartmentsDesc,
          );
        }

        var list = [...depts]..sort((a, b) {
          final ba = a.baseScore ?? a.scoreData?.baseScore ?? 0;
          final bb = b.baseScore ?? b.scoreData?.baseScore ?? 0;
          if (ba != bb) return bb.compareTo(ba);
          return a.name.compareTo(b.name);
        });

        // Bölüm adı filtresi: sadece eşleşen bölümleri göster
        if (departmentNameFilter != null && departmentNameFilter!.isNotEmpty) {
          final filterName = departmentNameFilter!.toLowerCase();
          list = list.where((d) => d.name.toLowerCase() == filterName).toList();
        }

        final q = query.trim().toLowerCase();
        final filtered = q.isEmpty
            ? list
            : list
                .where((d) =>
                    d.name.toLowerCase().contains(q) ||
                    d.faculty.toLowerCase().contains(q))
                .toList();

        if (filtered.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.search_off_rounded,
            title: loc.prefNoSearchResults,
            description: loc.prefNoSearchResultsDesc,
          );
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _DeptCard(
            uni: uni,
            dept: filtered[i],
            onTap: () => Navigator.pop(
              context,
              DepartmentPickResult(university: uni, department: filtered[i]),
            ),
          ),
        );
      },
    );
  }
}

class _DeptCard extends StatelessWidget {
  final UniversityModel uni;
  final DepartmentModel dept;
  final VoidCallback onTap;
  const _DeptCard({required this.uni, required this.dept, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brand = uni.brandColor ?? AppColors.primary;
    final loc = AppLocalizations.of(context);
    final score = dept.scoreData;
    final baseScore = score?.baseScore ?? dept.baseScore;
    final ranking = score?.ranking ?? dept.ranking;
    final quota = score?.quota ?? dept.quota;
    final placed = score?.placedCount;
    final scoreType = score?.scoreType ?? dept.scoreType;

    return Material(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLightFor(context)),
            color: AppColors.surfaceFor(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 38,
                    decoration: BoxDecoration(
                      color: brand,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dept.name,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dept.faculty,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondaryFor(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (scoreType != null && scoreType.isNotEmpty)
                    ScoreBadge.scoreType(scoreType),
                ],
              ),
              if (baseScore != null && baseScore > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: loc.prefBaseScoreShort,
                        value: baseScore.toStringAsFixed(2),
                        icon: Icons.trending_up_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    if (ranking != null && ranking > 0) ...[
                      Container(width: 1, height: 28, color: AppColors.borderLightFor(context)),
                      Expanded(
                        child: _Stat(
                          label: loc.ranking,
                          value: _formatRank(ranking),
                          icon: Icons.emoji_events_rounded,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                    if (quota != null && quota > 0) ...[
                      Container(width: 1, height: 28, color: AppColors.borderLightFor(context)),
                      Expanded(
                        child: _Stat(
                          label: loc.quota,
                          value: placed != null ? '$placed/$quota' : '$quota',
                          icon: Icons.people_alt_rounded,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatRank(int rank) {
    if (rank >= 1000000) return '${(rank / 1000000).toStringAsFixed(1)}M';
    if (rank >= 1000) return '${(rank / 1000).toStringAsFixed(0)}B';
    return '$rank';
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryFor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Picker yükleme sırasında gösterilen iskelet animasyonu.
class _PickerSkeleton extends StatefulWidget {
  final bool isUniList;
  const _PickerSkeleton({required this.isUniList});

  @override
  State<_PickerSkeleton> createState() => _PickerSkeletonState();
}

class _PickerSkeletonState extends State<_PickerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = widget.isUniList ? 8 : 6;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final shimmer = _ctrl.value;
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: count,
          separatorBuilder: (_, i) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            return Container(
              height: widget.isUniList ? 68 : 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment(-1.0 + 2.0 * shimmer, 0),
                  end: Alignment(-0.5 + 2.0 * shimmer, 0),
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.04),
                          Colors.white.withValues(alpha: 0.10),
                          Colors.white.withValues(alpha: 0.04),
                        ]
                      : [
                          Colors.grey.shade200,
                          Colors.grey.shade100,
                          Colors.grey.shade200,
                        ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
