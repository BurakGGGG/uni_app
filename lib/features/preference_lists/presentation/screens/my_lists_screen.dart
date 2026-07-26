import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../router/app_router.dart';
import '../../../assistant/domain/robot_brain.dart';
import '../../../assistant/presentation/widgets/robot_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/list_overview.dart';
import '../../domain/models/preference_list_model.dart';
import '../providers/preference_list_providers.dart';
import '../widgets/create_list_sheet.dart';
import '../widgets/list_actions_sheet.dart';
import '../widgets/dashed_box.dart';
import '../widgets/list_balance_bar.dart';
import '../widgets/share_list_sheet.dart';

/// Tercih Listelerim.
///
/// Yerleşim kuralı (kullanıcı kararı): **tek bir ana liste kahraman**, geri
/// kalanlar altında ince satırlar. Eskiden bütün listeler aynı boyda ve aynı
/// görünen kartlardı; ekranda hiyerarşi yoktu ve kartlar listenin İÇİNDEN
/// hiçbir şey göstermiyordu (sadece ad + doluluk çubuğu). Artık kahraman
/// kart dengeyi, logoları, ilk üç tercihi ve Üni'nin yorumunu taşıyor.
class MyListsScreen extends ConsumerWidget {
  const MyListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const _UnauthenticatedView();

    final listsAsync = ref.watch(myPreferenceListsProvider);
    final overviews = ref.watch(listOverviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      // Yüzen buton YOK (kullanıcı kararı): sağ alt köşe yüzen Üni'nin,
      // ikisi üst üste biniyordu. "Yeni liste" listenin sonunda, bağlamının
      // içinde duruyor. `AppRoutes.branchesWithOwnFab` de bu yüzden boşaldı.
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _Header(overviews: overviews),
            ),
            listsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).errorGeneral(e.toString()),
                  ),
                ),
              ),
              data: (_) {
                if (overviews.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  );
                }
                return _Body(overviews: overviews);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final List<ListOverview> overviews;
  const _Header({required this.overviews});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final total = overviews.fold<int>(0, (sum, o) => sum + o.filled);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.prefListsTitle,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          if (overviews.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              loc.prefListsSummary(overviews.length, total),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final List<ListOverview> overviews;
  const _Body({required this.overviews});

  @override
  Widget build(BuildContext context) {
    final main = overviews.first;
    final others = overviews.skip(1).toList();

    return SliverPadding(
      // Alttaki 100: yüzen Üni son satırı kapatmasın.
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      sliver: SliverList.list(
        children: [
          _HeroCard(overview: main)
              .animate()
              .fadeIn(duration: 320.ms)
              .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              AppLocalizations.of(context).prefListsOthersHeading,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiaryFor(context),
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < others.length; i++)
              _CompactRow(overview: others[i])
                  .animate(delay: (60 * (i + 1)).ms)
                  .fadeIn(duration: 280.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          ],
          const SizedBox(height: 12),
          const _NewListRow(),
        ],
      ),
    );
  }
}

// ─── Kahraman kart ─────────────────────────────────────────────

class _HeroCard extends ConsumerWidget {
  final ListOverview overview;
  const _HeroCard({required this.overview});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final list = overview.list;
    final health = overview.health;

    return Material(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: () => context.push('/my-lists/${list.id}'),
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.30),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MainBadge(pinned: overview.pinned),
                  const SizedBox(width: 8),
                  // Gizli/açık durumu kartta kalır: listenin herkese açık
                  // olduğunu ancak paylaş sayfasını açınca görmek geç olur.
                  _VisibilityChip(list: list),
                  const Spacer(),
                  _MoreButton(
                    onTap: () =>
                        ListActionsSheet.show(context, ref, overview),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                list.title,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              _FillRow(overview: overview),
              const SizedBox(height: 14),
              if (health != null && overview.hasBalance)
                ListBalanceBar(report: health)
              else if (health == null)
                ListBalanceInvite(
                  onTap: () =>
                      navigateToRoute(context, AppRoutes.scoreCalculator),
                ),
              if (!overview.isEmpty) ...[
                const SizedBox(height: 16),
                ListLogoStack(overview: overview),
                const SizedBox(height: 14),
                for (final item in overview.topItems())
                  _TopItemRow(order: item.order, item: item),
              ],
              if (health != null && overview.hasBalance) ...[
                const SizedBox(height: 12),
                _RobotNote(comment: RobotBrain.listHealthComment(health).text),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: FilledButton(
                        onPressed: () => context.push('/my-lists/${list.id}'),
                        child: Text(
                          overview.isEmpty
                              ? loc.prefListAddDepartment
                              : loc.prefListsOpen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 46,
                    width: 46,
                    child: OutlinedButton(
                      onPressed: () => ShareListSheet.show(context, list),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Icon(Icons.ios_share_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainBadge extends StatelessWidget {
  final bool pinned;
  const _MainBadge({required this.pinned});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pinned ? Icons.push_pin_rounded : Icons.star_rounded,
            size: 13,
            color: AppColors.primary,
          ),
          const SizedBox(width: 5),
          Text(
            AppLocalizations.of(context).prefListsMainBadge,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gizli mi, herkese açık mı — açıksa görüntülenme sayısıyla.
class _VisibilityChip extends StatelessWidget {
  final PreferenceListModel list;
  const _VisibilityChip({required this.list});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final public = list.isPublic;
    final color = public ? AppColors.success : AppColors.textTertiaryFor(context);
    final label = public && list.viewCount > 0
        ? '${loc.commonPublic} · ${list.viewCount}'
        : (public ? loc.commonPublic : loc.commonPrivate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            public ? Icons.public_rounded : Icons.lock_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// "12/24" + doluluk çubuğu. Sayı sayarak değil, çubuk akarak dolar —
/// kart her açılışta minik bir hareket gösterir.
class _FillRow extends StatelessWidget {
  final ListOverview overview;
  const _FillRow({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${overview.filled}',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            Text(
              ' ${AppLocalizations.of(context)
                  .prefListItemLimit(ListOverview.capacity)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            ),
            const Spacer(),
            if (overview.remaining > 0)
              Text(
                AppLocalizations.of(context)
                    .prefListsSlotsFree(overview.remaining),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiaryFor(context),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: overview.progress),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariantFor(context),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopItemRow extends StatelessWidget {
  final int order;
  final PreferenceItem item;

  const _TopItemRow({required this.order, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$order',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiaryFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: item.uniName,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(
                    text: '  ·  ${item.deptName}',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondaryFor(context),
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RobotNote extends StatelessWidget {
  final String comment;
  const _RobotNote({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RobotAvatar(size: 24, animated: false),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              comment,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryFor(context),
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Kompakt satır ─────────────────────────────────────────────

class _CompactRow extends ConsumerWidget {
  final ListOverview overview;
  const _CompactRow({required this.overview});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = overview.health;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.push('/my-lists/${overview.id}'),
          onLongPress: () => ListActionsSheet.show(context, ref, overview),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLightFor(context)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        overview.list.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${overview.filled}/${ListOverview.capacity}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondaryFor(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (health != null && overview.hasBalance)
                            Expanded(
                              child: ListBalanceBar(
                                report: health,
                                showLabels: false,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _MoreButton(
                  onTap: () => ListActionsSheet.show(context, ref, overview),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiaryFor(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context).prefListOptions,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 20,
        color: AppColors.textTertiaryFor(context),
      ),
    );
  }
}

/// Listenin sonundaki "yeni liste" daveti — yüzen butonun yerini aldı.
class _NewListRow extends ConsumerWidget {
  const _NewListRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => CreateListSheet.show(context, ref),
        borderRadius: BorderRadius.circular(18),
        child: DottedBorderBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                loc.prefListsNewList,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Boş durum ─────────────────────────────────────────────────

/// Hiç liste yokken: Üni taslak listeyi kursun (kullanıcı kararı).
///
/// Eski hâl kaldırılan `/preference-wizard` rotasına gidiyordu — düğme
/// kırıktı. Artık Tercih Yolu'nun taslak adımına götürüyor.
class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final nudge = RobotBrain.emptyListNudge();

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RobotAvatar(size: 76, mood: nudge.mood),
            const SizedBox(height: 20),
            Text(
              loc.prefListsEmptyHeroTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              loc.prefListsEmptyHeroDesc,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryFor(context),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => navigateToRoute(
                  context,
                  '${AppRoutes.uniFlow}?step=list',
                ),
                icon: const RobotAvatar(size: 20, animated: false),
                label: Text(loc.prefListsEmptyDraftCta),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => CreateListSheet.show(context, ref),
              child: Text(loc.prefListsEmptyBlankCta),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Misafir ───────────────────────────────────────────────────

class _UnauthenticatedView extends StatelessWidget {
  const _UnauthenticatedView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loc.prefListsTitle,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariantFor(context),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_person_rounded,
                          size: 44,
                          color: AppColors.textTertiaryFor(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        loc.prefListsLoginTitle,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.prefListsLoginDesc,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondaryFor(context),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: () => context.push('/login'),
                          child: Text(
                            loc.authSignIn,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
