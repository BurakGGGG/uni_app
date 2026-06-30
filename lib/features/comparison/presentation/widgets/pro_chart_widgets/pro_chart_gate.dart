import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../monetization/domain/enums/subscription_tier.dart';
import '../../../../monetization/presentation/widgets/subscription_gate_widget.dart';
import '../../../../monetization/data/ad_service.dart';
import '../../../../monetization/presentation/providers/temporary_pro_access_provider.dart';
import '../../../../../services/analytics_service.dart';
import '../../../../admin/data/analytics_service.dart' as firestore_analytics;
import '../../../../admin/domain/models/analytics_event.dart';

class ProChartGate extends StatelessWidget {
  final String title;
  final Widget child;

  const ProChartGate({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SubscriptionGateWidget(
      requiredTier: SubscriptionTier.pro,
      allowTemporaryAccess: true,
      showBlurPreview: true,
      onLocked: () => context.push('/compare/paywall'),
      lockedFallback: _ProOverlay(title: title, child: child),
      child: child,
    );
  }
}

class _ProOverlay extends ConsumerWidget {
  final String title;
  final Widget child;
  const _ProOverlay({required this.title, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          // Bulanık önizleme — Stack'e boyutunu veren normal (positioned olmayan)
          // child. Aksi halde scroll view içinde (sınırsız yükseklik) Stack
          // "infinite size" hatası verir ve sekme boş kalır.
          IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Opacity(opacity: 0.35, child: child),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.72),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.tierPro, AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.proChartLockedSubtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? Colors.white70 : AppColors.textSecondaryFor(context),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => context.push('/compare/paywall'),
                          icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                          label: Text(loc.viewProPlans),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.tierPro,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(loc.adLoading),
                                duration: const Duration(seconds: 2),
                              ),
                            );

                            final success = await AdService().showRewardedAd();
                            await AnalyticsService().logRewardedAdResult(
                              placement: 'pro_chart',
                              completed: success,
                            );
                            if (success) {
                              await ref.read(temporaryProAccessProvider.notifier).unlockProForOneHour();
                              await AnalyticsService().logTempProUnlocked(source: 'pro_chart');
                              firestore_analytics.AnalyticsService.instance
                                  .trackEvent(AnalyticsEvent.adWatched);
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(loc.proChartsUnlockedOneHour),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(loc.adFailedRetry),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                          label: Text(loc.watchAdUnlockOneHour),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.tierPro),
                            foregroundColor: AppColors.tierPro,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

