import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/admin_reports_providers.dart';

/// Admin Paneli — merkezi yönetim hub'ı.
///
/// Buradan farklı admin modüllerine erişilir.
/// İlk modül: Story Yönetimi. İleride genişletilecek.
class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        title: Text(
          'Admin Paneli',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: AppColors.surfaceFor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ─── Hoş geldin kartı ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yönetim Paneli',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Uygulama içeriklerini buradan yönetin.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Modül Başlığı ────────────────────────────────────
          Text(
            'Modüller',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // ─── Story Yönetimi ───────────────────────────────────
          _AdminModuleCard(
            icon: Icons.auto_stories_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Story Yönetimi',
            description: 'Story ekle, düzenle, arşivle veya sil.',
            onTap: () => context.push('/admin/stories'),
          ),

          const SizedBox(height: 12),

          // ─── Placeholder modüller (gelecekte eklenecek) ───────
          Consumer(
            builder: (context, ref, _) {
              final pendingCount = ref.watch(pendingReportCountProvider);
              return _AdminModuleCard(
                icon: Icons.flag_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Raporlar',
                description: 'Kullanıcı raporlarını ve şikayetleri incele.',
                badgeCount: pendingCount.valueOrNull ?? 0,
                onTap: () => context.push('/admin/reports'),
              );
            },
          ),

          const SizedBox(height: 12),

          _AdminModuleCard(
            icon: Icons.bar_chart_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'İstatistikler',
            description: 'Uygulama kullanım istatistiklerini gör.',
            isComingSoon: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

/// Admin panel modül kartı
class _AdminModuleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isComingSoon;
  final int badgeCount;

  const _AdminModuleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
    this.isComingSoon = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isComingSoon ? 0.5 : 1.0,
      child: Material(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isComingSoon ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLightFor(context)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isComingSoon) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.textTertiaryFor(context)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Yakında',
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontSize: 9,
                                  color: AppColors.textTertiaryFor(context),
                                ),
                              ),
                            ),
                          ],
                          if (!isComingSoon && badgeCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$badgeCount',
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryFor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isComingSoon)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiaryFor(context),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
