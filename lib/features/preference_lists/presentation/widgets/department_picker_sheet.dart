import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../../university/domain/models/university_model.dart';
import '../../../university/domain/models/department_model.dart';
import '../../../university/presentation/widgets/score_badge.dart';
import '../../domain/models/preference_list_model.dart';

class DepartmentPickerSheet {
  static Future<PreferenceItem?> show(BuildContext context) {
    return showModalBottomSheet<PreferenceItem?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => _Body(scrollController: scrollController),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const _Body({required this.scrollController});

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
    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 4),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderLight,
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
                  color: AppColors.textPrimary,
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
                child: Text(
                  _selectedUni == null ? 'Üniversite Seç' : 'Bölüm Seç',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
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
                  hintText: 'Üniversite ara…',
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
                  hintText: 'Bölüm ara…',
                  onChanged: (v) => setState(() => _deptQuery = v),
                  trailing: _deptQuery.isNotEmpty
                      ? _ClearBtn(onTap: () {
                          _deptSearchCtrl.clear();
                          setState(() => _deptQuery = '');
                        })
                      : null,
                ),
        ),

        const Divider(height: 1, color: AppColors.borderLight),

        Expanded(
          child: _selectedUni == null
              ? _UniList(
                  query: _uniQuery,
                  scrollController: widget.scrollController,
                  onSelect: (uni) => setState(() => _selectedUni = uni),
                )
              : _DeptList(
                  uni: _selectedUni!,
                  query: _deptQuery,
                  scrollController: widget.scrollController,
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
      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textTertiary),
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Image.asset(
              uni.logoAssetPath,
              fit: BoxFit.contain,
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
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${uni.type} • ${uni.establishedYear}',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textSecondary),
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
  const _UniList({
    required this.query,
    required this.scrollController,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unisAsync = ref.watch(allUniversitiesProvider);
    return unisAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Hata: $e')),
      data: (unis) {
        final q = query.trim().toLowerCase();
        final filtered = q.isEmpty
            ? unis
            : unis.where((u) =>
                u.name.toLowerCase().contains(q) ||
                u.aliases.any((a) => a.toLowerCase().contains(q))).toList();
        if (filtered.isEmpty) {
          return _Empty(
            icon: Icons.search_off_rounded,
            title: 'Sonuç bulunamadı',
            subtitle: 'Farklı bir arama deneyebilirsin.',
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
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
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
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  uni.logoAssetPath,
                  fit: BoxFit.contain,
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
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${uni.type} • ${uni.establishedYear}',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
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
  const _DeptList({
    required this.uni,
    required this.query,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(departmentsByUniversityProvider(uni.id));

    return deptsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Hata: $e')),
      data: (depts) {
        if (depts.isEmpty) {
          return _Empty(
            icon: Icons.school_outlined,
            title: 'Bölüm bulunamadı',
            subtitle: 'Bu üniversite için kayıtlı bölüm yok.',
          );
        }

        // Sort: önce baseScore (varsa) yüksekten düşüğe, yoksa isim
        final list = [...depts]..sort((a, b) {
          final ba = a.baseScore ?? a.scoreData?.baseScore ?? 0;
          final bb = b.baseScore ?? b.scoreData?.baseScore ?? 0;
          if (ba != bb) return bb.compareTo(ba);
          return a.name.compareTo(b.name);
        });

        final q = query.trim().toLowerCase();
        final filtered = q.isEmpty
            ? list
            : list
                .where((d) =>
                    d.name.toLowerCase().contains(q) ||
                    d.faculty.toLowerCase().contains(q))
                .toList();

        if (filtered.isEmpty) {
          return _Empty(
            icon: Icons.search_off_rounded,
            title: 'Sonuç bulunamadı',
            subtitle: 'Farklı bir arama deneyebilirsin.',
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
              _buildPreferenceItem(uni, filtered[i]),
            ),
          ),
        );
      },
    );
  }
}

PreferenceItem _buildPreferenceItem(UniversityModel uni, DepartmentModel dept) {
  final score = dept.scoreData;
  return PreferenceItem(
    deptId: dept.id,
    uniId: uni.id,
    order: 0,
    deptName: dept.name,
    uniName: uni.name,
    uniLogoUrl: uni.logoAssetPath,
    faculty: dept.faculty,
    deptType: dept.type,
    language: dept.language,
    scoreType: score?.scoreType ?? dept.scoreType,
    baseScore: score?.baseScore ?? dept.baseScore,
    ranking: score?.ranking ?? dept.ranking,
    quota: score?.quota ?? dept.quota,
    placedCount: score?.placedCount,
    uniBrandHex: uni.brandPrimaryHex,
  );
}

class _DeptCard extends StatelessWidget {
  final UniversityModel uni;
  final DepartmentModel dept;
  final VoidCallback onTap;
  const _DeptCard({required this.uni, required this.dept, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brand = uni.brandColor ?? AppColors.primary;
    final score = dept.scoreData;
    final baseScore = score?.baseScore ?? dept.baseScore;
    final ranking = score?.ranking ?? dept.ranking;
    final quota = score?.quota ?? dept.quota;
    final placed = score?.placedCount;
    final scoreType = score?.scoreType ?? dept.scoreType;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            color: AppColors.surface,
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
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (scoreType != null) ScoreBadge.scoreType(scoreType),
                ],
              ),
              if (baseScore != null && baseScore > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'Taban',
                        value: baseScore.toStringAsFixed(2),
                        icon: Icons.trending_up_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    if (ranking != null && ranking > 0) ...[
                      Container(
                        width: 1,
                        height: 28,
                        color: AppColors.borderLight,
                      ),
                      Expanded(
                        child: _Stat(
                          label: 'Sıralama',
                          value: _formatRank(ranking),
                          icon: Icons.emoji_events_rounded,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                    if (quota != null && quota > 0) ...[
                      Container(
                        width: 1,
                        height: 28,
                        color: AppColors.borderLight,
                      ),
                      Expanded(
                        child: _Stat(
                          label: 'Kontenjan',
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
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Empty({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
