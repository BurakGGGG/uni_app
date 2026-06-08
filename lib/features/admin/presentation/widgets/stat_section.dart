import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'stat_card.dart';

/// İstatistik kartlarını section başlığı ile gruplandıran widget.
class StatSection extends StatelessWidget {
  final String title;
  final List<StatCardData> cards;

  const StatSection({
    super.key,
    required this.title,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section başlığı
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Kart grid'i (2 sütun)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return StatCard(
              icon: card.icon,
              color: card.color,
              label: card.label,
              value: card.value,
            );
          },
        ),
      ],
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
