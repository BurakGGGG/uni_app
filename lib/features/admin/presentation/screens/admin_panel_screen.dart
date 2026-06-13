import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/admin_reports_providers.dart';
import '../../data/analytics_migration_service.dart';

/// Admin Paneli — merkezi yönetim hub'ı.
///
/// Buradan farklı admin modüllerine erişilir.
/// İlk modül: Story Yönetimi. İleride genişletilecek.
class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  void _runMigration(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Migration Çalıştır'),
        content: const Text(
          'Mevcut kullanıcı, yorum, beğeni ve rapor sayıları '
          'istatistik counter\'larına aktarılacak. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çalıştır'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final results = await AnalyticsMigrationService().runMigration();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Migration tamamlandı! '
            'Kullanıcı: ${results['totalUsers']}, '
            'Yorum: ${results['totalReviews']}, '
            'Beğeni: ${results['totalLikes']}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Migration hatası: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

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
            onTap: () => context.push('/admin/stats'),
          ),

          const SizedBox(height: 24),

          // ─── Araçlar ──────────────────────────────────────────
          Text(
            'Araçlar',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          _AdminModuleCard(
            icon: Icons.sync_rounded,
            iconColor: const Color(0xFF0EA5E9),
            title: 'İstatistik Migration',
            description: 'Mevcut verileri istatistik counter\'larına aktar.',
            onTap: () => _runMigration(context, ref),
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
  final int badgeCount;
  const _AdminModuleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badgeCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiaryFor(context),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
