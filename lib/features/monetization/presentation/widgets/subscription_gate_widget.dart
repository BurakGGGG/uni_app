import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/subscription_tier.dart';
import '../providers/subscription_providers.dart';

/// Abonelik tier'ına göre içerik gating widget'ı.
///
/// [requiredTier] — erişim için gereken minimum tier.
/// [child] — erişim varsa gösterilecek widget.
/// [lockedFallback] — erişim yoksa gösterilecek widget (null ise varsayılan kilit ekranı).
/// [onLocked] — erişim yokken child'a tıklanırsa çağrılır (paywall yönlendirme vb.)
///
/// Kullanım:
/// ```dart
/// SubscriptionGateWidget(
///   requiredTier: SubscriptionTier.plus,
///   child: DepartmentComparisonButton(),
///   onLocked: () => context.push('/compare/paywall'),
/// )
/// ```
class SubscriptionGateWidget extends ConsumerWidget {
  final SubscriptionTier requiredTier;
  final Widget child;
  final Widget? lockedFallback;
  final VoidCallback? onLocked;

  /// Kilitli durumda child'ı blur ile göster mi?
  final bool showBlurPreview;

  const SubscriptionGateWidget({
    super.key,
    required this.requiredTier,
    required this.child,
    this.lockedFallback,
    this.onLocked,
    this.showBlurPreview = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierAsync = ref.watch(subscriptionTierProvider);

    return tierAsync.when(
      data: (currentTier) {
        // Tier yeterli — içeriği göster
        if (currentTier.satisfies(requiredTier)) {
          return child;
        }

        // Tier yetersiz — kilitli görünüm
        if (lockedFallback != null) {
          return GestureDetector(
            onTap: onLocked,
            child: lockedFallback!,
          );
        }

        // Varsayılan kilitli görünüm
        if (showBlurPreview) {
          return _BlurLockedOverlay(
            requiredTier: requiredTier,
            onTap: onLocked,
            child: child,
          );
        }

        return _DefaultLockedWidget(
          requiredTier: requiredTier,
          onTap: onLocked,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => child, // Hata durumunda erişim ver (graceful)
    );
  }
}

/// Blurlanmış önizleme + kilit overlay'ı.
class _BlurLockedOverlay extends StatelessWidget {
  final SubscriptionTier requiredTier;
  final VoidCallback? onTap;
  final Widget child;

  const _BlurLockedOverlay({
    required this.requiredTier,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierColor = requiredTier == SubscriptionTier.pro
        ? AppColors.tierPro // Altın
        : AppColors.tierPlus; // Mor

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Blurlu içerik
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.white38,
                  BlendMode.lighten,
                ),
                child: IgnorePointer(child: child),
              ),
            ),

            // Kilit overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.74),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: tierColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _requiredTierTitle(requiredTier),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _requiredTierDescription(requiredTier),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _requiredTierDescription(SubscriptionTier tier) {
    if (tier == SubscriptionTier.plus) {
      return 'Bölüm ve şehir sıralamalarını açmak için Plus gerekir (Pro da açar).';
    }
    if (tier == SubscriptionTier.pro) {
      return 'Pro grafiklerini açmak için Pro gerekir.';
    }
    return 'Bu özellik için uygun bir plan gerekir';
  }

  String _requiredTierTitle(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.plus:
        return 'Bölüm & Şehir Sıralamaları';
      case SubscriptionTier.pro:
        return 'Pro Grafikler';
      case SubscriptionTier.free:
        return 'Üyelik';
    }
  }
}

/// Varsayılan kilitli widget (blur olmadan).
class _DefaultLockedWidget extends StatelessWidget {
  final SubscriptionTier requiredTier;
  final VoidCallback? onTap;

  const _DefaultLockedWidget({
    required this.requiredTier,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierColor = requiredTier == SubscriptionTier.pro
        ? AppColors.tierPro
        : AppColors.tierPlus;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tierColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: tierColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '${requiredTier.label} Gerekli',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tierColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
