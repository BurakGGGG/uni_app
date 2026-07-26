import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../assistant/presentation/widgets/robot_avatar.dart';
import '../../../domain/compare_note.dart';
import '../../../domain/compare_view.dart';
import 'compare_theme.dart';

/// Karşılaştırmanın tepesindeki özet.
///
/// **Kazanan ilan etmez** (kullanıcı kararı): kupa, podyum, "kazandı"
/// yok. Yalnız kim kaç ölçütte önde — kararı öğrenci veriyor. Altındaki
/// tek cümle Üni'nin; kural tabanlı olduğu için her zaman dolu.
class CompareVerdictCard extends StatelessWidget {
  final ComparisonView view;

  const CompareVerdictCard({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final verdict = view.verdict;
    final note = compareNoteFor(view);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: AppColors.softShadowFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (verdict.hasData) ...[
            _LeadBar(verdict: verdict),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (var i = 0; i < view.sides.length; i++)
                  if (verdict.leads[i] > 0)
                    _LeadLabel(
                      color: compareSideColor(i),
                      text: loc.cmpVerdictAhead(
                        _short(view.sides[i].title),
                        '${verdict.leads[i]}',
                      ),
                    ),
                if (verdict.tied > 0)
                  _LeadLabel(
                    color: AppColors.textTertiaryFor(context),
                    text: loc.cmpVerdictTiedSuffix('${verdict.tied}'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RobotAvatar(size: 26, animated: false),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  note.text,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryFor(context),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _short(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    return parts.length <= 2 ? name : parts.take(2).join(' ');
  }
}

/// Önde olunan ölçüt sayılarının oranı — tek şeritte.
class _LeadBar extends StatelessWidget {
  final CompareVerdict verdict;

  const _LeadBar({required this.verdict});

  @override
  Widget build(BuildContext context) {
    final segments = <(Color, int)>[
      for (var i = 0; i < verdict.leads.length; i++)
        if (verdict.leads[i] > 0) (compareSideColor(i), verdict.leads[i]),
      if (verdict.tied > 0)
        (AppColors.textTertiaryFor(context).withValues(alpha: 0.35), verdict.tied),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (final (color, count) in segments)
              Expanded(
                flex: count,
                child: Container(
                  margin: const EdgeInsets.only(right: 2),
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LeadLabel extends StatelessWidget {
  final Color color;
  final String text;

  const _LeadLabel({required this.color, required this.text});

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
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondaryFor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
