import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../router/app_router.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../domain/insights/uni_insight.dart';
import '../providers/assistant_providers.dart';
import '../providers/uni_panel_providers.dart';
import '../robot_action_route.dart';
import 'robot_avatar.dart';

/// Üni'nin tek bir notu: avatar + başlık + gövde + tek eylem butonu.
///
/// Sohbet yok — kullanıcı ya butona basar ya notu susturur. Bu yüzden kartın
/// tek bir CTA'sı vardır; iki eylem sunmak "hangisi doğru" sorusu yaratır.
class UniInsightCard extends ConsumerWidget {
  final UniInsight insight;

  /// Susturma sonrası panelin listeyi tazelemesi için.
  final VoidCallback? onDismissed;

  const UniInsightCard({
    super.key,
    required this.insight,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = _accentFor(insight.tone);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: insight.tone == InsightTone.neutral
              ? AppColors.borderLightFor(context)
              : accent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Listede çok kart olabilir — hiçbiri animasyonlu değil
              // (RobotAvatar performans kuralı: ekran başına tek animasyon).
              RobotAvatar(size: 26, mood: insight.mood, animated: false),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: insight.tone == InsightTone.neutral
                            ? null
                            : accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.body,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryFor(context),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (insight.dismissible)
                IconButton(
                  tooltip: 'Bu notu gizle',
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textTertiaryFor(context),
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    await ref
                        .read(robotMemoryProvider)
                        .dismissInsight(insight.id);
                    // Susturma shared_preferences'ta; provider onu izlemiyor
                    // (senkron okuma) — listeyi elle tazelemek gerekiyor.
                    ref.invalidate(insightContextProvider);
                    onDismissed?.call();
                  },
                )
              else
                const SizedBox(width: 8),
            ],
          ),
          if (insight.hasAction && insight.actionLabel != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _go(context),
                style: TextButton.styleFrom(foregroundColor: accent),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      insight.actionLabel!,
                      style: AppTextStyles.labelLarge
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _go(BuildContext context) {
    final route = robotActionRoute(insight.action, arg: insight.actionArg);
    if (route == null) return;
    AnalyticsService.instance.trackEvent(AnalyticsEvent.uniInsightTapped);
    // `openLists` bir alt sekme rotası — panelin üstünden push edilirse
    // Navigator çift page key görür (bkz. [navigateToRoute]).
    navigateToRoute(context, route);
  }

  static Color _accentFor(InsightTone tone) {
    switch (tone) {
      case InsightTone.neutral:
        return AppColors.primary;
      case InsightTone.positive:
        return AppColors.success;
      case InsightTone.warning:
        return AppColors.warning;
      case InsightTone.urgent:
        return AppColors.error;
    }
  }
}
