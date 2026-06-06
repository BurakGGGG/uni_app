import 'package:flutter/material.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/locale_provider.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../scripts/brand_colors_migration.dart';
import '../../../../scripts/city_brand_colors_migration.dart';
import '../../../../scripts/department_scores_migration.dart';
import '../../../../scripts/delete_missing_departments.dart';
import '../../../../scripts/seed_data_service.dart' deferred as seed_data;
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../../comparison/presentation/providers/comparison_providers.dart';
import '../widgets/change_password_dialog.dart';
import '../../../stories/presentation/widgets/admin_story_upload_sheet.dart';
import '../../../stories/presentation/widgets/admin_story_management_sheet.dart';
import '../widgets/feedback_sheet.dart';

/// Profil ekranı — auth durumuna göre içerik gösterir
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = ref.watch(currentUserProvider);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // ─── Başlık ───────────────────────────────────────
              Row(
                children: [
                  Text(loc.profileTitle, style: AppTextStyles.headlineLarge),
                  const Spacer(),
                  // Ayarlar butonu
                  Material(
                    color: AppColors.surfaceFor(context),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _showSettingsSheet(context, ref),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderLightFor(context)),
                        ),
                        child: Icon(
                          Icons.settings_rounded,
                          color: AppColors.textSecondaryFor(context),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── Profil Kartı ─────────────────────────────────
              authState.when(
                data: (user) {
                  if (user == null) return _buildGuestProfile(context);
                  return currentUser.when(
                    data: (profile) => _buildUserCard(context, ref, profile, user),
                    loading: () => const Column(
                      children: [
                        CardSkeleton(height: 120),
                        SizedBox(height: 16),
                        ListSkeleton(itemCount: 4, itemHeight: 56),
                      ],
                    ),
                    error: (e, st) => _buildUserCard(context, ref, null, user),
                  );
                },
                loading: () => const Column(
                  children: [
                    CardSkeleton(height: 120),
                    SizedBox(height: 16),
                    ListSkeleton(itemCount: 4, itemHeight: 56),
                  ],
                ),
                error: (e, st) => _buildGuestProfile(context),
              ),

              const SizedBox(height: 24),

              // ─── İstatistikler (giriş yapmışsa) ───────────────
              authState.when(
                data: (user) {
                  if (user == null) return const SizedBox.shrink();
                  return currentUser.when(
                    data: (profile) => _buildStats(context, ref, profile),
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => const SizedBox.shrink(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // ─── Admin Story Yönetimi (sadece admin) ───────────
              currentUser.when(
                data: (profile) {
                  if (profile == null || !profile.isAdmin) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      _SettingsSection(
                        title: 'Story Yönetimi',
                        items: [
                          _SettingsItem(
                            icon: Icons.add_photo_alternate_rounded,
                            title: 'Yeni Story Ekle',
                            subtitle: 'Görsel ve başlıkla story paylaş',
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const AdminStoryUploadSheet(),
                              );
                            },
                          ),
                          _SettingsItem(
                            icon: Icons.view_carousel_rounded,
                            title: 'Aktif Story\'leri Yönet',
                            subtitle: 'Görüntüle veya sil',
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    const AdminStoryManagementSheet(),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              // ─── Hesap Ayarları ────────────────────────────────
              authState.when(
                data: (user) {
                  if (user == null) return const SizedBox.shrink();
                  return _SettingsSection(
                    title: loc.profileAccount,
                    items: [
                      _SettingsItem(
                        icon: Icons.edit_rounded,
                        title: loc.profileEditProfile,
                        subtitle: loc.profileEditSubtitle,
                        onTap: () => context.push('/edit-profile'),
                      ),
                      _buildMembershipSettingsItem(context, ref, loc),                      if (!user.providerData.any((p) => p.providerId == 'google.com'))
                        _SettingsItem(
                          icon: Icons.security_rounded,
                          title: loc.profileSecurity,
                          subtitle: loc.profileSecuritySubtitle,
                          onTap: () async {
                            final result = await ChangePasswordDialog.show(context);
                            if (result == true && context.mounted) {
                              showAppSnackBar(context, message: loc.profilePasswordChanged, isSuccess: true);
                            }
                          },
                        ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // ─── Ayarlar (Tek Buton) ─────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  border: Border.all(color: AppColors.borderLightFor(context)),
                ),
                child: ListTile(
                  onTap: () => _showSettingsSheet(context, ref),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings_rounded, color: AppColors.primary, size: 20),
                  ),
                  title: Text(loc.profileSettings, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${loc.profileTheme}, ${loc.profileLanguage}, ${loc.profileNotifications}',
                    style: AppTextStyles.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryFor(context), size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLg)),
                ),
              ),

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
                            title: Text(loc.profileSignOut),
                            content: Text(loc.profileSignOutConfirm),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.profileCancel)),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(loc.profileSignOut, style: const TextStyle(color: AppColors.error)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          // Comparison state'lerini sıfırla
                          ref.read(comparisonSelectionProvider.notifier).reset();
                          ref.invalidate(comparisonResultProvider);
                          ref.invalidate(comparisonGateDecisionProvider);
                          ref.invalidate(comparisonGateControllerProvider);
                          // Önce nav, sonra signOut → kullanıcı bekleme algılamasın
                          if (context.mounted) context.go('/login');
                          ref.read(authControllerProvider.notifier).signOut();
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: Text(
                        loc.profileSignOut,
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMd)),
                      ),
                    ),
                  );
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

  // ═══════════════════════════════════════════════════════════════
  //  Ayarlar Bottom Sheet
  // ═══════════════════════════════════════════════════════════════

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SettingsBottomSheet(parentContext: context),
    );
  }

  _SettingsItem _buildMembershipSettingsItem(BuildContext context, WidgetRef ref, AppLocalizations loc) {
    final tier = ref.watch(subscriptionTierProvider).valueOrNull ?? SubscriptionTier.free;

    return _SettingsItem(
      icon: Icons.workspace_premium_rounded,
      title: loc.profileMembershipPlan,
      subtitle: loc.profileMembershipUsing(tier.label),
      onTap: () => _showPlanDetails(context, tier, loc),
    );
  }

  void _showPlanDetails(BuildContext context, SubscriptionTier currentTier, AppLocalizations loc) {
    final plans = {
      SubscriptionTier.free: (
        title: 'Ücretsiz',
        features: const [
          'Üniversite karşılaştırma (günlük limitli)',
          'Temel keşif ve inceleme özellikleri',
        ],
      ),
      SubscriptionTier.plus: (
        title: 'Plus',
        features: const [
          'Bölüm ve şehir karşılaştırmaları',
          'Daha geniş kullanım limitleri',
        ],
      ),
      SubscriptionTier.pro: (
        title: 'Pro',
        features: const [
          'Tüm Plus özellikleri',
          'Pro grafikler ve AI destekli özet özellikleri',
        ],
      ),
    };

    final currentPlan = plans[currentTier] ?? plans[SubscriptionTier.free]!;
    
    final Color tierColor;
    switch (currentTier) {
      case SubscriptionTier.pro:
        tierColor = AppColors.tierPro;
        break;
      case SubscriptionTier.plus:
        tierColor = AppColors.tierPlus;
        break;
      case SubscriptionTier.free:
        tierColor = AppColors.tierFree;
        break;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(ctx),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mevcut Planın',
                  style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: tierColor.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: tierColor),
                          const SizedBox(width: 8),
                          Text(
                            currentPlan.title,
                            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800, color: tierColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...currentPlan.features.map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(Icons.check_circle_rounded, size: 16, color: tierColor),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondaryFor(ctx),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/compare/paywall');
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Tüm Planları ve Detayları Gör',
                      style: AppTextStyles.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Misafir Profili ──────────────────────────────────────────

  Widget _buildGuestProfile(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        border: Border.all(color: AppColors.borderLightFor(context)),
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
          Text(loc.profileGuestWelcome, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 6),
          Text(
            loc.profileGuestSubtitle,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: loc.authSignIn,
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
              label: Text(loc.authSignUp),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Kullanıcı Kartı ──────────────────────────────────────────

  Widget _buildUserCard(BuildContext context, WidgetRef ref, UserModel? profile, dynamic firebaseUser) {
    final loc = AppLocalizations.of(context);
    final displayName = profile?.displayName ?? firebaseUser.displayName ?? loc.profileUser;
    final email = profile?.email ?? firebaseUser.email ?? '';
    final photoUrl = profile?.photoUrl ?? firebaseUser.photoURL;
    final isEdu = email.toLowerCase().endsWith('.edu.tr');
    final isVerified = isEdu && ((firebaseUser.emailVerified == true) || (profile?.isVerifiedStudent ?? false));
    final university = profile?.university;
    final department = profile?.department;
    final initials = profile?.initials ?? (displayName.isNotEmpty ? displayName[0] : '?');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        border: Border.all(color: AppColors.borderLightFor(context)),
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
                        child: CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          width: 64,
                          height: 64,
                          memCacheWidth: 128,
                          memCacheHeight: 128,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => Center(
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
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryFor(context)),
                      ),
                    ],
                    if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        profile.bio!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryFor(context),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
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
                    loc.profileVerifiedStudent,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else if (email.toLowerCase().endsWith('.edu.tr'))
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      loc.profileVerificationPending,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final success = await ref.read(authRepositoryProvider).reloadAndCheckVerification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? loc.profileVerified : loc.profileNotVerified),
                            backgroundColor: success ? AppColors.success : AppColors.warning,
                          ),
                        );
                        if (success) {
                          // Firestore'daki güncel isVerifiedStudent değerini okutmak için her iki provider'ı yenile
                          ref.invalidate(currentUserProvider);
                          ref.invalidate(authStateProvider);
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(loc.profileRefresh, style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── İstatistikler ────────────────────────────────────────────

  Widget _buildStats(BuildContext context, WidgetRef ref, UserModel? profile) {
    final loc = AppLocalizations.of(context);
    final favoritesCount = ref.watch(favoritesProvider).value?.length ?? 0;
    final memberDays = DateTime.now().difference(profile?.createdAt ?? DateTime.now()).inDays;

    return Row(
      children: [
        _StatCard(
          icon: Icons.rate_review_rounded,
          label: loc.profileStatReview,
          value: '${profile?.reviewCount ?? 0}',
          color: AppColors.primary,
          onTap: () => context.push('/my-reviews'),
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.favorite_rounded,
          label: loc.profileStatFavorite,
          value: '$favoritesCount',
          color: AppColors.error,
          onTap: () => context.push('/favorites'),
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.cake_rounded,
          label: loc.profileStatMembership,
          value: loc.profileStatDays(memberDays),
          color: AppColors.warning,
        ),
      ],
    );
  }
}

// ─── Stat Card ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              border: Border.all(color: AppColors.borderLightFor(context)),
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
              color: AppColors.textTertiaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(color: AppColors.borderLightFor(context)),
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
      leading: Icon(icon, color: AppColors.textSecondaryFor(context), size: 22),
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.labelSmall)
          : null,
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryFor(context), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLg)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Settings Bottom Sheet
// ═══════════════════════════════════════════════════════════════

class _SettingsBottomSheet extends ConsumerStatefulWidget {
  final BuildContext parentContext;
  const _SettingsBottomSheet({required this.parentContext});

  @override
  ConsumerState<_SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends ConsumerState<_SettingsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentTheme = ref.watch(themeProvider);
    final currentLocale = ref.watch(localeProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Handle bar ─────────────────────────────────
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiaryFor(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 16),

              // ─── Başlık ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(loc.profileSettings, style: AppTextStyles.titleLarge),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundFor(context),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondaryFor(context)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Görünüm Section ────────────────────────────
              _buildSectionLabel(context, 'Görünüm'),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundFor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLightFor(context)),
                ),
                child: Column(
                  children: [
                    // ─── Tema Seçimi ─────────────────────────
                    _buildSheetTile(
                      context,
                      icon: Icons.palette_rounded,
                      iconColor: AppColors.primary,
                      title: loc.profileTheme,
                      trailing: _buildThemeSelector(context, ref, currentTheme, loc),
                    ),
                    Divider(height: 1, indent: 56, color: AppColors.borderLightFor(context)),
                    // ─── Dil Seçimi ──────────────────────────
                    _buildSheetTile(
                      context,
                      icon: Icons.language_rounded,
                      iconColor: AppColors.accent,
                      title: loc.profileLanguage,
                      trailing: _buildLanguageSelector(context, ref, currentLocale, loc),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Genel Section ──────────────────────────────
              _buildSectionLabel(context, 'Genel'),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundFor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLightFor(context)),
                ),
                child: Column(
                  children: [
                    _buildSheetActionTile(
                      context,
                      icon: Icons.notifications_outlined,
                      iconColor: AppColors.warning,
                      title: loc.profileNotifications,
                      subtitle: loc.profileNotificationsSubtitle,
                      onTap: () {
                        Navigator.pop(context);
                        GoRouter.of(widget.parentContext).push('/notification-settings');
                      },
                    ),
                    Divider(height: 1, indent: 56, color: AppColors.borderLightFor(context)),
                    _buildSheetActionTile(
                      context,
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.primary,
                      title: loc.profileAbout,
                      subtitle: '${AppConstants.appName} v${AppConstants.appVersion}',
                      onTap: () {
                        Navigator.pop(context);
                        showAboutDialog(
                          context: widget.parentContext,
                          applicationName: AppConstants.appName,
                          applicationVersion: 'v${AppConstants.appVersion}',
                          applicationIcon: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                          ),
                          children: [
                            const SizedBox(height: 16),
                            Text(loc.profileAboutDescription),
                            const SizedBox(height: 8),
                            Text(loc.profileAboutCopyright),
                          ],
                        );
                      },
                    ),
                    Divider(height: 1, indent: 56, color: AppColors.borderLightFor(context)),
                    _buildSheetActionTile(
                      context,
                      icon: Icons.star_outline_rounded,
                      iconColor: AppColors.ratingStar,
                      title: loc.profileRateApp,
                      subtitle: loc.profileRateAppSubtitle,
                      onTap: () async {
                        Navigator.pop(context);
                        final inAppReview = InAppReview.instance;
                        if (await inAppReview.isAvailable()) {
                          await inAppReview.requestReview();
                        } else {
                          final url = Uri.parse('https://play.google.com/store/apps/details?id=com.unisec.app');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        }
                      },
                    ),
                    Divider(height: 1, indent: 56, color: AppColors.borderLightFor(context)),
                    _buildSheetActionTile(
                      context,
                      icon: Icons.share_outlined,
                      iconColor: AppColors.success,
                      title: loc.profileShareApp,
                      subtitle: loc.profileShareAppSubtitle,
                      onTap: () {
                        Navigator.pop(context);
                        Share.share(loc.profileShareText);
                      },
                    ),
                    Divider(height: 1, indent: 56, color: AppColors.borderLightFor(context)),
                    _buildSheetActionTile(
                      context,
                      icon: Icons.feedback_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      title: loc.localeName == 'tr' ? 'Geri Bildirim' : 'Feedback',
                      subtitle: loc.localeName == 'tr'
                          ? 'Hata bildirin veya öneri gönderin'
                          : 'Report bugs or send suggestions',
                      onTap: () {
                        Navigator.pop(context);
                        final authState = ref.read(authStateProvider).valueOrNull;
                        final currentUser = ref.read(currentUserProvider).valueOrNull;
                        FeedbackSheet.show(
                          widget.parentContext,
                          userId: authState?.uid,
                          userEmail: currentUser?.email ?? authState?.email,
                        );
                      },
                    ),
                    Divider(height: 1, indent: 56, color: AppColors.borderLightFor(context)),
                    _buildSheetActionTile(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      iconColor: AppColors.textSecondaryFor(context),
                      title: loc.profilePrivacyPolicy,
                      onTap: () async {
                        Navigator.pop(context);
                        final url = Uri.parse('https://unisec.app/privacy');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          if (widget.parentContext.mounted) {
                            showAppSnackBar(widget.parentContext, message: loc.privacyPolicyComingSoon);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),

              // ─── Debug Section ──────────────────────────────
              if (kDebugMode) ...[
                const SizedBox(height: 20),
                _buildSectionLabel(context, 'Geliştirici'),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundFor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLightFor(context)),
                  ),
                  child: Column(
                    children: [
                      _buildSheetActionTile(
                        context,
                        icon: Icons.developer_mode_rounded,
                        iconColor: AppColors.error,
                        title: 'Onboarding\'i Sıfırla',
                        onTap: () async {
                          final prefs = ref.read(sharedPreferencesProvider);
                          await prefs.remove('onboarding_completed');
                          if (context.mounted) Navigator.pop(context);
                          if (widget.parentContext.mounted) {
                            ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                              const SnackBar(content: Text('Onboarding sıfırlandı.')),
                            );
                          }
                        },
                      ),
                      Divider(height: 1, indent: 56, color: AppColors.borderLightFor(context)),
                      _buildSheetActionTile(
                        context,
                        icon: Icons.cloud_upload_rounded,
                        iconColor: AppColors.info,
                        title: 'Seed Verisini Yükle',
                        onTap: () async {
                          Navigator.pop(context);
                          await seed_data.loadLibrary();
                          final seedService = seed_data.SeedDataService();
                          try {
                            await seedService.uploadSeedData();
                            if (widget.parentContext.mounted) {
                              showAppSnackBar(widget.parentContext, message: 'Seed verisi yüklendi!', isSuccess: true);
                            }
                          } catch (e) {
                            if (widget.parentContext.mounted) {
                              showAppSnackBar(widget.parentContext, message: 'Hata: $e', isSuccess: false);
                            }
                          }
                        },
                      ),
                      Divider(height: 1, indent: 56, color: AppColors.borderLightFor(context)),
                      _buildSheetActionTile(
                        context,
                        icon: Icons.delete_sweep_rounded,
                        iconColor: AppColors.error,
                        title: 'Kafeleri Sil (Firebase)',
                        onTap: () async {
                          Navigator.pop(context);
                          await seed_data.loadLibrary();
                          final seedService = seed_data.SeedDataService();
                          try {
                            await seedService.deleteCafes();
                            if (widget.parentContext.mounted) {
                              showAppSnackBar(widget.parentContext, message: 'Kafeler silindi!', isSuccess: true);
                            }
                          } catch (e) {
                            if (widget.parentContext.mounted) {
                              showAppSnackBar(widget.parentContext, message: 'Hata: $e', isSuccess: false);
                            }
                          }
                        },
                      ),
                      Divider(height: 1, indent: 56, color: AppColors.borderLightFor(context)),
                      _buildSheetActionTile(
                        context,
                        icon: Icons.bed_rounded,
                        iconColor: AppColors.info,
                        title: 'Yurtları Güncelle (KYK)',
                        onTap: () async {
                          Navigator.pop(context);
                          await seed_data.loadLibrary();
                          final seedService = seed_data.SeedDataService();
                          try {
                            if (widget.parentContext.mounted) {
                              showAppSnackBar(widget.parentContext, message: 'Yurtlar güncelleniyor...', isSuccess: true);
                            }
                            await seedService.reseedDorms();
                            if (widget.parentContext.mounted) {
                              showAppSnackBar(widget.parentContext, message: 'Yurtlar güncellendi!', isSuccess: true);
                            }
                          } catch (e) {
                            if (widget.parentContext.mounted) {
                              showAppSnackBar(widget.parentContext, message: 'Hata: $e', isSuccess: false);
                            }
                          }
                        },
                      ),
                      Divider(height: 1, indent: 56, color: AppColors.borderLightFor(context)),
                      _buildSheetActionTile(
                        context,
                        icon: Icons.palette_rounded,
                        iconColor: AppColors.secondary,
                        title: 'Marka Renklerini Yükle',
                        onTap: () async {
                          Navigator.pop(context);
                          await BrandColorsMigration().run();
                          if (widget.parentContext.mounted) {
                            showAppSnackBar(widget.parentContext, message: 'Marka renkleri yüklendi', isSuccess: true);
                          }
                        },
                      ),
                      Divider(height: 1, indent: 56, color: AppColors.borderLightFor(context)),
                      _buildSheetActionTile(
                        context,
                        icon: Icons.color_lens_rounded,
                        iconColor: AppColors.accent,
                        title: 'Şehir Renklerini Yükle',
                        onTap: () async {
                          Navigator.pop(context);
                          await CityBrandColorsMigration().run();
                          if (widget.parentContext.mounted) {
                            ref.invalidate(citiesProvider);
                            showAppSnackBar(widget.parentContext, message: 'Şehir renkleri yüklendi', isSuccess: true);
                          }
                        },
                      ),
                      Divider(height: 1, indent: 56, color: AppColors.borderLightFor(context)),
                      _buildSheetActionTile(
                        context,
                        icon: Icons.gradient_rounded,
                        iconColor: AppColors.gradientPurple,
                        title: 'Üniversite Gradient Renklerini Yükle',
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            await CityBrandColorsMigration().runUniversityBrandColors();
                            if (widget.parentContext.mounted) {
                              showAppSnackBar(widget.parentContext, message: 'Gradient renkleri yüklendi!', isSuccess: true);
                            }
                          } catch (e) {
                            if (widget.parentContext.mounted) {
                              showAppSnackBar(widget.parentContext, message: 'Hata: $e', isSuccess: false);
                            }
                          }
                        },
                      ),
                      Divider(height: 1, indent: 56, color: AppColors.borderLightFor(context)),
                      _buildSheetActionTile(
                        context,
                        icon: Icons.auto_graph_rounded,
                        iconColor: AppColors.success,
                        title: 'Bölüm Puanlarını Yükle',
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            final report = await DepartmentScoresMigration().run();
                            if (widget.parentContext.mounted) {
                              showAppSnackBar(widget.parentContext, message: 'Başarılı: $report', isSuccess: true);
                            }
                          } catch (e) {
                            if (widget.parentContext.mounted) {
                              showAppSnackBar(widget.parentContext, message: 'Hata: $e', isSuccess: false);
                            }
                          }
                        },
                      ),
                      Divider(height: 1, indent: 56, color: AppColors.borderLightFor(context)),
                      _buildSheetActionTile(
                        context,
                        icon: Icons.cleaning_services_rounded,
                        iconColor: AppColors.error,
                        title: 'Hatalı Bölümleri Temizle',
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            await deleteMissingDepartments();
                            if (widget.parentContext.mounted) {
                              showAppSnackBar(widget.parentContext, message: 'Temizlik başarılı!', isSuccess: true);
                            }
                          } catch (e) {
                            if (widget.parentContext.mounted) {
                              showAppSnackBar(widget.parentContext, message: 'Hata: $e', isSuccess: false);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tema Seçici ────────────────────────────────────────────────
  Widget _buildThemeSelector(BuildContext context, WidgetRef ref, ThemeMode current, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemeChip(
            context, ref,
            icon: Icons.light_mode_rounded,
            label: loc.themeLight,
            isSelected: current == ThemeMode.light,
            mode: ThemeMode.light,
          ),
          _buildThemeChip(
            context, ref,
            icon: Icons.dark_mode_rounded,
            label: loc.themeDark,
            isSelected: current == ThemeMode.dark,
            mode: ThemeMode.dark,
            showBeta: true,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeChip(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required ThemeMode mode,
    bool showBeta = false,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textSecondaryFor(context)),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondaryFor(context),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10,
              ),
            ),
            if (showBeta) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'BETA',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Dil Seçici ────────────────────────────────────────────────
  Widget _buildLanguageSelector(BuildContext context, WidgetRef ref, Locale current, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLangChip(context, ref, label: '🇹🇷 TR', locale: const Locale('tr'), isSelected: current.languageCode == 'tr'),
          _buildLangChip(context, ref, label: '🇬🇧 EN', locale: const Locale('en'), isSelected: current.languageCode == 'en'),
        ],
      ),
    );
  }

  Widget _buildLangChip(BuildContext context, WidgetRef ref, {required String label, required Locale locale, required bool isSelected}) {
    return GestureDetector(
      onTap: () => ref.read(localeProvider.notifier).setLocale(locale),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondaryFor(context),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────

  Widget _buildSectionLabel(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSheetTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Text(title, style: AppTextStyles.bodyMedium),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSheetActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyMedium),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryFor(context)),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiaryFor(context)),
            ],
          ),
        ),
      ),
    );
  }
}

