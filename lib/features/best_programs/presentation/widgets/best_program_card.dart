import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/city_helper.dart';
import '../../../preference_wizard/presentation/widgets/feasibility_chip.dart';
import '../../../university/domain/models/department_model.dart';
import '../../../university/presentation/widgets/score_badge.dart';
import '../../domain/best_programs_engine.dart';

/// Sıralı listedeki tek program kartı.
///
/// `WizardRecommendationCard`'ın profil-bağımlı parçaları (fit metresi,
/// eşleşme gerekçesi) yok — bu liste profilsiz de çalışır. Profil varsa
/// [FeasibilityChip] uygulamanın geri kalanıyla aynı rozeti gösterir.
class BestProgramCard extends StatelessWidget {
  final RankedProgram program;

  /// Bölüm adı listede tekrar ediyorsa (tek bölümün üniversiteleri) gizlenir.
  final bool showDepartmentName;

  const BestProgramCard({
    super.key,
    required this.program,
    this.showDepartmentName = true,
  });

  @override
  Widget build(BuildContext context) {
    final dept = program.department;
    final uni = program.university;
    final medal = _medalColor(program.position);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: AppColors.softShadowFor(context),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push('/department/${dept.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _positionBadge(context, medal),
                    const SizedBox(width: 12),
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.borderLightFor(context)),
                      ),
                      child: Image.asset(
                        uni.logoAssetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.school, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDepartmentName) ...[
                            Text(
                              dept.name,
                              style: AppTextStyles.titleSmall
                                  .copyWith(fontWeight: FontWeight.w800),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            uni.name,
                            style: showDepartmentName
                                ? AppTextStyles.bodySmall.copyWith(
                                    color:
                                        AppColors.textSecondaryFor(context))
                                : AppTextStyles.titleSmall
                                    .copyWith(fontWeight: FontWeight.w800),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${CityHelper.getCityName(uni.cityId)} · ${uni.type}'
                            '${dept.type == 'Önlisans' ? ' · Önlisans' : ''}',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textTertiaryFor(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (dept.effectiveScoreType != null)
                      ScoreBadge.scoreType(dept.effectiveScoreType!,
                          small: true),
                    if (program.reference != null)
                      ScoreBadge.ranking(program.reference!.rank, small: true),
                    if (dept.effectiveBaseScore > 0)
                      ScoreBadge.baseScore(dept.effectiveBaseScore,
                          small: true),
                    for (final tag in _tags(context))
                      _tagChip(context, tag.$1, tag.$2),
                    FeasibilityChip.forDepartment(dept, compact: true),
                  ],
                ),
                if (program.referenceIsStale) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${program.reference!.year} sırası — bu programın '
                    '2025 verisi yok.',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textTertiaryFor(context)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Kart etiketleri: burs ve öğretim dili `description` alanından okunur.
  List<(String, Color)> _tags(BuildContext context) {
    final tags = <(String, Color)>[];
    final dept = program.department;
    if (BestProgramsEngine.isScholarship(dept)) {
      tags.add(('Burslu', AppColors.success));
    }
    if (dept.language != 'Türkçe') {
      tags.add((dept.language, AppColors.info));
    }
    if (BestProgramsEngine.isDistanceLearning(dept)) {
      tags.add(('Uzaktan', AppColors.warning));
    }
    return tags;
  }

  Widget _tagChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall
            .copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _positionBadge(BuildContext context, Color? medal) {
    final color = medal ?? AppColors.textSecondaryFor(context);
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: medal == null ? 0.08 : 0.16),
        borderRadius: BorderRadius.circular(10),
        border: medal == null
            ? null
            : Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '${program.position}',
        style: AppTextStyles.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static Color? _medalColor(int position) {
    switch (position) {
      case 1:
        return const Color(0xFFD4AF37); // altın
      case 2:
        return const Color(0xFF9CA3AF); // gümüş
      case 3:
        return const Color(0xFFB45309); // bronz
      default:
        return null;
    }
  }
}
