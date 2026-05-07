import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final winnerA = result.overallWinnerId == result.uniA.id;
    final winnerB = result.overallWinnerId == result.uniB.id;

    return Screenshot(
      controller: controller,
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              Color.lerp(AppColors.primary, AppColors.secondary, 0.55)!,
              AppColors.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ÜniSeç',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                  ),
                  child: const Text(
                    'Karşılaştırma',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${result.uniA.name}  vs  ${result.uniB.name}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _ShareScoreCard(
                              name: result.uniA.name,
                              score: result.uniA.avgRating,
                              color: AppColors.primary,
                              isWinner: winnerA,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'VS',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ShareScoreCard(
                              name: result.uniB.name,
                              score: result.uniB.avgRating,
                              color: AppColors.secondary,
                              isWinner: winnerB,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          result.summaryText,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            height: 1.3,
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (result.stats.avgBaseScoreA > 0 ||
                          result.stats.avgBaseScoreB > 0) ...[
                        const SizedBox(height: 14),
                        Divider(
                          height: 1,
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.08),
                        ),
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
                        const SizedBox(height: 6),
                        _ShareStatRow(
                          label: 'Bölüm',
                          valueA: result.stats.totalDepartmentsA.toString(),
                          valueB: result.stats.totalDepartmentsB.toString(),
                        ),
                        const SizedBox(height: 6),
                        _ShareStatRow(
                          label: 'Mekan',
                          valueA: result.placeCountA.toString(),
                          valueB: result.placeCountB.toString(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'unisec.app • Türkiye\'nin üniversite rehberi',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
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
        if (isWinner) _WinnerPill(color: color),
        if (isWinner) const SizedBox(height: 8),
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

class _WinnerPill extends StatelessWidget {
  final Color color;
  const _WinnerPill({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            'Önde',
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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
