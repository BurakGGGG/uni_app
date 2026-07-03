import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../../university/presentation/widgets/score_badge.dart';
import '../providers/preference_list_providers.dart';
import '../../domain/models/preference_list_model.dart';
import '../../../../core/widgets/user_avatar.dart';

class SharedListScreen extends ConsumerWidget {
  final String shareSlug;
  const SharedListScreen({super.key, required this.shareSlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final listAsync = ref.watch(publicListBySlugProvider(shareSlug));
    final isLoggedIn = ref.watch(authStateProvider).value != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: SafeArea(
        child: listAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => _NotFoundView(message: loc.prefSharedListLoadError),
          data: (list) {
            if (list == null) return const _NotFoundView();
            return Column(
              children: [
                Expanded(child: _buildList(context, list, isLoggedIn)),
                _ActionBar(list: list, shareSlug: shareSlug),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(
      BuildContext context, PreferenceListModel list, bool isLoggedIn) {
    final loc = AppLocalizations.of(context);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Top bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimaryFor(context)),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                const Spacer(),
                if (!isLoggedIn)
                  TextButton(
                    onPressed: () => context.push('/login'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(
                      loc.authSignIn,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loc.prefSharedListBadge,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  list.title,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                if (list.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    list.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondaryFor(context),
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Author + stats
                Row(
                  children: [
                    UserAvatar(
                      photoUrl: list.userPhotoUrl,
                      name: list.userName,
                      size: 36,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            list.userName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            loc.prefSharedListOwner,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondaryFor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariantFor(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.format_list_numbered_rounded,
                              size: 14, color: AppColors.textSecondaryFor(context)),
                          const SizedBox(width: 4),
                          Text(
                            loc.prefListItemCount(list.items.length),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondaryFor(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (list.items.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyView(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            sliver: SliverList.separated(
              itemCount: list.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _SharedItemCard(
                item: list.items[i],
                index: i,
              ),
            ),
          ),
      ],
    );
  }
}

/// Alt aksiyon çubuğu: salt görüntüleme bildirimi + kopyalama/düzenleme aksiyonu.
///
/// - Liste sahibi → kendi listesini düzenlemeye gider.
/// - Plus/Pro → listeyi kendi hesabına kopyalar (orijinal DEĞİŞMEZ).
/// - Free → paywall yönlendirmeli bilgi sheet'i.
/// - Giriş yapmamış → login'e yönlendirilir (dönüşte buraya gelir).
class _ActionBar extends ConsumerStatefulWidget {
  final PreferenceListModel list;
  final String shareSlug;
  const _ActionBar({required this.list, required this.shareSlug});

  @override
  ConsumerState<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends ConsumerState<_ActionBar> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;
    final isOwner = user != null && user.uid == widget.list.userId;
    // Stream'i canlı tut: tıklama anında tier değeri hazır olsun (autoDispose).
    ref.watch(subscriptionTierProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        border: Border(
          top: BorderSide(color: AppColors.borderLightFor(context)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 14,
                color: AppColors.textTertiaryFor(context),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  isOwner
                      ? loc.prefSharedCopyOwnList
                      : loc.prefSharedReadOnlyNotice,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryFor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _busy ? null : () => _onPressed(isOwner),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isOwner
                          ? Icons.edit_rounded
                          : Icons.copy_all_rounded,
                      size: 20,
                    ),
              label: Text(
                isOwner ? loc.prefSharedEditOwnList : loc.prefSharedCopyButton,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onPressed(bool isOwner) async {
    final loc = AppLocalizations.of(context);

    // Sahibi kendisi → düzenleme ekranına git.
    if (isOwner) {
      context.push('/my-lists/${widget.list.id}');
      return;
    }

    // Giriş yapılmamış → login'e yönlendir, dönüşte bu sayfaya gelsin.
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      final from = Uri.encodeComponent('/list/${widget.shareSlug}');
      context.push('/login?from=$from');
      return;
    }

    // Free kullanıcı → paywall yönlendirmeli bilgi sheet'i.
    final tier = ref.read(subscriptionTierProvider).valueOrNull ??
        SubscriptionTier.free;
    if (!tier.satisfies(SubscriptionTier.plus)) {
      _showUpsellSheet();
      return;
    }

    // Plus/Pro → kopyala ve düzenlemeye git (orijinal liste değişmez).
    setState(() => _busy = true);
    try {
      final copy = await ref
          .read(preferenceListControllerProvider.notifier)
          .copy(widget.list);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.prefSharedCopySuccess),
          duration: const Duration(seconds: 3),
        ),
      );
      context.push('/my-lists/${copy.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.errorGeneral(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showUpsellSheet() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.borderLightFor(sheetContext),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.prefSharedCopyPaywallTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.prefSharedCopyPaywallDesc,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryFor(sheetContext),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.push('/compare/paywall');
                },
                child: Text(
                  loc.prefSharedCopyPaywallButton,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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

class _SharedItemCard extends StatelessWidget {
  final PreferenceItem item;
  final int index;
  const _SharedItemCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final brand = _hexToColor(item.uniBrandHex) ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: AppColors.softShadowFor(context),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: brand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: brand,
                  fontWeight: FontWeight.w800,
                  fontSize: index < 9 ? 18 : 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.deptName,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.scoreType != null) ...[
                      const SizedBox(width: 6),
                      ScoreBadge.scoreType(item.scoreType!, small: true),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.uniName,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_hasScore) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (item.baseScore != null && item.baseScore! > 0)
                        _Pill(
                          icon: Icons.trending_up_rounded,
                          color: AppColors.primary,
                          value: item.baseScore!.toStringAsFixed(2),
                        ),
                      if (item.ranking != null && item.ranking! > 0)
                        _Pill(
                          icon: Icons.emoji_events_rounded,
                          color: AppColors.warning,
                          value: _formatRank(item.ranking!),
                        ),
                      if (item.quota != null && item.quota! > 0)
                        _Pill(
                          icon: Icons.people_alt_rounded,
                          color: AppColors.info,
                          value: item.placedCount != null
                              ? '${item.placedCount}/${item.quota}'
                              : '${item.quota}',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasScore =>
      (item.baseScore != null && item.baseScore! > 0) ||
      (item.ranking != null && item.ranking! > 0) ||
      (item.quota != null && item.quota! > 0);

  static String _formatRank(int rank) {
    if (rank >= 1000000) return '${(rank / 1000000).toStringAsFixed(1)}M';
    if (rank >= 1000) return '${(rank / 1000).toStringAsFixed(0)}B';
    return '$rank';
  }

  static Color? _hexToColor(String? hex) {
    if (hex == null) return null;
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    return v != null ? Color(v) : null;
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  const _Pill({
    required this.icon,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantFor(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 36,
                color: AppColors.textTertiaryFor(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.prefListEmptyItemsTitle,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.prefSharedListEmptyDesc,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  final String? message;
  const _NotFoundView({this.message});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.link_off_rounded,
                size: 44,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message ?? loc.prefListNotFound,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.prefSharedListHiddenOrDeleted,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryFor(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  } else {
                    GoRouter.of(context).go('/home');
                  }
                },
                child: Text(
                  loc.prefSharedListBackHome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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
