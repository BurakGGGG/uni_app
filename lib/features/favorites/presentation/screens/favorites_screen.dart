import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';

/// Favoriler ekranı placeholder
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

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
                'Favoriler',
                style: AppTextStyles.displaySmall,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Kaydettiğin üniversiteler',
                style: AppTextStyles.bodySmall,
              ),
            ),
            const Expanded(
              child: EmptyStateWidget(
                icon: Icons.favorite_rounded,
                title: 'Favori listeniz boş',
                description: 'Beğendiğin üniversiteleri favorilere ekle ve burada kolayca takip et.',
                actionText: 'Keşfet',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
