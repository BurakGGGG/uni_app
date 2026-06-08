import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/university_providers.dart';
import '../../domain/models/department_model.dart';
import '../widgets/score_badge.dart';

/// Tüm bölümlerin tam listesi — /university/:uniId/departments
class UniDepartmentsScreen extends ConsumerStatefulWidget {
  final String universityId;

  const UniDepartmentsScreen({super.key, required this.universityId});

  @override
  ConsumerState<UniDepartmentsScreen> createState() =>
      _UniDepartmentsScreenState();
}

class _UniDepartmentsScreenState extends ConsumerState<UniDepartmentsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _normalizeTurkish(String input) {
    const from = 'çÇğĞıİöÖşŞüÜ';
    const to   = 'cCgGiIoOsSuU';
    var result = input;
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result.toLowerCase();
  }

  List<DepartmentModel> _filterDepartments(List<DepartmentModel> departments) {
    if (_searchQuery.isEmpty) return departments;
    final query = _normalizeTurkish(_searchQuery);
    return departments.where((d) =>
      _normalizeTurkish(d.name).contains(query) ||
      _normalizeTurkish(d.faculty).contains(query)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final deptsAsync =
        ref.watch(departmentsByUniversityProvider(widget.universityId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bölümler'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimaryFor(context),
              ),
              decoration: InputDecoration(
                hintText: 'Bölüm veya fakülte ara…',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiaryFor(context),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textTertiaryFor(context),
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textTertiaryFor(context),
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariantFor(context),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMd),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMd),
                  borderSide: BorderSide(
                    color: AppColors.borderLightFor(context),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMd),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: deptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Bölümler yüklenemedi: $e')),
        data: (departments) {
          if (departments.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('Henüz bölüm eklenmemiş'),
              ),
            );
          }

          final filtered = _filterDepartments(departments);

          // Sonuç sayısı
          final lisans =
              filtered.where((d) => d.type == 'Lisans').toList();
          final onlisans =
              filtered.where((d) => d.type == 'Önlisans').toList();

          return Column(
            children: [
              // Sonuç sayısı
              if (_searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filtered.length} bölüm bulundu',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiaryFor(context),
                      ),
                    ),
                  ),
                ),

              // ─── Bölüm Listesi ──────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: AppColors.textTertiaryFor(context),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '"$_searchQuery" ile eşleşen bölüm bulunamadı',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color:
                                      AppColors.textSecondaryFor(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildList(lisans, onlisans),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(
    List<DepartmentModel> lisans,
    List<DepartmentModel> onlisans,
  ) {
    final children = <Widget>[];
    if (lisans.isNotEmpty) {
      children.add(_SectionTitle(title: 'Lisans (${lisans.length})'));
      children.addAll(lisans.map((d) => _DepartmentCard(
            department: d,
            onTap: () => context.push('/department/${d.id}'),
          )));
    }
    if (onlisans.isNotEmpty) {
      children.add(_SectionTitle(title: 'Önlisans (${onlisans.length})'));
      children.addAll(onlisans.map((d) => _DepartmentCard(
            department: d,
            onTap: () => context.push('/department/${d.id}'),
          )));
    }
    children.add(const SizedBox(height: 80));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(title, style: AppTextStyles.labelMedium.copyWith(
        color: AppColors.textTertiaryFor(context), fontWeight: FontWeight.w600,
      )),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final DepartmentModel department;
  final VoidCallback onTap;

  const _DepartmentCard({required this.department, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasScoreData = department.scoreData != null;

    return RepaintBoundary(
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: AppColors.softShadowFor(context),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst satır: tip ikonu + ad + scoreType badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: (department.type == 'Lisans'
                                ? AppColors.primary
                                : AppColors.accent)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        department.type == 'Lisans'
                            ? Icons.school_rounded
                            : Icons.auto_stories_rounded,
                        color: department.type == 'Lisans'
                            ? AppColors.primary
                            : AppColors.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            department.name,
                            style: AppTextStyles.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${department.faculty} · ${department.duration} Yıl · ${department.language}',
                            style: AppTextStyles.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (hasScoreData)
                      ScoreBadge.scoreType(department.scoreData!.scoreType, small: true)
                    else if (department.scoreType != null)
                      ScoreBadge.scoreType(department.scoreType!, small: true),
                  ],
                ),

                // Alt satır: puan rozetleri
                if (hasScoreData) ...[
                  const SizedBox(height: 10),
                  Container(height: 1, color: AppColors.borderLightFor(context)),
                  const SizedBox(height: 8),
                  _buildScoreRow(department.scoreData!),
                ] else if (department.baseScore != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ScoreBadge.baseScore(department.baseScore!, small: true),
                      if (department.ranking != null) ...[
                        const SizedBox(width: 6),
                        ScoreBadge.ranking(department.ranking!, small: true),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildScoreRow(DepartmentScoreData scoreData) {
    final delta = scoreData.yearOverYearDelta;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ScoreBadge.baseScore(scoreData.baseScore, small: true),
        if (scoreData.ranking > 0)
          ScoreBadge.ranking(scoreData.ranking, small: true),
        ScoreBadge.quota(scoreData.placedCount, scoreData.quota, small: true),
        if (delta != null && delta.abs() > 0.01)
          ScoreBadge.delta(delta, small: true),
      ],
    );
  }
}
