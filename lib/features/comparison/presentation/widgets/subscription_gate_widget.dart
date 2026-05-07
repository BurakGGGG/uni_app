import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

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
class SubscriptionGateWidget extends StatelessWidget {
  /// Gerekli minimum tier: 'plus' veya 'pro'
  final String requiredTier;

  /// Kullanıcının mevcut tier'ı: 'free', 'plus', 'pro'
  /// TODO: Kişi A'nın subscriptionTierProvider'ına bağlanacak
  final String currentTier;

  /// Erişim engelli kısımdaki özellik adı
  final String featureName;

  /// Tier yeterliyse gösterilecek widget
  final Widget child;

  /// Opsiyonel: kilit durumunda gösterilecek özel fallback
  final Widget? lockedFallback;

  const SubscriptionGateWidget({
    super.key,
    required this.requiredTier,
    this.currentTier = 'free', // TODO: Provider'dan gelecek
    required this.featureName,
    required this.child,
    this.lockedFallback,
  });

  bool get _hasAccess {
    const tierOrder = {'free': 0, 'plus': 1, 'pro': 2};
    return (tierOrder[currentTier] ?? 0) >= (tierOrder[requiredTier] ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasAccess) return child;
    if (lockedFallback != null) return lockedFallback!;
    return _DefaultLockedView(
      requiredTier: requiredTier,
      featureName: featureName,
      child: child,
    );
  }
}

/// Varsayılan kilit görünümü — blur overlay + kilit ikonu + CTA
class _DefaultLockedView extends StatelessWidget {
  final String requiredTier;
  final String featureName;
  final Widget child;

  const _DefaultLockedView({
    required this.requiredTier,
    required this.featureName,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tierColor =
        requiredTier == 'pro' ? AppColors.tierPro : AppColors.tierPlus;
    final tierLabel = requiredTier == 'pro' ? 'Pro' : 'Plus';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Alt katman — bulanık içerik önizlemesi
          Positioned.fill(
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Opacity(opacity: 0.4, child: child),
              ),
            ),
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
