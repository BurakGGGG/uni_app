import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/engagement_service.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../../assistant/domain/robot_mood.dart';
import '../../../assistant/presentation/widgets/robot_avatar.dart';
import '../../domain/models/multi_score_result.dart';
import 'score_type_card.dart';

/// Sonuç paylaşım kartı: 540×675 mantıksal (2x → 1080×1350 px, IG post
/// oranı). Ekran dışında render edildiği için renkleri tema bağımsız sabit.
class ScoreShareCard extends StatelessWidget {
  final MultiScoreOutcome outcome;

  const ScoreShareCard({super.key, required this.outcome});

  /// Kartı görüntüye çevirip sistem paylaşım menüsünü açar
  /// (comparison_share_card.dart ile aynı akış).
  static Future<void> share(
      BuildContext context, MultiScoreOutcome outcome) async {
    final controller = ScreenshotController();
    final mediaQueryData = MediaQuery.of(context);

    final image = await controller.captureFromWidget(
      MediaQuery(
        data: mediaQueryData,
        child: ScoreShareCard(outcome: outcome),
      ),
      pixelRatio: 2.0,
      targetSize: const Size(540, 675),
    );

    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/yks_sonuc_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(image);

    final best = outcome.best;
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'YKS ${outcome.year} deneme sonucum'
          '${best != null ? ' — en güçlü türüm ${best.score.scoreType} 💪' : ''}'
          ' | ÜniSeç',
    );
    AnalyticsService.instance.trackEvent(AnalyticsEvent.scoreShared);
    EngagementService.instance.recordShare();
  }

  @override
  Widget build(BuildContext context) {
    final best = outcome.best;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 540,
          height: 675,
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const RobotAvatar(
                    size: 56,
                    animated: false,
                    mood: RobotMood.celebrating,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YKS Sonuçlarım',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${outcome.year} · Deneme Hesaplaması',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final o in outcome.outcomes) ...[
                        _TypeRow(outcome: o, isBest: o == best),
                        if (o != outcome.outcomes.last)
                          const Divider(height: 20),
                      ],
                      const Spacer(),
                      Text(
                        'Sıralamalar ÖSYM verilerine dayalı tahmindir.',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: Colors.black45),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ÜniSeç · Puan Hesaplama',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _dateLabel(DateTime.now()),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _dateLabel(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }
}

class _TypeRow extends StatelessWidget {
  final ScoreTypeOutcome outcome;
  final bool isBest;

  const _TypeRow({required this.outcome, required this.isBest});

  @override
  Widget build(BuildContext context) {
    final color = scoreTypeColor(outcome.score.scoreType);

    return Row(
      children: [
        Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              outcome.score.scoreType,
              style: AppTextStyles.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    outcome.score.placementScore.toStringAsFixed(2),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (isBest) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.star_rounded,
                        size: 16, color: AppColors.gold),
                  ],
                ],
              ),
              if (outcome.estimatedRank != null)
                Text(
                  '~${formatRank(outcome.estimatedRank!)}. sıra'
                  '${outcome.percentile != null ? ' · ${formatPercentile(outcome.percentile!)}' : ''}',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: Colors.black54),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
