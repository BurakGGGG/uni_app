import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'stat_card.dart';

/// İstatistik kartlarını section başlığı ile gruplandıran widget.
class StatSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<StatCardData> cards;

  const StatSection({
    super.key,
    required this.title,
    required this.cards,
    this.icon = Icons.analytics_outlined,
    this.accentColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondaryFor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columnCount = constraints.maxWidth >= 340 ? 2 : 1;
              final spacing = 10.0;
              final cardWidth =
                  (constraints.maxWidth - spacing * (columnCount - 1)) /
                  columnCount;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: cards.map((card) {
                  return SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      icon: card.icon,
                      color: card.color,
                      label: card.label,
                      value: card.value,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// StatCard için veri taşıyıcı sınıf.
class StatCardData {
  final IconData icon;
  final Color color;
  final String label;
  final int value;

  const StatCardData({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
}
