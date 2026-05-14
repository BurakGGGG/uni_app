import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/models/comparison_result.dart';
import '../providers/comparison_providers.dart';
import '../widgets/comparison_uni_picker.dart';
import '../widgets/comparison_header.dart';
import '../widgets/comparison_category_row.dart';
import '../widgets/comparison_stats_table.dart';
import '../widgets/comparison_share_card.dart';
import '../widgets/comparison_radar_chart.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ComparisonScreen extends ConsumerWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(comparisonSelectionProvider);
    final resultAsync = ref.watch(comparisonResultProvider);
    final gateLocked = ref.watch(comparisonAdGateLockedProvider);
    final gateBusy = ref.watch(comparisonAdGateBusyProvider);

    // Gate kararını dinle — izin verilmediyse locked overlay'i göster
    final gateDecision = ref.watch(comparisonGateDecisionProvider);
    gateDecision.whenData((decision) {
      if (decision != null && !decision.isAllowed) {
        // Sadece henüz locked değilse güncelle (rebuild döngüsünü kır)
        Future.microtask(() {
          if (ref.read(comparisonAdGateLockedProvider) != true) {
            ref.read(comparisonAdGateLockedProvider.notifier).state = true;
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child:
                            Text('Karşılaştır', style: AppTextStyles.displaySmall),
                      ),
                      if (selection.uniIdA != null || selection.uniIdB != null)
                        TextButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Sıfırla'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                            backgroundColor:
                                AppColors.error.withValues(alpha: 0.08),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                              ref.read(comparisonSelectionProvider.notifier).reset();
                              ref.read(comparisonAdGateLockedProvider.notifier).state = false;
                            },
                        ),
                      if (selection.bothSelected) ...[
                        IconButton(
                          icon: const Icon(Icons.swap_horiz_rounded),
                          tooltip: 'Yer Değiştir',
                          onPressed: () =>
                              ref.read(comparisonSelectionProvider.notifier).swap(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.ios_share_rounded),
                          tooltip: 'Paylaş',
                          onPressed: () async {
                            final result = resultAsync.valueOrNull;
                            if (result != null) {
                              await ComparisonShareCard.shareCard(context, result);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Üniversiteleri yan yana kıyasla',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  const ComparisonUniPicker(),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _buildBody(context, selection, resultAsync),
                  ),
                ],
              ),
            ),

            if (gateLocked)
              Positioned.fill(
                child: _ComparisonAdGateOverlay(
                  isBusy: gateBusy,
                  onCtaPressed: () => _showAdGateModal(context: context),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: selection.bothSelected && resultAsync.valueOrNull != null
          ? SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
                ),
                child: _ComparisonFloatingActionBar(
                  result: resultAsync.value!,
                  onShare: () => ComparisonShareCard.shareCard(context, resultAsync.value!),
                  onFavorite: () => _showFavoriteModal(
                    context: context,
                    ref: ref,
                    result: resultAsync.value!,
                  ),
                  onRecompare: () {
                    ref.read(comparisonSelectionProvider.notifier).reset();
                    ref.read(comparisonAdGateLockedProvider.notifier).state = false;
                    ref.invalidate(comparisonResultProvider);
                  },
                ),
              ),

            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    ComparisonSelection selection,
    AsyncValue<ComparisonResult?> resultAsync,
  ) {
    if (!selection.bothSelected) {
      return const _EmptyState();
    }

    return resultAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(child: Text('Hata: $e')),
      data: (result) {
        if (result == null) return const _EmptyState();
        return _ResultView(result: result);
      },
    );
  }
}

/// UI state for rewarded-ad gate. Kişi A'nın limit/ad logic'i bu provider'ları set edecek.
final comparisonAdGateLockedProvider = StateProvider<bool>((ref) => false);
final comparisonAdGateBusyProvider = StateProvider<bool>((ref) => false);

Future<void> _showAdGateModal({
  required BuildContext context,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final isGuest = ref.watch(authStateProvider).valueOrNull == null;

          return SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ─── İkon ─────────────────────────────
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.secondary.withValues(alpha: 0.10),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isGuest
                          ? Icons.play_circle_outline_rounded
                          : Icons.lock_outline_rounded,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── Başlık ────────────────────────────
                  Text(
                    isGuest
                        ? 'Reklam ile Karşılaştır'
                        : 'Ücretsiz hakkın bitti',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ─── Açıklama ──────────────────────────
                  Text(
                    isGuest
                        ? 'Karşılaştırma yapmak için kısa bir reklam izlemen gerekiyor. '
                          'Giriş yap veya Plus\'a geçerek sınırsız karşılaştırma yapabilirsin.'
                        : 'Günlük 1 ücretsiz karşılaştırma hakkını kullandın. '
                          'Devam etmek için kısa bir reklam izleyebilir veya '
                          'Plus\'a geçerek sınırsız karşılaştırma yapabilirsin.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── Butonlar ──────────────────────────
                  Consumer(
                    builder: (context, ref2, _) {
                      final busy = ref2.watch(comparisonAdGateBusyProvider);
                      return Column(
                        children: [
                          // Reklam butonu
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: busy
                                  ? null
                                  : () async {
                                      ref2
                                          .read(comparisonAdGateBusyProvider.notifier)
                                          .state = true;
                                      // Reklam hazırlama süresi
                                      await Future<void>.delayed(
                                          const Duration(milliseconds: 900));
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                      ref2
                                          .read(comparisonAdGateBusyProvider.notifier)
                                          .state = false;
                                      ref2
                                          .read(comparisonAdGateLockedProvider.notifier)
                                          .state = false;
                                    },
                              icon: busy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white70,
                                      ),
                                    )
                                  : const Icon(Icons.smart_display_rounded, size: 18),
                              label: Text(
                                busy ? 'Reklam hazırlanıyor…' : 'Reklamı İzle ve Devam Et',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                textStyle: AppTextStyles.labelLarge
                                    .copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Plus'a Geç butonu
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: busy
                                  ? null
                                  : () {
                                      Navigator.of(context).pop();
                                    },
                              icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                              label: const Text('Plus\'a Geç — Sınırsız'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    isDark ? Colors.white : AppColors.textPrimary,
                                side: BorderSide(
                                  color: (isDark ? Colors.white : AppColors.textPrimary)
                                      .withValues(alpha: 0.16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                textStyle: AppTextStyles.labelLarge
                                    .copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Kapat butonu
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text(
                              'Şimdilik Vazgeç',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isDark ? Colors.white38 : AppColors.textTertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _showFavoriteModal({
  required BuildContext context,
  required WidgetRef ref,
  required ComparisonResult result,
}) async {
  final auth = ref.read(authStateProvider).valueOrNull;
  if (auth == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Favori için giriş yapmalısın.')),
    );
    return;
  }

  final favorites = ref.read(favoritesProvider).valueOrNull ?? const <String>[];
  final aFav = favorites.contains(result.uniA.id);
  final bFav = favorites.contains(result.uniB.id);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Favorilere ekle',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _FavoriteChoiceTile(
                title: result.uniA.name,
                isFavorite: aFav,
                onTap: () async {
                  await ref.read(favoritesControllerProvider.notifier).toggleFavorite(
                        auth.uid,
                        result.uniA.id,
                        aFav,
                      );
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              _FavoriteChoiceTile(
                title: result.uniB.name,
                isFavorite: bFav,
                onTap: () async {
                  await ref.read(favoritesControllerProvider.notifier).toggleFavorite(
                        auth.uid,
                        result.uniB.id,
                        bFav,
                      );
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
    },
  );
}

class _FavoriteChoiceTile extends StatelessWidget {
  final String title;
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteChoiceTile({
    required this.title,
    required this.isFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite ? AppColors.error : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComparisonFloatingActionBar extends StatelessWidget {
  final ComparisonResult result;
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final VoidCallback onRecompare;

  const _ComparisonFloatingActionBar({
    required this.result,
    required this.onShare,
    required this.onFavorite,
    required this.onRecompare,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white)
                    .withValues(alpha: isDark ? 0.35 : 0.70),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionPill(
                      icon: Icons.ios_share_rounded,
                      label: 'Paylaş',
                      onTap: onShare,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionPill(
                      icon: Icons.favorite_rounded,
                      label: 'Favorile',
                      onTap: onFavorite,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionPill(
                      icon: Icons.refresh_rounded,
                      label: 'Yeniden',
                      onTap: onRecompare,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isDark ? Colors.white : AppColors.textPrimary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComparisonAdGateOverlay extends ConsumerWidget {
  final bool isBusy;
  final VoidCallback onCtaPressed;

  const _ComparisonAdGateOverlay({
    required this.isBusy,
    required this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGuest = ref.watch(authStateProvider).valueOrNull == null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (isDark ? Colors.black : Colors.white)
                            .withValues(alpha: 0.55),
                        (isDark ? Colors.black : Colors.white)
                            .withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isGuest
                          ? Icons.play_circle_outline_rounded
                          : Icons.lock_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isGuest
                        ? 'Reklam izleyerek devam et'
                        : 'Devam etmek için kilidi aç',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isGuest
                        ? 'Karşılaştırma için kısa bir reklam izlemen gerekiyor.'
                        : 'Günlük karşılaştırma hakkın doldu.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isBusy ? null : onCtaPressed,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: AppTextStyles.labelLarge
                            .copyWith(fontWeight: FontWeight.w900),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isBusy) ...[
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                          ] else ...[
                            const Icon(Icons.smart_display_rounded, size: 18),
                            const SizedBox(width: 10),
                          ],
                          Text(isBusy ? 'Yükleniyor…' : 'Reklamı İzle / Plus’a Geç'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: EmptyStateWidget(
        illustration: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: SvgPicture.asset(
            'assets/icons/compare_icon.svg',
            width: 56,
            height: 56,
          ),
        ),
        title: 'İki üniversite seç',
        description:
            'Yukarıdan iki üniversite seçince karşılaştırma sonuçları burada gözükür.',
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final ComparisonResult result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ComparisonHeader(result: result),
        const SizedBox(height: 24),
        _SectionTitle('Kategori Puanları'),
            if (result.categoryComparisons.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: EmptyStateWidget(
                  illustration: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rate_review_rounded, size: 32, color: AppColors.primary),
                  ),
                  title: 'Yeterli değerlendirme yok',
                  description:
                      'Bu iki üniversite için henüz kategori puanı oluşturacak yorum bulunmuyor.',
                ),
              )
            else
              ...result.categoryComparisons.values.map(
                (c) => ComparisonCategoryRow(
                  comparison: c,
                  uniAId: result.uniA.id,
                  uniBId: result.uniB.id,
                ),
              ),
        const SizedBox(height: 24),
        _SectionTitle('Genel Görünüm'),
            if (result.categoryComparisons.isEmpty)
              const SizedBox.shrink()
            else
              ComparisonRadarChart(result: result),
        const SizedBox(height: 24),
        _SectionTitle('Genel İstatistikler'),
        ComparisonStatsTable(result: result),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}