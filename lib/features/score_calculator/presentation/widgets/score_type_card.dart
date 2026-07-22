import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/multi_score_result.dart';

/// Binlik ayraçlı sıra formatı: 85600 → "85.600".
String formatRank(int rank) {
  final digits = rank.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Yüzdelik dilim formatı: 6.63 → "İlk %6,6", 0.4 → "İlk %0,4".
String formatPercentile(double percentile) {
  final rounded = percentile >= 10
      ? percentile.toStringAsFixed(0)
      : percentile.toStringAsFixed(1);
  return 'İlk %${rounded.replaceAll('.', ',')}';
}

/// Puan türü renkleri — kartlar ve tür seçici çipler aynı dili konuşur.
Color scoreTypeColor(String scoreType) {
  switch (scoreType) {
    case 'TYT':
      return AppColors.primary;
    case 'SAY':
      return const Color(0xFF2563EB); // mavi
    case 'EA':
      return const Color(0xFF059669); // yeşil
    case 'SÖZ':
      return const Color(0xFFD97706); // turuncu
    case 'DİL':
      return const Color(0xFF7C3AED); // mor
    default:
      return AppColors.primary;
  }
}

/// Tek puan türünün sonucu: yerleştirme puanı + ham/OBP + sıra + dilim.
class ScoreTypeCard extends StatelessWidget {
  final ScoreTypeOutcome outcome;
  final bool isBest;

  const ScoreTypeCard({
    super.key,
    required this.outcome,
    this.isBest = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = scoreTypeColor(outcome.score.scoreType);
    final score = outcome.score;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBest
              ? color.withValues(alpha: 0.5)
              : AppColors.borderLightFor(context),
          width: isBest ? 1.5 : 1,
        ),
        boxShadow: AppColors.softShadowFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  score.scoreType,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isBest)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text(
                        'En güçlü türün',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Text(
                score.placementScore.toStringAsFixed(3),
                style: AppTextStyles.headlineSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _detail(context, 'Ham', score.rawScore.toStringAsFixed(2)),
              _detail(context, 'OBP',
                  '+${(score.placementScore - score.rawScore).toStringAsFixed(1)}'),
              if (score.extraPlacementScore != null)
                _detail(context, 'Ek puanlı (kendi alanında)',
                    score.extraPlacementScore!.toStringAsFixed(2)),
            ],
          ),
          if (outcome.estimatedRank != null) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: AppColors.borderLightFor(context)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.leaderboard_rounded,
                    size: 18, color: AppColors.textSecondaryFor(context)),
                const SizedBox(width: 8),
                Text(
                  outcome.rankIsUserEntered
                      ? 'Başarı sıran'
                      : 'Tahmini başarı sırası',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondaryFor(context)),
                ),
                const Spacer(),
                Text(
                  outcome.rankIsUserEntered
                      ? formatRank(outcome.estimatedRank!)
                      : '~${formatRank(outcome.estimatedRank!)}',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
              ],
            ),
            if (outcome.percentile != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.donut_small_rounded,
                      size: 18, color: AppColors.textSecondaryFor(context)),
                  const SizedBox(width: 8),
                  Text(
                    'Yüzdelik dilim',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondaryFor(context)),
                  ),
                  const Spacer(),
                  Text(
                    formatPercentile(outcome.percentile!),
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryFor(context),
                    ),
                  ),
                ],
              ),
            ],
            if (outcome.rankIsProxy) ...[
              const SizedBox(height: 8),
              Text(
                outcome.rankIsUserEntered
                    // Sıra modunda belirsizlik sırada değil PUANDA: sıra
                    // kullanıcının verisi, puan tablodan türetildi.
                    ? 'Puan, ÖSYM ${outcome.rankCurveYear} dağılımından '
                        'türetildi — ${score.year} verileri henüz açıklanmadı.'
                    : 'ÖSYM ${outcome.rankCurveYear} dağılımına göre tahmini — '
                        '${score.year} verileri henüz açıklanmadı.',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textTertiaryFor(context)),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _detail(BuildContext context, String label, String value) {
    return Text.rich(
      TextSpan(
        text: '$label: ',
        style: AppTextStyles.bodySmall
            .copyWith(color: AppColors.textSecondaryFor(context)),
        children: [
          TextSpan(
            text: value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
