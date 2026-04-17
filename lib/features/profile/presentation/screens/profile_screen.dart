import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/user_model.dart';

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
              const SizedBox(height: 10),

              // ─── Başlık ───────────────────────────────────────
              Row(
                children: [
                  Text('Hesabım', style: AppTextStyles.headlineLarge),
                  const Spacer(),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // ─── Profil Kartı ─────────────────────────────────
              authState.when(
                data: (user) {
                  if (user == null) return _buildGuestProfile(context);
                  return currentUser.when(
                    data: (profile) => _buildUserCard(context, ref, profile, user),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, st) => _buildUserCard(context, ref, null, user),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => _buildGuestProfile(context),
              ),

              const SizedBox(height: 24),

              // ─── İstatistikler (giriş yapmışsa) ───────────────
              authState.when(
                data: (user) {
                  if (user == null) return const SizedBox.shrink();
                  return currentUser.when(
                    data: (profile) => _buildStats(profile),
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => const SizedBox.shrink(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // ─── Hesap Ayarları ────────────────────────────────
              authState.when(
                data: (user) {
                  if (user == null) return const SizedBox.shrink();
                  return _SettingsSection(
                    title: 'Hesap',
                    items: [
                      _SettingsItem(
                        icon: Icons.edit_rounded,
                        title: 'Profili Düzenle',
                        subtitle: 'Fotoğraf, isim, üniversite',
                        onTap: () => context.push('/edit-profile'),
                      ),
                      _SettingsItem(
                        icon: Icons.notifications_outlined,
                        title: 'Bildirimler',
                        subtitle: 'Yorum, favori bildirimleri',
                        onTap: () {},
                      ),
                      if (!user.providerData.any((p) => p.providerId == 'google.com'))
                        _SettingsItem(
                          icon: Icons.security_rounded,
                          title: 'Güvenlik',
                          subtitle: 'Şifre değiştir',
                          onTap: () {},
                        ),
                    ],
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
                },
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // ─── Uygulama Ayarları ─────────────────────────────
              _SettingsSection(
                title: 'Uygulama',
                items: [
                  _SettingsItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Hakkında',
                    subtitle: '${AppConstants.appName} v${AppConstants.appVersion}',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.star_outline_rounded,
                    title: 'Uygulamayı Puanla',
                    subtitle: 'Google Play\'de değerlendir',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.share_outlined,
                    title: 'Arkadaşına Öner',
                    subtitle: 'Linki paylaş',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Gizlilik Politikası',
                    onTap: () {},
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 16),

              // ─── Çıkış Yap ─────────────────────────────────────
              authState.when(
                data: (user) {
                  if (user == null) return const SizedBox.shrink();
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Çıkış Yap'),
                            content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Çıkış Yap', style: TextStyle(color: AppColors.error)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref.read(authControllerProvider.notifier).signOut();
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: Text(
                        'Çıkış Yap',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMd)),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
                },
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Misafir Profili ──────────────────────────────────────────

  Widget _buildGuestProfile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
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
            child: const Icon(Icons.person_rounded, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text('Hoş Geldin!', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Yorum yapmak ve favori eklemek için\ngiriş yapman gerekiyor.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Giriş Yap',
            icon: Icons.login_rounded,
            onPressed: () => context.go('/login'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/register'),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Kayıt Ol'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  // ─── Kullanıcı Kartı ──────────────────────────────────────────

  Widget _buildUserCard(BuildContext context, WidgetRef ref, UserModel? profile, dynamic firebaseUser) {
    final displayName = profile?.displayName ?? firebaseUser.displayName ?? 'Kullanıcı';
    final email = profile?.email ?? firebaseUser.email ?? '';
    final photoUrl = profile?.photoUrl ?? firebaseUser.photoURL;
    final isVerified = profile?.isVerifiedStudent ?? false;
    final university = profile?.university;
    final department = profile?.department;
    final initials = profile?.initials ?? (displayName.isNotEmpty ? displayName[0] : '?');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          width: 64,
                          height: 64,
                          errorBuilder: (ctx, err, trace) => Center(
                            child: Text(initials, style: AppTextStyles.titleLarge.copyWith(color: Colors.white)),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(initials, style: AppTextStyles.titleLarge.copyWith(color: Colors.white)),
                      ),
              ),
              const SizedBox(width: 16),
              // Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: AppTextStyles.titleLarge),
                    const SizedBox(height: 2),
                    Text(email, style: AppTextStyles.bodySmall),
                    if (university != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        university,
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                      ),
                    ],
                    if (department != null) ...[
                      Text(
                        department,
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // edu.tr rozeti
          if (isVerified)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Doğrulanmış Öğrenci',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  // ─── İstatistikler ────────────────────────────────────────────

  Widget _buildStats(UserModel? profile) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.rate_review_rounded,
          label: 'Yorum',
          value: '${profile?.reviewCount ?? 0}',
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.favorite_rounded,
          label: 'Favori',
          value: '${profile?.favorites.length ?? 0}',
          color: AppColors.error,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.star_rounded,
          label: 'Puan',
          value: '4.5',
          color: AppColors.warning,
        ),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }
}

// ─── Stat Card ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: AppTextStyles.titleLarge),
            Text(label, style: AppTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }
}

// ─── Settings Section ───────────────────────────────────────────

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
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.labelSmall)
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLg)),
    );
  }
}
