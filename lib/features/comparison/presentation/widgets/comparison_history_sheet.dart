import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptic.dart';
import '../../domain/models/comparison_history_entry.dart';
import '../providers/comparison_providers.dart';

/// Karşılaştırma geçmişi modal bottom sheet.
/// - Plus/Pro: kullanıcının son ~20 karşılaştırması listelenir.
/// - Free/Misafir: tek bir "Plus/Pro'da var" paywall kartı gösterilir.
class ComparisonHistorySheet extends ConsumerWidget {
  const ComparisonHistorySheet({super.key});

  /// Helper: bottom sheet'i açar.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ComparisonHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canUse = ref.watch(canUseComparisonHistoryProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Başlık
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 22, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      'Karşılaştırma Geçmişi',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    if (canUse)
                      Consumer(
                        builder: (context, ref, _) {
                          final history = ref.watch(comparisonHistoryProvider);
                          final hasItems = history.valueOrNull?.isNotEmpty ?? false;
                          if (!hasItems) return const SizedBox.shrink();
                          return IconButton(
                            icon: const Icon(Icons.delete_sweep_outlined),
                            tooltip: 'Geçmişi temizle',
                            onPressed: () => _confirmClear(context, ref),
                          );
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // İçerik
              Expanded(
                child: canUse
                    ? _HistoryList(scrollController: scrollController)
                    : _PaywallView(scrollController: scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.delete_sweep_outlined,
            color: AppColors.error, size: 32),
        title: const Text('Geçmişi Temizle'),
        content: const Text('Tüm karşılaştırma geçmişin silinsin mi?'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    AppHaptic.reset();
    await ref.read(comparisonHistoryRepositoryProvider).clearHistory();
  }
}

class _HistoryList extends ConsumerWidget {
  final ScrollController scrollController;
  const _HistoryList({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(comparisonHistoryProvider);
    return asyncHistory.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Geçmiş yüklenemedi: $e',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return _EmptyHistory(scrollController: scrollController);
        }
        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _HistoryTile(entry: entries[i]),
        );
      },
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  final ComparisonHistoryEntry entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('d MMM HH:mm', 'tr_TR');

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      onDismissed: (_) {
        ref
            .read(comparisonHistoryRepositoryProvider)
            .deleteEntry(entry.id);
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _open(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              // Sol logo (A) + Sağ logo (B) yan yana — VS göstergesi
              _LogoStack(
                logoA: entry.entityALogo,
                logoB: entry.entityBLogo,
                fallbackIcon: _typeIcon(entry.type),
                accentColor: _typeColor(entry.type),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.entityAName} · ${entry.entityBName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_typeLabel(entry.type)} · ${dateFormat.format(entry.createdAt)}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    Navigator.pop(context);
    // Geçmişten gelen kayıt: çifti seçili olarak aç.
    // Router query params'ı screen'lerin initialAId/initialBId param'larına geçer.
    final base = switch (entry.type) {
      ComparisonHistoryType.university => '/compare/university',
      ComparisonHistoryType.department => '/compare/department',
      ComparisonHistoryType.city => '/compare/city',
    };
    final uri = Uri(
      path: base,
      queryParameters: {
        'a': entry.entityAId,
        'b': entry.entityBId,
      },
    );
    context.push(uri.toString());
  }

  Color _typeColor(ComparisonHistoryType type) {
    switch (type) {
      case ComparisonHistoryType.university:
        return AppColors.primary;
      case ComparisonHistoryType.department:
        return AppColors.secondary;
      case ComparisonHistoryType.city:
        return AppColors.accent;
    }
  }

  IconData _typeIcon(ComparisonHistoryType type) {
    switch (type) {
      case ComparisonHistoryType.university:
        return Icons.account_balance_rounded;
      case ComparisonHistoryType.department:
        return Icons.menu_book_rounded;
      case ComparisonHistoryType.city:
        return Icons.location_city_rounded;
    }
  }

  String _typeLabel(ComparisonHistoryType type) {
    switch (type) {
      case ComparisonHistoryType.university:
        return 'Üniversite';
      case ComparisonHistoryType.department:
        return 'Bölüm';
      case ComparisonHistoryType.city:
        return 'Şehir';
    }
  }
}

/// İki logo'yu hafif overlap ile yan yana gösterir (Stack).
/// Logo string'i:
/// - "assets/" ile başlıyorsa Image.asset (asset bulunamazsa fallback icon)
/// - "http"/"https" ile başlıyorsa Image.network
/// - null veya geçersizse fallback icon kullanılır
class _LogoStack extends StatelessWidget {
  final String? logoA;
  final String? logoB;
  final IconData fallbackIcon;
  final Color accentColor;

  const _LogoStack({
    required this.logoA,
    required this.logoB,
    required this.fallbackIcon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Arka katman (B) — sağda
          Positioned(
            right: 0,
            top: 0,
            child: _LogoCircle(
              source: logoB,
              fallbackIcon: fallbackIcon,
              accentColor: accentColor,
            ),
          ),
          // Ön katman (A) — solda, hafif üstte (z-order)
          Positioned(
            left: 0,
            top: 0,
            child: _LogoCircle(
              source: logoA,
              fallbackIcon: fallbackIcon,
              accentColor: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoCircle extends StatelessWidget {
  final String? source;
  final IconData fallbackIcon;
  final Color accentColor;

  const _LogoCircle({
    required this.source,
    required this.fallbackIcon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    final src = source;
    if (src == null || src.isEmpty) {
      return Icon(fallbackIcon, size: 18, color: accentColor);
    }
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Icon(fallbackIcon, size: 18, color: accentColor),
      );
    }
    if (src.startsWith('assets/')) {
      return Image.asset(
        src,
        fit: BoxFit.cover,
        semanticLabel: 'Üniversite logosu',
        errorBuilder: (_, _, _) =>
            Icon(fallbackIcon, size: 18, color: accentColor),
      );
    }
    return Icon(fallbackIcon, size: 18, color: accentColor);
  }
}

class _EmptyHistory extends StatelessWidget {
  final ScrollController scrollController;
  const _EmptyHistory({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(Icons.history_toggle_off_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Henüz karşılaştırma yapmadın',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk karşılaştırmanı yaptığında burada görünecek.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallView extends StatelessWidget {
  final ScrollController scrollController;
  const _PaywallView({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.tierPlusGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.lock_rounded, color: Colors.white, size: 36),
                const SizedBox(height: 12),
                Text(
                  'Karşılaştırma Geçmişi Plus / Pro\'da',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yaptığın karşılaştırmalar otomatik kaydedilsin, '
                  'istediğin zaman tekrar açıp incele.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/compare/paywall');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.tierPlus,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: Text(
                    'Plus / Pro\'ya Geç',
                    style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _FeatureBullet(
              icon: Icons.bookmark_rounded,
              text: 'Son 20 karşılaştırma otomatik kaydedilir'),
          _FeatureBullet(
              icon: Icons.refresh_rounded,
              text: 'Tek dokunuşla aynı karşılaştırmaya geri dön'),
          _FeatureBullet(
              icon: Icons.cloud_done_rounded,
              text: 'Cihazlar arası senkronize'),
        ],
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
