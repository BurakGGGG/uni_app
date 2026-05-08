import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';

/// SubscriptionGateWidget — UI Shell
/// Kişi A'nın logic'ini bekliyor. Şimdilik sadece UI kısmı hazır.
///
/// Kullanım:
/// ```dart
/// SubscriptionGateWidget(
///   requiredTier: 'plus',     // 'plus' veya 'pro'
///   currentTier: 'free',      // A'nın provider'ından gelecek
///   featureName: 'Bölüm Karşılaştırma',
///   child: DepartmentComparisonScreen(),
/// )
/// ```
///
/// currentTier >= requiredTier ise child'ı gösterir,
/// değilse bulanık overlay + kilit ikonu + paywall CTA gösterir.
class SubscriptionGateWidget extends ConsumerWidget {
  /// Gerekli minimum tier.
  final SubscriptionTier requiredTier;

  /// Erişim engelli kısımdaki özellik adı
  final String featureName;

  /// Tier yeterliyse gösterilecek widget
  final Widget child;

  /// Opsiyonel: kilit durumunda gösterilecek özel fallback
  final Widget? lockedFallback;

  /// Kilitliyse child önizlemesini blur göster.
  final bool showBlurPreview;

  const SubscriptionGateWidget({
    super.key,
    required this.requiredTier,
    required this.featureName,
    required this.child,
    this.lockedFallback,
    this.showBlurPreview = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierAsync = ref.watch(subscriptionTierProvider);

    return tierAsync.when(
      data: (tier) {
        if (tier.satisfies(requiredTier)) {
          return child;
        }
        if (lockedFallback != null) return lockedFallback!;
        return _DefaultLockedView(
          requiredTier: requiredTier,
          featureName: featureName,
          showBlurPreview: showBlurPreview,
          child: child,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => child,
    );
  }
}

/// Varsayılan kilit görünümü — blur overlay + kilit ikonu + CTA
class _DefaultLockedView extends StatelessWidget {
  final SubscriptionTier requiredTier;
  final String featureName;
  final Widget child;
  final bool showBlurPreview;

  const _DefaultLockedView({
    required this.requiredTier,
    required this.featureName,
    required this.child,
    required this.showBlurPreview,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tierColor =
        requiredTier == SubscriptionTier.pro ? AppColors.tierPro : AppColors.tierPlus;
    final tierLabel = requiredTier.label;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Alt katman — bulanık içerik önizlemesi
          if (showBlurPreview)
            Positioned.fill(
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Opacity(opacity: 0.4, child: child),
                ),
              ),
            ),
          if (!showBlurPreview)
            Positioned.fill(
              child: Container(color: Colors.transparent),
            ),

          // Üst katman — kilit overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Kilit ikonu
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: tierColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Mesaj
                  Text(
                    featureName,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$tierLabel veya üstü gerekli',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Paywall CTA
                  FilledButton.icon(
                    onPressed: () => context.push('/compare/paywall'),
                    icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                    label: Text('$tierLabel\'a Geç'),
                    style: FilledButton.styleFrom(
                      backgroundColor: tierColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: AppTextStyles.labelMedium
                          .copyWith(fontWeight: FontWeight.w700),
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
