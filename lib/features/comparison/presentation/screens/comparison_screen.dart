import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';

/// Karşılaştırma ekranı placeholder
class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Karşılaştır',
                style: AppTextStyles.displaySmall,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Üniversiteleri yan yana kıyasla',
                style: AppTextStyles.bodySmall,
              ),
            ),
            const Expanded(
              child: EmptyStateWidget(
                icon: Icons.compare_arrows_rounded,
                title: 'Henüz karşılaştırma yok',
                description: 'İki üniversiteyi seçerek detaylı karşılaştırma yapabilirsin.',
                actionText: 'Üniversite Seç',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
