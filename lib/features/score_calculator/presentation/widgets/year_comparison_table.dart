import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/score_calculator_providers.dart';
import 'score_type_card.dart';

/// Yıl karşılaştırması: aynı netler, seçili türde 2022–2026 puan + sıra.
/// Her yılın puanı o yılın katsayılarıyla, sırası o yılın resmî ÖSYM
/// dağılımıyla hesaplanır.
///
/// Sıra modunda soru tersine döner — sabit olan sıradır, her yıl için o
/// sıranın kaç puana denk geldiği gösterilir.
class YearComparisonTable extends ConsumerWidget {
  final String scoreType;

  const YearComparisonTable({super.key, required this.scoreType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(yearComparisonProvider(scoreType));
    final rankMode = ref.watch(scoreInputProvider).isRankMode;

    return rowsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (rows) {
        if (rows.isEmpty) return const SizedBox.shrink();
        final hasProxy = rows.any((r) => r.rankIsProxy);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLightFor(context)),
            boxShadow: AppColors.softShadowFor(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerRow(context, rankMode),
              const SizedBox(height: 4),
              for (final row in rows) ...[
                Divider(height: 1, color: AppColors.borderLightFor(context)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: Row(
                          children: [
                            Text(
                              '${row.year}',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (row.rankIsProxy)
                              Text(
                                '*',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textTertiaryFor(context),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row.placementScore.toStringAsFixed(2),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scoreTypeColor(scoreType),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row.estimatedRank != null
                              ? '${rankMode ? '' : '~'}'
                                  '${formatRank(row.estimatedRank!)}'
                              : '—',
                          textAlign: TextAlign.right,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (hasProxy) ...[
                const SizedBox(height: 8),
                Text(
                  '* 2026 dağılımı henüz açıklanmadı; sıra 2025 verisine göre '
                  'tahminidir.',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textTertiaryFor(context)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _headerRow(BuildContext context, bool rankMode) {
    final style = AppTextStyles.labelSmall.copyWith(
      color: AppColors.textSecondaryFor(context),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 64, child: Text('YIL', style: style)),
          Expanded(
              child: Text(rankMode ? 'O YILKİ PUAN' : 'PUAN',
                  textAlign: TextAlign.center, style: style)),
          Expanded(
              child: Text(rankMode ? 'SIRA' : 'TAHMİNİ SIRA',
                  textAlign: TextAlign.right, style: style)),
        ],
      ),
    );
  }
}
