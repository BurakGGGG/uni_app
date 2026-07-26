import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../../monetization/presentation/widgets/temporary_pro_badge.dart';
import '../../domain/models/comparison_history_entry.dart';
import '../providers/comparison_providers.dart';
import '../widgets/comparison_history_sheet.dart';
import '../widgets/university_logo_box.dart';

/// Karşılaştırma hub'ı: ne karşılaştıracağını seç.
///
/// **Abonelik footer'ı kaldırıldı** (kullanıcı kararı): "Aboneliğin:
/// Ücretsiz + Plus'a Geç" bloğu, kilitli kartların kendi rozetiyle aynı
/// şeyi ikinci kez söylüyordu. Yerine geçmiş yüzeye çıktı — sağ üstteki
/// ikonun içinde gömülüyken kimse açmıyordu.
class ComparisonHubScreen extends ConsumerWidget {
  const ComparisonHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final canDepartment = ref.watch(canCompareDepartmentsProvider);
    final canCity = ref.watch(canCompareCitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: SafeArea(
        child: ListView(
          // Alttaki 88: yüzen Üni son kartı kapatmasın.
          padding: EdgeInsets.fromLTRB(
            Responsive.horizontalPadding(context),
            12,
            Responsive.horizontalPadding(context),
            88,
          ),
          children: [
            _Header(),
            const SizedBox(height: 20),
            _TypeRow(
              icon: Icons.account_balance_rounded,
              color: AppColors.primary,
              title: loc.comparisonEntityUniversity,
              description: loc.comparisonUniversityDesc,
              locked: false,
              onTap: () => context.push('/compare/university'),
            ),
            const SizedBox(height: 10),
            _TypeRow(
              icon: Icons.menu_book_rounded,
              color: AppColors.tierPlus,
              title: loc.comparisonEntityDepartment,
              description: loc.comparisonDepartmentDesc,
              locked: !canDepartment,
              onTap: () => context.push(
                canDepartment ? '/compare/department' : '/compare/paywall',
              ),
            ),
            const SizedBox(height: 10),
            _TypeRow(
              icon: Icons.location_city_rounded,
              color: AppColors.tierPlus,
              title: loc.comparisonEntityCity,
              description: loc.comparisonCityDesc,
              locked: !canCity,
              onTap: () => context.push(
                canCity ? '/compare/city' : '/compare/paywall',
              ),
            ),
            const SizedBox(height: 28),
            const _RecentSection(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.comparisonHubTitle,
                style: AppTextStyles.displaySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                loc.comparisonHubSubtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
        ),
        const TemporaryProBadge(),
      ],
    );
  }
}

/// Tür satırı — eskiden büyük, gradyanlı, blur kaplamalı karttı.
///
/// Kilit artık blur değil küçük bir rozet: blur kaplama içeriği okunmaz
/// yapıp "gizli bir şey var" hissi veriyordu; oysa kilitli olan özellik,
/// içerik değil.
class _TypeRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool locked;
  final VoidCallback onTap;

  const _TypeRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderLightFor(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (locked) ...[
                          const SizedBox(width: 8),
                          const _PlusBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryFor(context),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlusBadge extends StatelessWidget {
  const _PlusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tierPlus.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Plus',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.tierPlus,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ─── Son karşılaştırmalar ──────────────────────────────────────────

/// Geçmiş artık hub'ın içinde (kullanıcı kararı).
///
/// Kayıt Plus/Pro özelliği: ücretsiz kullanıcıda liste boş döner ve bölüm
/// hiç çizilmez — kilitli bir bloğu boş boş göstermek satış gürültüsü
/// olurdu.
class _RecentSection extends ConsumerWidget {
  const _RecentSection();

  static const int _visible = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final entries = ref.watch(comparisonHistoryProvider).valueOrNull;
    if (entries == null || entries.isEmpty) return const SizedBox.shrink();

    final shown = entries.take(_visible).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                loc.cmpHubRecentTitle,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiaryFor(context),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            if (entries.length > _visible)
              TextButton(
                onPressed: () => ComparisonHistorySheet.show(context),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                child: Text(loc.cmpHubSeeAll),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _RecentRow(entry: shown[i])
              .animate()
              .fadeIn(delay: Duration(milliseconds: 40 * i), duration: 240.ms)
              .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
        ],
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  final ComparisonHistoryEntry entry;
  const _RecentRow({required this.entry});

  String get _route => switch (entry.type) {
        ComparisonHistoryType.university => '/compare/university',
        ComparisonHistoryType.department => '/compare/department',
        ComparisonHistoryType.city => '/compare/city',
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push(
          '$_route?a=${entry.entityAId}&b=${entry.entityBId}',
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLightFor(context)),
          ),
          child: Row(
            children: [
              UniversityLogoBox(
                universityId: entry.entityAId,
                universityName: entry.entityAName,
                accentColor: AppColors.primary,
                size: 30,
              ),
              const SizedBox(width: 6),
              UniversityLogoBox(
                universityId: entry.entityBId,
                universityName: entry.entityBName,
                accentColor: AppColors.secondary,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${entry.entityAName}  ·  ${entry.entityBName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textTertiaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
