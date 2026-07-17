import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/match_reason.dart';

/// Sonuç ekranı özet başlığı: puan/sıralama pilleri, "tahmindir" notu ve
/// puanla girilmiş (sırasız) profillerde "sıralamanı ekle" dürtmesi —
/// gerçek sıra tahminden her zaman daha isabetlidir.
class WizardSummaryHeader extends StatelessWidget {
  final String scoreType;
  final double score;
  final int? rank;
  final int total;

  const WizardSummaryHeader({
    super.key,
    required this.scoreType,
    required this.score,
    required this.rank,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final showRankNudge = score > 0 && rank == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradientFor(context),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              // Puansız (sadece sıralamayla) profillerde puan pili gizlenir.
              if (score > 0)
                _Pill(
                    label: 'Puan',
                    value: '${score.toStringAsFixed(1)} $scoreType')
              else if (rank != null)
                _Pill(
                    label: 'Sıralama',
                    value: '${formatRankTr(rank!)} $scoreType'),
              const SizedBox(width: 10),
              if (score > 0 && rank != null)
                _Pill(label: 'Sıralama', value: formatRankTr(rank!))
              else
                _Pill(label: 'Eşleşen', value: '$total program'),
              const Spacer(),
              const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 30),
            ],
          ),
        ),
        // Kesinlik iddiası yok — öneriler geçmiş yıl verisine dayalı tahmin.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 13, color: AppColors.textTertiaryFor(context)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Öneriler geçmiş yıl verilerine dayalı tahmindir, '
                  'yerleşme garantisi vermez.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryFor(context),
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showRankNudge)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: InkWell(
              onTap: () => context.push('/preference-wizard'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location_rounded,
                        size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Eşleştirme puanından tahmini sırayla yapıldı — '
                        'gerçek sıralamanı girersen isabet artar.',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.info),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  const _Pill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall
                .copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
          Text(
            value,
            style: AppTextStyles.titleSmall
                .copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
