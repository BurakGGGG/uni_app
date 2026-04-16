import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Profil ekranı — auth durumuna göre içerik gösterir
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ─── Profil Bilgileri / Giriş Alanı ────────────────
              authState.when(
                data: (user) {
                  if (user == null) {
                    return _buildGuestProfile(context);
                  }
                  return currentUser.when(
                    data: (profile) => _buildUserProfile(
                      context,
                      ref,
                      displayName: profile?.displayName ?? user.displayName ?? 'Kullanıcı',
                      email: profile?.email ?? user.email ?? '',
                      isVerified: profile?.isVerifiedStudent ?? false,
                      initials: profile?.initials ?? (user.displayName?.isNotEmpty == true ? user.displayName![0] : '?'),
                      photoUrl: profile?.photoUrl ?? user.photoURL,
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, st) => _buildUserProfile(
                      context,
                      ref,
                      displayName: user.displayName ?? 'Kullanıcı',
                      email: user.email ?? '',
                      isVerified: false,
                      initials: user.displayName?.isNotEmpty == true ? user.displayName![0] : '?',
                      photoUrl: user.photoURL,
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => _buildGuestProfile(context),
              ),

              const SizedBox(height: 40),

              // ─── Ayarlar ─────────────────────────────────────
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

  Widget _buildGuestProfile(BuildContext context) {
    return Column(
      children: [
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
        Text('Giriş Yap', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Yorum yapmak ve favori eklemek için\ngiriş yapman gerekiyor.',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: GradientButton(
            text: 'Giriş Yap',
            icon: Icons.login_rounded,
            onPressed: () => context.go('/login'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/register'),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Kayıt Ol'),
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfile(
    BuildContext context,
    WidgetRef ref, {
    required String displayName,
    required String email,
    required bool isVerified,
    required String initials,
    String? photoUrl,
  }) {
    return Column(
      children: [
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
          child: photoUrl != null
              ? ClipOval(
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, trace) => Center(
                      child: Text(
                        initials,
                        style: AppTextStyles.displaySmall
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    initials,
                    style: AppTextStyles.displaySmall
                        .copyWith(color: Colors.white),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Text(displayName, style: AppTextStyles.headlineMedium),
        const SizedBox(height: 4),
        Text(email, style: AppTextStyles.bodySmall),

        // edu.tr doğrulama durumu
        if (isVerified)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded,
                    color: AppColors.success, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Doğrulanmış Öğrenci',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // Çıkış yap butonu
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: Text(
              'Çıkış Yap',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({required this.title, required this.items});

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
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    const Divider(height: 1, indent: 52),
                ],
              );
            }).toList(),
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
