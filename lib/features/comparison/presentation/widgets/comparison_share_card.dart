import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/comparison_result.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';

enum ShareFormat {
  instagramStory(width: 1080, height: 1920),
  instagramPost(width: 1080, height: 1080),
  twitterCard(width: 1200, height: 675),
  whatsappPreview(width: 800, height: 600);

  final int width;
  final int height;
  const ShareFormat({required this.width, required this.height});

  double get aspectRatio => width / height;
}

class ShareFormatPicker extends StatelessWidget {
  final ValueChanged<ShareFormat> onSelected;

  const ShareFormatPicker({super.key, required this.onSelected});

  static Future<ShareFormat?> show(BuildContext context) {
    return showModalBottomSheet<ShareFormat>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ShareFormatPicker(
        onSelected: (format) => Navigator.pop(ctx, format),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).commonShare,
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: Text(AppLocalizations.of(context).shareInstagramStory),
            onTap: () => onSelected(ShareFormat.instagramStory),
          ),
          ListTile(
            leading: const Icon(Icons.crop_square_rounded),
            title: Text(AppLocalizations.of(context).shareInstagramPost),
            onTap: () => onSelected(ShareFormat.instagramPost),
          ),
          ListTile(
            leading: const Icon(Icons.forum_rounded),
            title: Text(AppLocalizations.of(context).shareTwitterWhatsApp),
            onTap: () => onSelected(ShareFormat.twitterCard),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class ComparisonShareCard extends StatelessWidget {
  final ComparisonResult result;
  final ScreenshotController controller;
  final ShareFormat format;

  const ComparisonShareCard({
    super.key,
    required this.result,
    required this.controller,
    required this.format,
  });

  static Future<void> shareCard(
    BuildContext context,
    ComparisonResult result,
  ) async {
    final loc = AppLocalizations.of(context);
    final mediaQueryData = MediaQuery.of(context);
    final format = await ShareFormatPicker.show(context);
    if (format == null) return;

    final controller = ScreenshotController();
    final image = await controller.captureFromWidget(
      MediaQuery(
        data: mediaQueryData,
        child: ComparisonShareCard(
          result: result,
          controller: controller,
          format: format,
        ),
      ),
      pixelRatio: 2.0,
      targetSize: Size(format.width.toDouble(), format.height.toDouble()),
    );

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/karsilastirma_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(image);

    // Deep-link URL — alıcı app'i indirip yüklediyse direkt karşılaştırmaya gelir.
    // Host şu an placeholder; production'a hazırlanırken Universal/App Links setup'ı
    // (apple-app-site-association, assetlinks.json) sonrasında çalışır hale gelir.
    final shareLink = Uri(
      scheme: 'https',
      host: 'uniseç.app',
      path: '/compare/university',
      queryParameters: {
        'a': result.uniA.id,
        'b': result.uniB.id,
      },
    ).toString();

    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          '${result.uniA.name} vs ${result.uniB.name} — ${loc.comparisonHubTitle} | ÜniSeç\n\n$shareLink',
    );
    AnalyticsService.instance.trackEvent(AnalyticsEvent.comparisonShared);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final winnerA = result.overallWinnerId == result.uniA.id;
    final winnerB = result.overallWinnerId == result.uniB.id;

    return Screenshot(
      controller: controller,
      child: Container(
        width: format.width.toDouble(),
        height: format.height.toDouble(),
        padding: EdgeInsets.all(format.width * 0.05), // Dinamik padding
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
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'ÜniSeç',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${result.uniA.name}  vs  ${result.uniB.name}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
                              ),
                            ),
                            const SizedBox(height: 20),
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
                                const SizedBox(width: 16),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.white : Colors.black)
                                        .withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'VS',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
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
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                result.summaryText,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  height: 1.3,
                                  color: isDark ? Colors.white70 : AppColors.textSecondaryFor(context),
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (result.stats.avgBaseScoreA > 0 ||
                                result.stats.avgBaseScoreB > 0) ...[
                              const SizedBox(height: 18),
                              Divider(
                                height: 1,
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.08),
                              ),
                              const SizedBox(height: 16),
                              _ShareStatRow(
                                label: loc.shareStatAvgBase,
                                valueA: result.stats.avgBaseScoreA > 0
                                    ? result.stats.avgBaseScoreA.toStringAsFixed(1)
                                    : '-',
                                valueB: result.stats.avgBaseScoreB > 0
                                    ? result.stats.avgBaseScoreB.toStringAsFixed(1)
                                    : '-',
                              ),
                              const SizedBox(height: 10),
                              _ShareStatRow(
                                label: loc.shareStatDepartment,
                                valueA: result.stats.totalDepartmentsA.toString(),
                                valueB: result.stats.totalDepartmentsB.toString(),
                              ),
                              const SizedBox(height: 10),
                              _ShareStatRow(
                                label: loc.shareStatPlace,
                                valueA: result.placeCountA.toString(),
                                valueB: result.placeCountB.toString(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Watermark
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'üniSeç',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
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
            AppLocalizations.of(context).winner,
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
              color: AppColors.textTertiaryFor(context),
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
