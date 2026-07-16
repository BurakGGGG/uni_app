import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/badge_catalog.dart';
import '../providers/badge_providers.dart';
import '../widgets/badge_detail_sheet.dart';
import '../widgets/badge_medallion.dart';

/// Rozetlerim — tüm katalog, kategori bölümleri ve ilerleme ile.
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final progress = ref.watch(badgeProgressProvider);
    final earnedCount = progress.where((p) => p.earned).length;

    final byCategory = <BadgeCategory, List<BadgeProgress>>{};
    for (final item in progress) {
      byCategory.putIfAbsent(item.definition.category, () => []).add(item);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundFor(context),
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.badgesScreenTitle,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                loc.badgesEarnedCount(earnedCount, progress.length),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          for (final category in BadgeCategory.values)
            if (byCategory.containsKey(category))
              _CategorySection(
                category: category,
                items: byCategory[category]!,
              ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final BadgeCategory category;
  final List<BadgeProgress> items;

  const _CategorySection({required this.category, required this.items});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final earned = items.where((p) => p.earned).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 12),
          child: Row(
            children: [
              Text(
                badgeCategoryLabel(loc, category),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                loc.badgesEarnedCount(earned, items.length),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
          children: [
            for (final item in items) _BadgeTile(progress: item),
          ],
        ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeProgress progress;

  const _BadgeTile({required this.progress});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final definition = progress.definition;
    final target = definition.target;

    return GestureDetector(
      onTap: () => BadgeDetailSheet.show(context, progress),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: progress.earned
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.borderLightFor(context),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BadgeMedallion(
              definition: definition,
              earned: progress.earned,
              size: 56,
            ),
            const SizedBox(height: 8),
            Text(
              definition.label(loc),
              style: AppTextStyles.labelSmall.copyWith(
                color: progress.earned
                    ? AppColors.textPrimaryFor(context)
                    : AppColors.textTertiaryFor(context),
                fontWeight:
                    progress.earned ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (progress.earned)
              const Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: AppColors.success,
              )
            else if (target != null)
              Text(
                loc.badgeProgressLabel(
                  progress.current.clamp(0, target),
                  target,
                ),
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 10,
                  color: AppColors.textTertiaryFor(context),
                ),
              )
            else
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: AppColors.textTertiaryFor(context),
              ),
          ],
        ),
      ),
    );
  }
}
