import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/badge_catalog.dart';
import '../providers/badge_providers.dart';
import 'badge_detail_sheet.dart';
import 'badge_medallion.dart';

/// Profildeki rozet vitrini — "Rozetlerim (8/25)" başlığı ve tek sıra
/// madalyon: önce son kazanılanlar, sonra hedefe en yakın kilitliler.
class BadgeShowcase extends ConsumerWidget {
  const BadgeShowcase({super.key});

  static const _visibleCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final progress = ref.watch(badgeProgressProvider);
    if (progress.isEmpty) return const SizedBox.shrink();

    final earned = progress.where((p) => p.earned).toList()
      ..sort((a, b) => b.earnedAt!.compareTo(a.earnedAt!));
    final locked = progress.where((p) => !p.earned).toList()
      ..sort((a, b) => b.fraction.compareTo(a.fraction));
    final visible = [...earned, ...locked].take(_visibleCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              loc.badgesScreenTitle,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                loc.badgesEarnedCount(earned.length, progress.length),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/badges'),
              child: Text(
                loc.badgesSeeAll,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final item in visible) ...[
              Expanded(
                child: _ShowcaseItem(
                  progress: item,
                  onTap: () => BadgeDetailSheet.show(context, item),
                ),
              ),
              if (item != visible.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _ShowcaseItem extends StatelessWidget {
  final BadgeProgress progress;
  final VoidCallback onTap;

  const _ShowcaseItem({required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BadgeMedallion(
            definition: progress.definition,
            earned: progress.earned,
            size: 52,
          ),
          const SizedBox(height: 6),
          Text(
            progress.definition.label(loc),
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 10,
              color: progress.earned
                  ? AppColors.textPrimaryFor(context)
                  : AppColors.textTertiaryFor(context),
              fontWeight: progress.earned ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
