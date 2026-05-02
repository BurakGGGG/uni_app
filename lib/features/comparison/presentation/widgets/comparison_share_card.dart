import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/comparison_result.dart';

class ComparisonShareCard extends StatelessWidget {
  final ComparisonResult result;
  final ScreenshotController controller;

  const ComparisonShareCard({
    super.key,
    required this.result,
    required this.controller,
  });

  static Future<void> shareCard(
    BuildContext context,
    ComparisonResult result,
  ) async {
    final controller = ScreenshotController();
    final image = await controller.captureFromWidget(
      MediaQuery(
        data: MediaQuery.of(context),
        child: ComparisonShareCard(result: result, controller: controller),
      ),
      pixelRatio: 2.5,
    );

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/karsilastirma.png');
    await file.writeAsBytes(image);

    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          '${result.uniA.name} vs ${result.uniB.name} karşılaştırması — ÜniSeç ile yap!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: controller,
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.school_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'ÜniSeç',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Karşılaştırma',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _ShareScoreCard(
                        name: result.uniA.name,
                        score: result.uniA.avgRating,
                        color: AppColors.primary,
                        isWinner: result.overallWinnerId == result.uniA.id,
                      )),
                      const SizedBox(width: 12),
                      Text(
                        'VS',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _ShareScoreCard(
                        name: result.uniB.name,
                        score: result.uniB.avgRating,
                        color: AppColors.secondary,
                        isWinner: result.overallWinnerId == result.uniB.id,
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    result.summaryText,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (result.stats.avgBaseScoreA > 0 ||
                      result.stats.avgBaseScoreB > 0) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _ShareStatRow(
                      label: 'Ort. Taban',
                      valueA: result.stats.avgBaseScoreA > 0
                          ? result.stats.avgBaseScoreA.toStringAsFixed(1)
                          : '-',
                      valueB: result.stats.avgBaseScoreB > 0
                          ? result.stats.avgBaseScoreB.toStringAsFixed(1)
                          : '-',
                    ),
                    const SizedBox(height: 4),
                    _ShareStatRow(
                      label: 'Bölüm',
                      valueA: result.stats.totalDepartmentsA.toString(),
                      valueB: result.stats.totalDepartmentsB.toString(),
                    ),
                    const SizedBox(height: 4),
                    _ShareStatRow(
                      label: 'Mekan',
                      valueA: result.placeCountA.toString(),
                      valueB: result.placeCountB.toString(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'unisec.app — Türkiye\'nin üniversite rehberi',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareScoreCard extends StatelessWidget {
  final String name;
  final double score;
  final Color color;
  final bool isWinner;

  const _ShareScoreCard({
    required this.name,
    required this.score,
    required this.color,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isWinner)
          Icon(Icons.emoji_events_rounded, color: color, size: 24),
        if (isWinner) const SizedBox(height: 4),
        Text(
          score > 0 ? score.toStringAsFixed(1) : '-',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 36,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ShareStatRow extends StatelessWidget {
  final String label;
  final String valueA;
  final String valueB;

  const _ShareStatRow({
    required this.label,
    required this.valueA,
    required this.valueB,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            valueA,
            textAlign: TextAlign.right,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            valueB,
            textAlign: TextAlign.left,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
