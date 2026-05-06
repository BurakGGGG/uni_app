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
class UniDepartmentsScreen extends ConsumerWidget {
  final String universityId;

  const UniDepartmentsScreen({super.key, required this.universityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(departmentsByUniversityProvider(universityId));

    return Scaffold(
      appBar: AppBar(title: const Text('Bölümler')),
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

          final lisans = departments.where((d) => d.type == 'Lisans').toList();
          final onlisans = departments.where((d) => d.type == 'Önlisans').toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              if (lisans.isNotEmpty) ...[
                _SectionTitle(title: 'Lisans (${lisans.length})'),
                ...lisans.asMap().entries.map((e) => _DepartmentCard(
                  department: e.value,
                  onTap: () => context.push('/department/${e.value.id}'),
                )),
              ],
              if (onlisans.isNotEmpty) ...[
                _SectionTitle(title: 'Önlisans (${onlisans.length})'),
                ...onlisans.asMap().entries.map((e) => _DepartmentCard(
                  department: e.value,
                  onTap: () => context.push('/department/${e.value.id}'),
                )),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
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
        color: AppColors.textTertiary, fontWeight: FontWeight.w600,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
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
                  Container(height: 1, color: AppColors.borderLight),
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
        ScoreBadge.ranking(scoreData.ranking, small: true),
        ScoreBadge.quota(scoreData.placedCount, scoreData.quota, small: true),
        if (delta != null && delta.abs() > 0.01)
          ScoreBadge.delta(delta, small: true),
      ],
    );
  }
}
