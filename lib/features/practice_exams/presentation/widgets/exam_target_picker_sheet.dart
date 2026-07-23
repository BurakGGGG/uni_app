import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../score_calculator/presentation/providers/score_calculator_providers.dart';
import '../../../score_calculator/presentation/widgets/score_type_card.dart';
import '../../../university/domain/models/department_model.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../domain/models/exam_target.dart';

/// Seçilen bölüm adındaki programlar arasından hedef programı seçtirir.
///
/// Hedef sırası/puanı elle yazılmaz — programın taban verisinden
/// (`rankingForMatching` / `effectiveBaseScore`) türetilir, böylece hedef
/// uygulamadaki gerçek verilerle bağlantılı kalır.
class ExamTargetPickerSheet extends ConsumerWidget {
  final String departmentName;

  const ExamTargetPickerSheet({super.key, required this.departmentName});

  static Future<ExamTarget?> show(
    BuildContext context, {
    required String departmentName,
  }) {
    return showModalBottomSheet<ExamTarget>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExamTargetPickerSheet(departmentName: departmentName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(allScoredDepartmentsProvider);
    final unisAsync = ref.watch(allUniversitiesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLightFor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      departmentName,
                      style: AppTextStyles.titleLarge
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hedeflediğin üniversiteyi seç — o programın 2025 tabanı '
                      'hedef çizgin olur.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: (deptsAsync.isLoading || unisAsync.isLoading)
                    ? const Center(child: CircularProgressIndicator())
                    : _buildList(
                        context,
                        scrollController,
                        deptsAsync.valueOrNull ?? const [],
                        {
                          for (final u in unisAsync.valueOrNull ?? const [])
                            u.id: u.name,
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    ScrollController controller,
    List<DepartmentModel> allDepts,
    Map<String, String> uniNames,
  ) {
    final wanted = departmentName.toLowerCase().trim();
    final matches = [
      for (final d in allDepts)
        if (d.name.toLowerCase().trim() == wanted) d,
    ];
    // En iyi program başta: taban sırası küçük olan üstte.
    matches.sort((a, b) {
      final ra = a.rankingForMatching;
      final rb = b.rankingForMatching;
      if (ra == null && rb == null) {
        return b.effectiveBaseScore.compareTo(a.effectiveBaseScore);
      }
      if (ra == null) return 1;
      if (rb == null) return -1;
      return ra.compareTo(rb);
    });

    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Bu bölüm için taban verisi bulunamadı.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondaryFor(context)),
          ),
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final dept = matches[index];
        final uniName = uniNames[dept.universityId] ?? 'Üniversite';
        final rank = dept.rankingForMatching;
        final type = dept.effectiveScoreType ?? '';

        return ListTile(
          title: Text(
            uniName,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            [
              if (type.isNotEmpty) type,
              if (rank != null) '${formatRank(rank)}. sıra',
              '${dept.effectiveBaseScore.toStringAsFixed(1)} puan',
            ].join(' · '),
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textSecondaryFor(context)),
          ),
          trailing: const Icon(Icons.flag_rounded, size: 20),
          onTap: () => Navigator.pop(
            context,
            ExamTarget(
              departmentId: dept.id,
              departmentName: dept.name,
              universityName: uniName,
              scoreType: type.toUpperCase(),
              targetRank: rank,
              targetScore: dept.effectiveBaseScore,
              setAt: DateTime.now(),
            ),
          ),
        );
      },
    );
  }
}
