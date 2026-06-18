import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/services/feature_discovery_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../../../scripts/brand_colors_migration.dart';
import '../../../../scripts/city_brand_colors_migration.dart';
import '../../../../scripts/department_scores_migration.dart';
import '../../../../scripts/delete_missing_departments.dart';
import '../../../../scripts/seed_data_service.dart' deferred as seed_data;
import 'feedback_sheet.dart';

/// Profil sayfasındaki ayarlar bottom sheet'i.
/// Tema, dil, bildirim, hakkında ve geliştirici araçları içerir.
class SettingsBottomSheet extends ConsumerStatefulWidget {
  final BuildContext parentContext;
  const SettingsBottomSheet({super.key, required this.parentContext});

  @override
  ConsumerState<SettingsBottomSheet> createState() =>
      _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends ConsumerState<SettingsBottomSheet> {
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
                  color: AppColors.textTertiaryFor(
                    context,
                  ).withValues(alpha: 0.3),
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
                      child: const Icon(
                        Icons.settings_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
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
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textSecondaryFor(context),
                        ),
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
                    _buildSheetTile(
                      context,
                      icon: Icons.palette_rounded,
                      iconColor: AppColors.primary,
                      title: loc.profileTheme,
                      trailing: _buildThemeSelector(
                        context,
                        ref,
                        currentTheme,
                        loc,
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 56,
                      color: AppColors.borderLightFor(context),
                    ),
                    _buildSheetTile(
                      context,
                      icon: Icons.language_rounded,
                      iconColor: AppColors.accent,
                      title: loc.profileLanguage,
                      trailing: _buildLanguageSelector(
                        context,
                        ref,
                        currentLocale,
                        loc,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Genel Section ──────────────────────────────
              _buildSectionLabel(context, 'Genel'),
              const SizedBox(height: 8),
              _buildGeneralSection(context, loc),

              // ─── Debug Section ──────────────────────────────
              if (kDebugMode) ...[
                const SizedBox(height: 20),
                _buildSectionLabel(context, 'Geliştirici'),
                const SizedBox(height: 8),
                _buildDebugSection(context),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Genel Section ────────────────────────────────────────────
  Widget _buildGeneralSection(BuildContext context, AppLocalizations loc) {
    return Container(
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
          _divider(context),
          _buildSheetActionTile(
            context,
            icon: Icons.lightbulb_outline_rounded,
            iconColor: AppColors.accent,
            title: 'Rehberi Tekrar Gör',
            subtitle: 'Uygulama tanıtım turunu tekrar başlat',
            onTap: () {
              Navigator.pop(context);
              ref.read(featureDiscoveryProvider).resetAll();
              ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Rehber sıfırlandı! Sayfaları ziyaret ettiğinde tekrar gösterilecek.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _divider(context),
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
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
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
          _divider(context),
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
                final url = Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.unisec.app',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              }
            },
          ),
          _divider(context),
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
          _divider(context),
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
          _divider(context),
          _buildSheetActionTile(
            context,
            icon: Icons.privacy_tip_outlined,
            iconColor: AppColors.textSecondaryFor(context),
            title: loc.profilePrivacyPolicy,
            onTap: () async {
              Navigator.pop(context);
              final url = Uri.parse(
                'https://uni-app-web-sitesi.vercel.app/privacy.html',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (widget.parentContext.mounted) {
                  showAppSnackBar(
                    widget.parentContext,
                    message: loc.privacyPolicyComingSoon,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ─── Debug Section ────────────────────────────────────────────
  Widget _buildDebugSection(BuildContext context) {
    return Container(
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
          _divider(context),
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
                  showAppSnackBar(
                    widget.parentContext,
                    message: 'Seed verisi yüklendi!',
                    isSuccess: true,
                  );
                }
              } catch (e) {
                if (widget.parentContext.mounted) {
                  showAppSnackBar(
                    widget.parentContext,
                    message: 'Hata: $e',
                    isSuccess: false,
                  );
                }
              }
            },
          ),
          _divider(context),
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
                  showAppSnackBar(
                    widget.parentContext,
                    message: 'Kafeler silindi!',
                    isSuccess: true,
                  );
                }
              } catch (e) {
                if (widget.parentContext.mounted) {
                  showAppSnackBar(
                    widget.parentContext,
                    message: 'Hata: $e',
                    isSuccess: false,
                  );
                }
              }
            },
          ),
          _divider(context),
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
                  showAppSnackBar(
                    widget.parentContext,
                    message: 'Yurtlar güncelleniyor...',
                    isSuccess: true,
                  );
                }
                await seedService.reseedDorms();
                if (widget.parentContext.mounted) {
                  showAppSnackBar(
                    widget.parentContext,
                    message: 'Yurtlar güncellendi!',
                    isSuccess: true,
                  );
                }
              } catch (e) {
                if (widget.parentContext.mounted) {
                  showAppSnackBar(
                    widget.parentContext,
                    message: 'Hata: $e',
                    isSuccess: false,
                  );
                }
              }
            },
          ),
          _divider(context),
          _buildSheetActionTile(
            context,
            icon: Icons.palette_rounded,
            iconColor: AppColors.secondary,
            title: 'Marka Renklerini Yükle',
            onTap: () async {
              Navigator.pop(context);
              await BrandColorsMigration().run();
              if (widget.parentContext.mounted) {
                showAppSnackBar(
                  widget.parentContext,
                  message: 'Marka renkleri yüklendi',
                  isSuccess: true,
                );
              }
            },
          ),
          _divider(context),
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
                showAppSnackBar(
                  widget.parentContext,
                  message: 'Şehir renkleri yüklendi',
                  isSuccess: true,
                );
              }
            },
          ),
          _divider(context),
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
                  showAppSnackBar(
                    widget.parentContext,
                    message: 'Gradient renkleri yüklendi!',
                    isSuccess: true,
                  );
                }
              } catch (e) {
                if (widget.parentContext.mounted) {
                  showAppSnackBar(
                    widget.parentContext,
                    message: 'Hata: $e',
                    isSuccess: false,
                  );
                }
              }
            },
          ),
          _divider(context),
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
                  showAppSnackBar(
                    widget.parentContext,
                    message: 'Başarılı: $report',
                    isSuccess: true,
                  );
                }
              } catch (e) {
                if (widget.parentContext.mounted) {
                  showAppSnackBar(
                    widget.parentContext,
                    message: 'Hata: $e',
                    isSuccess: false,
                  );
                }
              }
            },
          ),
          _divider(context),
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
                  showAppSnackBar(
                    widget.parentContext,
                    message: 'Temizlik başarılı!',
                    isSuccess: true,
                  );
                }
              } catch (e) {
                if (widget.parentContext.mounted) {
                  showAppSnackBar(
                    widget.parentContext,
                    message: 'Hata: $e',
                    isSuccess: false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ─── Tema Seçici ────────────────────────────────────────────────
  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
    AppLocalizations loc,
  ) {
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
            context,
            ref,
            icon: Icons.light_mode_rounded,
            label: loc.themeLight,
            isSelected: current == ThemeMode.light,
            mode: ThemeMode.light,
          ),
          _buildThemeChip(
            context,
            ref,
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
      onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : AppColors.textSecondaryFor(context),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondaryFor(context),
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
  Widget _buildLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    Locale current,
    AppLocalizations loc,
  ) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLangChip(
            context,
            ref,
            label: '🇹🇷 TR',
            locale: const Locale('tr'),
            isSelected: current.languageCode == 'tr',
          ),
          _buildLangChip(
            context,
            ref,
            label: '🇬🇧 EN',
            locale: const Locale('en'),
            isSelected: current.languageCode == 'en',
          ),
        ],
      ),
    );
  }

  Widget _buildLangChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required Locale locale,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => ref.read(localeProvider.notifier).setLocale(locale),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected
                ? Colors.white
                : AppColors.textSecondaryFor(context),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────

  Widget _divider(BuildContext context) =>
      Divider(height: 1, indent: 56, color: AppColors.borderLightFor(context));

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
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiaryFor(context),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textTertiaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
