import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../../comparison/presentation/providers/comparison_providers.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/guest_profile_card.dart';
import '../widgets/user_profile_card.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/profile_settings_section.dart';
import '../widgets/settings_bottom_sheet.dart';

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
              BrandedScreenHeader(
                title: loc.profileTitle,
                titleStyle: AppTextStyles.headlineLarge,
                padding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),

              // ─── Profil Kartı ─────────────────────────────────
              authState.when(
                data: (user) {
                  if (user == null) return const GuestProfileCard();
                  return currentUser.when(
                    data: (profile) =>
                        UserProfileCard(profile: profile, firebaseUser: user),
                    loading: () => const Column(
                      children: [
                        CardSkeleton(height: 120),
                        SizedBox(height: 16),
                        ListSkeleton(itemCount: 4, itemHeight: 56),
                      ],
                    ),
                    error: (e, st) =>
                        UserProfileCard(profile: null, firebaseUser: user),
                  );
                },
                loading: () => const Column(
                  children: [
                    CardSkeleton(height: 120),
                    SizedBox(height: 16),
                    ListSkeleton(itemCount: 4, itemHeight: 56),
                  ],
                ),
                error: (e, st) => const GuestProfileCard(),
              ),

              const SizedBox(height: 24),

              // ─── İstatistikler (giriş yapmışsa) ───────────────
              authState.when(
                data: (user) {
                  if (user == null) return const SizedBox.shrink();
                  return currentUser.when(
                    data: (profile) => ProfileStatsRow(profile: profile),
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => const SizedBox.shrink(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // ─── Admin Paneli (sadece admin) ───────────────────
              ref
                  .watch(currentUserAdminProvider)
                  .when(
                    data: (isAdmin) {
                      if (!isAdmin) return const SizedBox.shrink();
                      return Column(
                        children: [
                          ProfileSettingsSection(
                            title: 'Yönetim',
                            items: [
                              ProfileSettingsItem(
                                icon: Icons.admin_panel_settings_rounded,
                                title: 'Admin Paneli',
                                subtitle: 'Story yönetimi ve diğer araçlar',
                                onTap: () => context.push('/admin'),
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
                  return ProfileSettingsSection(
                    title: loc.profileAccount,
                    items: [
                      ProfileSettingsItem(
                        icon: Icons.edit_rounded,
                        title: loc.profileEditProfile,
                        subtitle: loc.profileEditSubtitle,
                        onTap: () => context.push('/edit-profile'),
                      ),
                      _buildMembershipSettingsItem(context, ref, loc),
                      if (!user.providerData.any(
                        (p) => p.providerId == 'google.com',
                      ))
                        ProfileSettingsItem(
                          icon: Icons.security_rounded,
                          title: loc.profileSecurity,
                          subtitle: loc.profileSecuritySubtitle,
                          onTap: () async {
                            final result = await ChangePasswordDialog.show(
                              context,
                            );
                            if (result == true && context.mounted) {
                              showAppSnackBar(
                                context,
                                message: loc.profilePasswordChanged,
                                isSuccess: true,
                              );
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
              Material(
                color: AppColors.surfaceFor(context),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  side: BorderSide(color: AppColors.borderLightFor(context)),
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
                    child: const Icon(
                      Icons.settings_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    loc.profileSettings,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${loc.profileTheme}, ${loc.profileLanguage}, ${loc.profileNotifications}',
                    style: AppTextStyles.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiaryFor(context),
                    size: 20,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ─── Çıkış Yap ─────────────────────────────────────
              authState.when(
                data: (user) {
                  if (user == null) return const SizedBox.shrink();
                  return _buildSignOutButton(context, ref, loc);
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
  //  Yardımcı Metodlar
  // ═══════════════════════════════════════════════════════════════

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SettingsBottomSheet(parentContext: context),
    );
  }

  ProfileSettingsItem _buildMembershipSettingsItem(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations loc,
  ) {
    final tier =
        ref.watch(subscriptionTierProvider).valueOrNull ??
        SubscriptionTier.free;

    return ProfileSettingsItem(
      icon: Icons.workspace_premium_rounded,
      title: loc.profileMembershipPlan,
      subtitle: loc.profileMembershipUsing(tier.label),
      onTap: () => _showPlanDetails(context, tier, loc),
    );
  }

  void _showPlanDetails(
    BuildContext context,
    SubscriptionTier currentTier,
    AppLocalizations loc,
  ) {
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mevcut Planın',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
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
                          Icon(
                            Icons.workspace_premium_rounded,
                            color: tierColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentPlan.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: tierColor,
                            ),
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
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: tierColor,
                                ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Tüm Planları ve Detayları Gör',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildSignOutButton(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations loc,
  ) {
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
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(loc.profileCancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    loc.profileSignOut,
                    style: const TextStyle(color: AppColors.error),
                  ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
        ),
      ),
    );
  }
}
