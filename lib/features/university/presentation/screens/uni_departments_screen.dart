import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/university_providers.dart';
import '../../domain/models/department_model.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: (department.type == 'Lisans' ? AppColors.primary : AppColors.accent)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  department.type == 'Lisans' ? Icons.school_rounded : Icons.auto_stories_rounded,
                  color: department.type == 'Lisans' ? AppColors.primary : AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(department.name, style: AppTextStyles.titleSmall,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${department.faculty} • ${department.language}',
                    style: AppTextStyles.labelSmall,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )),
              if (department.baseScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(department.baseScore!.toStringAsFixed(1),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}
