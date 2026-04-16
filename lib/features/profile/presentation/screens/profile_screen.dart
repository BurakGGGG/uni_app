import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';

/// Profil ekranı placeholder
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Avatar
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Giriş Yap',
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Yorum yapmak ve favori eklemek için\ngiriş yapman gerekiyor.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Giriş Yap Butonu
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Giriş Yap'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Kayıt Ol'),
                ),
              ),
              const SizedBox(height: 40),
              // Ayarlar Listesi
              _SettingsSection(
                title: 'Uygulama',
                items: [
                  _SettingsItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Hakkında',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.star_outline_rounded,
                    title: 'Uygulamayı Puanla',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.share_outlined,
                    title: 'Paylaş',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Gizlilik Politikası',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '${AppConstants.appName} v${AppConstants.appVersion}',
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: items
                .asMap()
                .entries
                .map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Column(
                    children: [
                      item,
                      if (index < items.length - 1)
                        const Divider(height: 1, indent: 52),
                    ],
                  );
                })
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: AppTextStyles.bodyMedium),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
        size: 20,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      ),
    );
  }
}
