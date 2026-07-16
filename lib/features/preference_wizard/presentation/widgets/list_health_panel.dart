import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../../preference_lists/domain/models/preference_list_model.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import '../../domain/list_health.dart';
import '../providers/preference_wizard_providers.dart';

/// Tercih listesi sağlık paneli (Plus) — profil + liste öğelerinden dağılım,
/// uyarılar ve kaba "en olası yerleşme" tahmini üretir. Profil yoksa robota
/// davet eden CTA, Plus yoksa kilitli kart gösterir.
class ListHealthPanel extends ConsumerWidget {
  final List<PreferenceItem> items;
  const ListHealthPanel({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.length < 2) return const SizedBox.shrink();

    final profile = ref.watch(studentScoreProfileProvider);
    if (profile == null || profile.scoreType.isEmpty) {
      return _CtaCard(
        icon: Icons.smart_toy_rounded,
        title: 'Listenin sağlığını gör',
        subtitle: 'Puanını ya da sıralamanı gir, listenin dengesini ve '
            'risklerini analiz edelim.',
        onTap: () => context.push('/preference-wizard'),
      );
    }

    final tier = ref.watch(subscriptionTierProvider).valueOrNull;
    final hasPlus = tier != null && tier.satisfies(SubscriptionTier.plus);
    if (!hasPlus) {
      return _CtaCard(
        icon: Icons.lock_rounded,
        iconColor: AppColors.tierPlus,
        title: 'Liste sağlık analizi — Plus',
        subtitle: 'Dağılım, risk uyarıları ve en olası yerleşme tahmini '
            'Plus ile açılır.',
        onTap: () => context.push('/compare/paywall'),
      );
    }

    final report = analyzeListHealth(items, profile);
    if (report.rated == 0 && report.unrated == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
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
              const Icon(Icons.monitor_heart_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Liste Sağlığı',
                style: AppTextStyles.titleSmall
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                profile.hasRank
                    ? 'Sıralamana göre'
                    : 'Puanına göre',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiaryFor(context),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (report.rated > 0) ...[
            _DistributionBar(report: report),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _LegendDot(
                  color: AppColors.success,
                  label: '${report.guaranteed} yüksek şans',
                ),
                _LegendDot(
                  color: AppColors.warning,
                  label: '${report.target} ulaşılabilir',
                ),
                _LegendDot(
                  color: AppColors.error,
                  label: '${report.dream} zorlayıcı',
                ),
                if (report.unrated > 0)
                  _LegendDot(
                    color: AppColors.textTertiaryFor(context),
                    label: '${report.unrated} değerlendirilemedi',
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          for (final note in report.notes) _NoteRow(note: note),
          if (report.likelyPlacement != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    report.likelyCategory == MatchCategory.guaranteed
                        ? Icons.school_rounded
                        : Icons.adjust_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimaryFor(context),
                          height: 1.35,
                        ),
                        children: [
                          const TextSpan(text: 'En olası yerleşme: '),
                          TextSpan(
                            text: report.likelyPlacement!.deptName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: ' — ${report.likelyPlacement!.uniName} '
                                '(${report.likelyPlacement!.order}. tercih)',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Geçmiş yıl verilerine dayalı kaba tahmindir, yerleşme garantisi '
            'vermez.',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiaryFor(context),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final ListHealthReport report;
  const _DistributionBar({required this.report});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 9,
        child: Row(
          children: [
            if (report.guaranteed > 0)
              Expanded(
                flex: report.guaranteed,
                child: Container(color: AppColors.success),
              ),
            if (report.target > 0)
              Expanded(
                flex: report.target,
                child: Container(color: AppColors.warning),
              ),
            if (report.dream > 0)
              Expanded(
                flex: report.dream,
                child: Container(color: AppColors.error),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondaryFor(context),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _NoteRow extends StatelessWidget {
  final ListHealthNote note;
  const _NoteRow({required this.note});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (note.severity) {
      ListHealthSeverity.warning =>
        (Icons.warning_amber_rounded, AppColors.warning),
      ListHealthSeverity.info =>
        (Icons.info_outline_rounded, AppColors.info),
      ListHealthSeverity.ok =>
        (Icons.check_circle_outline_rounded, AppColors.success),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              note.text,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondaryFor(context),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _CtaCard({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryFor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondaryFor(context),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiaryFor(context)),
          ],
        ),
      ),
    );
  }
}
