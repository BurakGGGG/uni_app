import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/practice_exam_analytics.dart';

/// Ders bazında güçlü / zayıf analizi.
///
/// Karşılaştırma **başarı oranıyla** yapılır (`net / soru sayısı`); ham net
/// kullanılsaydı 40 soruluk Türkçe her zaman 13 soruluk Kimya'yı ezerdi.
class SubjectStrengthPanel extends StatelessWidget {
  final List<SubjectStat> stats;

  /// Defterde hiç netli deneme yoksa panel yerine yönlendirme gösterilir.
  final bool hasNetExams;

  const SubjectStrengthPanel({
    super.key,
    required this.stats,
    required this.hasNetExams,
  });

  static const int _showCount = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Derslerin',
                style: AppTextStyles.titleSmall
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasNetExams)
            _hint(
              context,
              'Ders analizi için netlerini gir. Yalnız puan veya sıra girilen '
              'denemelerde ders kırılımı olmuyor.',
            )
          else if (stats.isEmpty)
            _hint(context, 'Henüz analiz için yeterli veri yok.')
          else ...[
            _group(
              context,
              title: 'Güçlü olduğun dersler',
              color: AppColors.success,
              items: stats.take(_showCount).toList(),
            ),
            if (stats.length > _showCount) ...[
              const SizedBox(height: 16),
              _group(
                context,
                title: 'Geliştirmen gerekenler',
                color: AppColors.error,
                items: stats.reversed.take(_showCount).toList().reversed
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Son ${stats.first.sampleSize} denemenin ortalaması.',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textTertiaryFor(context)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _hint(BuildContext context, String text) {
    return Text(
      text,
      style: AppTextStyles.bodySmall
          .copyWith(color: AppColors.textSecondaryFor(context)),
    );
  }

  Widget _group(
    BuildContext context, {
    required String title,
    required Color color,
    required List<SubjectStat> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final stat in items) _row(context, stat, color),
      ],
    );
  }

  Widget _row(BuildContext context, SubjectStat stat, Color color) {
    final delta = stat.delta;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.subject.labelTr,
                  style: AppTextStyles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${stat.avgNet.toStringAsFixed(1).replaceAll('.', ',')}'
                ' / ${stat.subject.maxQuestions}',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
              if (delta != null && delta.abs() >= 0.05) ...[
                const SizedBox(width: 6),
                Icon(
                  delta > 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: delta > 0 ? AppColors.success : AppColors.error,
                ),
                Text(
                  delta.abs().toStringAsFixed(1).replaceAll('.', ','),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: delta > 0 ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stat.successRate,
              minHeight: 6,
              backgroundColor: AppColors.surfaceVariantFor(context),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
