import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../../monetization/presentation/widgets/subscription_gate_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/comparison_type_card.dart';
import '../widgets/comparison_history_sheet.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Karşılaştırma Hub Ekranı
/// Kullanıcı hangi tür karşılaştırma yapacağını seçer:
/// Üniversite (Free), Bölüm (Plus+), Şehir (Plus+)
class ComparisonHubScreen extends ConsumerStatefulWidget {
  const ComparisonHubScreen({super.key});

  @override
  ConsumerState<ComparisonHubScreen> createState() => _ComparisonHubScreenState();
}

class _ComparisonHubScreenState extends ConsumerState<ComparisonHubScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;

  // Staggered animation delays for cards
  late List<Animation<double>> _cardFadeAnims;
  late List<Animation<Offset>> _cardSlideAnims;
  int _selectedTypeIndex = 0;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Staggered animations for 3 cards
    _cardFadeAnims = List.generate(3, (i) {
      final start = i * 0.15;
      final end = (start + 0.6).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _cardSlideAnims = List.generate(3, (i) {
      final start = i * 0.15;
      final end = (start + 0.6).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    // Animasyonları başlat
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tierAsync = ref.watch(subscriptionTierProvider);
    final canDepartment = ref.watch(canCompareDepartmentsProvider);
    final canCity = ref.watch(canCompareCitiesProvider);
    final currentTier = tierAsync.valueOrNull ?? SubscriptionTier.free;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ──────────────────────────────────────────
              _buildHeader(context, isDark),
              const SizedBox(height: 8),
              _buildSubtitle(isDark),
              const SizedBox(height: 28),

              // ─── Karşılaştırma Kartları ──────────────────────────
              _buildAnimatedCard(
                index: 0,
                child: ComparisonTypeCard(
                  icon: Icons.account_balance_rounded,
                  title: 'Üniversite',
                  description: 'İki üniversiteyi detaylı karşılaştır',
                  iconColor: AppColors.primary,
                  isLocked: false,
                  isSelected: _selectedTypeIndex == 0,
                  onTap: () {
                    setState(() => _selectedTypeIndex = 0);
                    context.push('/compare/university');
                  },
                ),
              ),
              const SizedBox(height: 14),

              _buildAnimatedCard(
                index: 1,
                child: SubscriptionGateWidget(
                  requiredTier: SubscriptionTier.plus,
                  showBlurPreview: true,
                  onLocked: () => context.push('/compare/paywall'),
                  child: ComparisonTypeCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Bölüm',
                    description: 'Aynı bölümü farklı üniversitelerde karşılaştır',
                    iconColor: AppColors.tierPlus,
                    isLocked: !canDepartment,
                    requiredTier: SubscriptionTier.plus,
                    isSelected: _selectedTypeIndex == 1,
                    onTap: () {
                      setState(() => _selectedTypeIndex = 1);
                      context.push('/compare/department');
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _buildAnimatedCard(
                index: 2,
                child: SubscriptionGateWidget(
                  requiredTier: SubscriptionTier.plus,
                  showBlurPreview: true,
                  onLocked: () => context.push('/compare/paywall'),
                  child: ComparisonTypeCard(
                    icon: Icons.location_city_rounded,
                    title: 'Şehir',
                    description: 'İki şehrin üniversite ekosistemini karşılaştır',
                    iconColor: AppColors.tierPlus,
                    isLocked: !canCity,
                    requiredTier: SubscriptionTier.plus,
                    isSelected: _selectedTypeIndex == 2,
                    onTap: () {
                      setState(() => _selectedTypeIndex = 2);
                      context.push('/compare/city');
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ─── Abonelik durumu footer ─────────────────────────
              _buildSubscriptionFooter(context, isDark, currentTier),

              const SizedBox(height: 80), // Bottom nav space
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Dekoratif çizgi
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppLocalizations.of(context).comparisonHubTitle,
            style: AppTextStyles.displaySmall.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        // Geçmiş butonu — tüm tier'larda görünür, içerik tier'a göre değişir.
        IconButton(
          icon: Icon(
            Icons.history_rounded,
            color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
          ),
          tooltip: 'Karşılaştırma geçmişi',
          onPressed: () => ComparisonHistorySheet.show(context),
        ),
      ],
    );
  }

  Widget _buildSubtitle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        'Hangi tür karşılaştırma yapmak istiyorsun?',
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark
              ? Colors.white.withValues(alpha: 0.6)
              : AppColors.textSecondaryFor(context),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({required int index, required Widget child}) {
    return FadeTransition(
      opacity: _cardFadeAnims[index],
      child: SlideTransition(
        position: _cardSlideAnims[index],
        child: child,
      ),
    );
  }

  Widget _buildSubscriptionFooter(
    BuildContext context,
    bool isDark,
    SubscriptionTier currentTier,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.tierPro.withValues(alpha: 0.05),
                ],
              )
            : LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.04),
                  AppColors.tierPro.withValues(alpha: 0.03),
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Sol taraf - abonelik bilgisi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _tierIcon(currentTier),
                      size: 18,
                      color: _tierColor(currentTier),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Aboneliğin',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _tierLabel(currentTier),
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _tierColor(currentTier),
                  ),
                ),
              ],
            ),
          ),
          // Sağ taraf - upgrade butonu
          if (currentTier == SubscriptionTier.free)
            FilledButton.icon(
              onPressed: () => context.push('/compare/paywall'),
              icon: const Icon(Icons.rocket_launch_rounded, size: 18),
              label: const Text("Plus'a Geç"),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _tierIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.plus:
        return Icons.star_rounded;
      case SubscriptionTier.pro:
        return Icons.workspace_premium_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

  Color _tierColor(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.plus:
        return AppColors.tierPlus;
      case SubscriptionTier.pro:
        return AppColors.tierPro;
      default:
        return AppColors.tierFree;
    }
  }

  String _tierLabel(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.plus:
        return 'Plus';
      case SubscriptionTier.pro:
        return 'Pro';
      default:
        return 'Ücretsiz';
    }
  }
}
