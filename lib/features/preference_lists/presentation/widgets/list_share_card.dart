import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../services/engagement_service.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../../preference_wizard/domain/list_health.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import '../../domain/list_overview.dart';
import '../../domain/models/preference_list_model.dart';
import 'list_balance_bar.dart';

/// Tercih listesinin paylaşılabilir ÖZET görseli.
///
/// Tam liste değil özet (kullanıcı kararı): 24 satırlık uzun bir görsel
/// sosyal uygulamalarda kırpılıyor. Kart ilk beş tercihi, dolulukları ve
/// dengeyi taşır — gerisi "…N tercih daha".
class ListShareCard extends StatelessWidget {
  final ListOverview overview;

  /// Kart uygulama ağacının DIŞINDA çiziliyor (`captureFromWidget`), yani
  /// içinde `AppLocalizations.of(context)` çalışmaz — çeviri nesnesi
  /// çağıranın canlı context'inden alınıp buraya taşınıyor.
  final AppLocalizations loc;

  const ListShareCard({super.key, required this.overview, required this.loc});

  static const Size _size = Size(540, 675);
  static const int _visibleItems = 5;

  /// Kartı görüntüye çevirip sistem paylaşım menüsünü açar
  /// (`ScoreShareCard` ile aynı akış).
  static Future<void> share(BuildContext context, ListOverview overview) async {
    final controller = ScreenshotController();
    final mediaQueryData = MediaQuery.of(context);
    final loc = AppLocalizations.of(context);

    final image = await controller.captureFromWidget(
      MediaQuery(
        data: mediaQueryData,
        child: ListShareCard(overview: overview, loc: loc),
      ),
      pixelRatio: 2.0,
      targetSize: _size,
    );

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/tercih_listem_'
      '${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(image);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: loc.prefListShareCardText(
        overview.list.title,
        overview.filled,
        ListOverview.capacity,
      ),
    );
    AnalyticsService.instance.trackEvent(AnalyticsEvent.preferenceListShared);
    EngagementService.instance.recordShare();
  }

  @override
  Widget build(BuildContext context) {
    final items = overview.topItems(_visibleItems);
    final hidden = overview.filled - items.length;
    final health = overview.health;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: _size.width,
          height: _size.height,
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
              Text(
                loc.prefListShareCardHeading,
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                overview.list.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 16),
              _StatsRow(overview: overview, health: health, loc: loc),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _Row(order: i + 1, item: items[i]),
                      ],
                      const Spacer(),
                      if (hidden > 0)
                        Text(
                          loc.prefListShareCardMore(hidden),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'ÜniSeç',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'uniseç.app',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
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
}

class _StatsRow extends StatelessWidget {
  final ListOverview overview;
  final ListHealthReport? health;
  final AppLocalizations loc;

  const _StatsRow({
    required this.overview,
    required this.health,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final report = health;
    return Row(
      children: [
        _Pill(
          text: loc.prefListShareCardCount(
            overview.filled,
            ListOverview.capacity,
          ),
          bold: true,
        ),
        if (report != null && report.rated > 0) ...[
          const SizedBox(width: 8),
          _Pill(
            text: loc.prefListShareCardBandSafe(report.guaranteed),
            dot: listBandColor(MatchCategory.guaranteed),
          ),
          const SizedBox(width: 8),
          _Pill(
            text: loc.prefListShareCardBandReach(report.dream),
            dot: listBandColor(MatchCategory.dream),
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? dot;

  const _Pill({required this.text, this.bold = false, this.dot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: bold ? 0.24 : 0.14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: AppTextStyles.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final int order;
  final PreferenceItem item;

  const _Row({required this.order, required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Text(
            '$order',
            style: AppTextStyles.titleSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.uniName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                item.deptName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
