import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../../services/revenuecat_service.dart';
import '../../../../services/ab_test_service.dart';
import '../../../../services/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/subscription_model.dart';
import '../../domain/enums/subscription_tier.dart';

/// Paywall Ekranı — Tier-reactive UI
/// Üstte Ücretsiz/Plus/Pro chip seçicisi, ortada özellik listesi,
/// altta Aylık/Yıllık fiyat kartları. Pro = altın-turuncu, Plus = mor gradient.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with TickerProviderStateMixin {
  final RevenueCatService _revenueCatService = RevenueCatService();

  SubscriptionTier _selectedTier = SubscriptionTier.plus;
  String _paywallVariant = 'A';
  bool _isYearly = true;
  bool _isPurchasing = false;
  bool _isRestoring = false;
  bool _isLoadingOfferings = true;
  bool _loadError = false;
  Offerings? _offerings;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    // ─── A/B paywall varyantı ────────────────────────────────────
    final raw = ABTestService().getPaywallVariant();
    _paywallVariant = (raw == 'B' || raw == 'C') ? raw : 'A';
    // Varyant B: varsayılan olarak Pro'yu öne çıkar (kontrol: Plus).
    if (_paywallVariant == 'B') {
      _selectedTier = SubscriptionTier.pro;
    }
    AnalyticsService().logPaywallOpened(variant: _paywallVariant);

    _loadOfferings();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ─── Tier data ────────────────────────────────────────────────────
  static const Map<SubscriptionTier, _PlanData> _plans = {
    SubscriptionTier.free: _PlanData(
      name: 'Ücretsiz',
      monthlyPrice: 'Bedava',
      yearlyPrice: 'Bedava',
      icon: Icons.person_outline_rounded,
      subtitle: 'Temel karşılaştırma özelliklerine sınırlı erişim.',
      features: [
        _FeatureItem('Üniversite karşılaştırma (1/gün)', true),
        _FeatureItem('Bölüm karşılaştırma', false),
        _FeatureItem('Şehir karşılaştırma', false),
        _FeatureItem('AI karşılaştırma özeti', false),
        _FeatureItem('Pro grafikler', false),
      ],
    ),
    SubscriptionTier.plus: _PlanData(
      name: 'Plus',
      monthlyPrice: '39.90₺/ay',
      yearlyPrice: '32.90₺/ay',
      icon: Icons.star_rounded,
      subtitle: 'Sınırsız karşılaştırma + reklamsız deneyim.',
      features: [
        _FeatureItem('Sınırsız üniversite karşılaştırma', true),
        _FeatureItem('Bölüm karşılaştırma', true),
        _FeatureItem('Şehir karşılaştırma', true),
        _FeatureItem('Reklam yok', true),
        _FeatureItem('AI karşılaştırma özeti', false),
        _FeatureItem('Pro grafikler', false),
      ],
    ),
    SubscriptionTier.pro: _PlanData(
      name: 'Pro',
      monthlyPrice: '69.90₺/ay',
      yearlyPrice: '58.90₺/ay',
      icon: Icons.workspace_premium_rounded,
      subtitle: 'Yapay zeka destekli analiz + tüm Plus özellikleri.',
      features: [
        _FeatureItem('Plus dahil tüm özellikler', true),
        _FeatureItem('AI karşılaştırma özeti (5/gün)', true),
        _FeatureItem('AI öneri asistanı (10/gün)', true),
        _FeatureItem('Pro grafik paketi', true),
        _FeatureItem('Trend & scatter grafikler', true),
        _FeatureItem('Isı haritası', true),
      ],
    ),
  };

  _PlanData get _currentPlan => _plans[_selectedTier]!;

  // ─── Tier theme helpers ───────────────────────────────────────────
  LinearGradient _activeGradient(SubscriptionTier t) {
    switch (t) {
      case SubscriptionTier.pro:
        return AppColors.tierProGradient;
      case SubscriptionTier.plus:
        return AppColors.tierPlusGradient;
      case SubscriptionTier.free:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.tierFree,
            AppColors.tierFree.withValues(alpha: 0.7),
          ],
        );
    }
  }

  Color _activeColor(SubscriptionTier t) {
    switch (t) {
      case SubscriptionTier.pro:
        return AppColors.tierPro;
      case SubscriptionTier.plus:
        return AppColors.tierPlus;
      case SubscriptionTier.free:
        return AppColors.tierFree;
    }
  }

  // ─── RevenueCat (korunuyor) ───────────────────────────────────────
  Future<void> _loadOfferings() async {
    setState(() {
      _isLoadingOfferings = true;
      _loadError = false;
    });
    try {
      final offerings = await _revenueCatService.getOfferings();
      if (!mounted) return;
      setState(() {
        _offerings = offerings;
        _isLoadingOfferings = false;
        _loadError = offerings == null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingOfferings = false;
        _loadError = true;
      });
    }
  }

  Package? _resolvePackage() => _resolvePackageFor(_selectedTier, _isYearly);

  Package? _resolvePackageFor(SubscriptionTier tier, bool wantYearly) {
    final offerings = _offerings;
    if (offerings == null || offerings.current == null) return null;
    if (tier == SubscriptionTier.free) return null;

    final isPlus = tier == SubscriptionTier.plus;
    final packages = offerings.current!.availablePackages;
    final wantedProductId = isPlus
        ? (wantYearly
            ? RevenueCatProductIds.plusYearly
            : RevenueCatProductIds.plusMonthly)
        : (wantYearly
            ? RevenueCatProductIds.proYearly
            : RevenueCatProductIds.proMonthly);

    Package? best;
    for (final p in packages) {
      final id = p.identifier.toLowerCase();
      final matchPlan = id.contains(wantedProductId.toLowerCase()) ||
          (isPlus ? id.contains('plus') : id.contains('pro'));
      if (!matchPlan) continue;
      final matchPeriod = wantYearly
          ? p.packageType == PackageType.annual
          : p.packageType == PackageType.monthly;
      if (matchPeriod) return p;
      best ??= p;
    }

    for (final p in packages) {
      if (wantYearly && p.packageType == PackageType.annual) return p;
      if (!wantYearly && p.packageType == PackageType.monthly) return p;
    }
    return best;
  }

  /// Pakette ücretsiz deneme (intro offer, price == 0) varsa kullanıcıya
  /// gösterilecek metni döndürür; yoksa null (mağazada deneme tanımlı değilse
  /// sessizce gizlenir).
  String? _trialLabel(Package? pkg, AppLocalizations loc) {
    final intro = pkg?.storeProduct.introductoryPrice;
    if (intro == null || intro.price != 0) return null;
    final unit = switch (intro.periodUnit) {
      PeriodUnit.day => loc.paywallUnitDay,
      PeriodUnit.week => loc.paywallUnitWeek,
      PeriodUnit.month => loc.paywallUnitMonth,
      PeriodUnit.year => loc.paywallUnitYear,
      PeriodUnit.unknown => '',
    };
    if (unit.isEmpty || intro.periodNumberOfUnits <= 0) return null;
    return loc.paywallFreeTrialNote('${intro.periodNumberOfUnits} $unit');
  }

  Future<void> _handlePurchase() async {
    if (_selectedTier == SubscriptionTier.free) {
      context.pop();
      return;
    }
    final pkg = _resolvePackage();
    if (pkg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paket bilgisi alinamadi. Tekrar dene.')),
      );
      return;
    }
    setState(() => _isPurchasing = true);
    final ok = await _revenueCatService.purchasePackage(pkg);
    if (!mounted) return;
    setState(() => _isPurchasing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Satin alma basarili. Planin guncelleniyor.'
            : 'Satin alma tamamlanmadi.'),
      ),
    );
    if (ok) {
      await _showSuccessSheet();
      if (mounted) context.pop();
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isRestoring = true);
    final tier = await _revenueCatService.restorePurchases();
    if (!mounted) return;
    setState(() => _isRestoring = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Geri yukleme sonucu: ${tier.label}')),
    );
    if (tier != SubscriptionTier.free) {
      context.pop();
    }
  }

  Future<void> _showSuccessSheet() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _PurchaseSuccessDialog(),
    );
  }

  void _onTierTap(SubscriptionTier t) {
    if (t == _selectedTier) return;
    setState(() => _selectedTier = t);
    _fadeController.forward(from: 0);
  }

  // ─── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFree = _selectedTier == SubscriptionTier.free;
    final activeGradient = _activeGradient(_selectedTier);
    final activeColor = _activeColor(_selectedTier);
    final loc = AppLocalizations.of(context);

    // ─── Gerçek fiyatlar RevenueCat'ten (hardcoded fallback) ──────────
    final monthlyPkg = _resolvePackageFor(_selectedTier, false);
    final yearlyPkg = _resolvePackageFor(_selectedTier, true);
    final monthlyLabel = monthlyPkg != null
        ? '${monthlyPkg.storeProduct.priceString}${loc.paywallPerMonthSuffix}'
        : _currentPlan.monthlyPrice;
    final yearlyLabel = yearlyPkg != null
        ? '${yearlyPkg.storeProduct.priceString}${loc.paywallPerYearSuffix}'
        : _currentPlan.yearlyPrice;
    int? savingsPercent;
    if (monthlyPkg != null &&
        yearlyPkg != null &&
        monthlyPkg.storeProduct.price > 0) {
      final perMonthYearly = yearlyPkg.storeProduct.price / 12;
      final pct =
          ((1 - perMonthYearly / monthlyPkg.storeProduct.price) * 100).round();
      if (pct > 0) savingsPercent = pct;
    }
    final trialText =
        _trialLabel(_resolvePackageFor(_selectedTier, _isYearly), loc);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: SafeArea(
        child: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TierChipsRow(
                      selected: _selectedTier,
                      onTap: _onTierTap,
                      isDark: isDark,
                    ).animate().slideY(
                          begin: -0.25,
                          duration: 450.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 14),
                    _PaywallHeader(
                      tier: _selectedTier,
                      plan: _currentPlan,
                      gradient: activeGradient,
                      color: activeColor,
                      isDark: isDark,
                    ).animate().slideY(
                          begin: 0.18,
                          duration: 450.ms,
                          delay: 80.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: _FeatureChecklist(
                        features: _currentPlan.features,
                        color: activeColor,
                        isDark: isDark,
                      ).animate().slideY(
                            begin: 0.12,
                            duration: 450.ms,
                            delay: 160.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ),
                    if (!isFree) ...[
                      const SizedBox(height: 18),
                      // ─── Offerings yükleme hatası: in-card error ───
                      if (_loadError && !_isLoadingOfferings)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ErrorStateWidget(
                            message: 'Paketler yüklenirken bir sorun oluştu. Lütfen tekrar dene.',
                            onRetry: _loadOfferings,
                          ),
                        )
                      else if (_isLoadingOfferings)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),
                        )
                      else
                        _PricingCards(
                          monthlyLabel: monthlyLabel,
                          yearlyLabel: yearlyLabel,
                          savingsPercent: savingsPercent,
                          isYearly: _isYearly,
                          onSelect: (v) => setState(() => _isYearly = v),
                          color: activeColor,
                          gradient: activeGradient,
                          isDark: isDark,
                        ).animate().slideY(
                              begin: 0.14,
                              duration: 450.ms,
                              delay: 240.ms,
                              curve: Curves.easeOutCubic,
                            ),
                      if (!_isLoadingOfferings &&
                          !_loadError &&
                          trialText != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.card_giftcard_rounded,
                                size: 14, color: activeColor),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                trialText,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: activeColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                    const Spacer(),
                    _CtaButton(
                      label: isFree
                          ? 'Ücretsiz Devam Et'
                          : '${_currentPlan.name} Planına Geç',
                      gradient: activeGradient,
                      color: activeColor,
                      busy: _isPurchasing,
                      onTap: _isPurchasing || _isRestoring
                          ? null
                          : _handlePurchase,
                    ).animate().slideY(
                          begin: 0.22,
                          duration: 500.ms,
                          delay: 320.ms,
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: 4),
                    _RestoreButton(
                      onTap: _isPurchasing || _isRestoring
                          ? null
                          : _handleRestore,
                      busy: _isRestoring,
                    ),
                    const SizedBox(height: 6),
                    const _SecurityFooter(),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 14,
              child: _FloatingCloseButton(isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tier chips row ──────────────────────────────────────────────────
class _TierChipsRow extends StatelessWidget {
  final SubscriptionTier selected;
  final ValueChanged<SubscriptionTier> onTap;
  final bool isDark;

  const _TierChipsRow({
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _chip(SubscriptionTier.free)),
        const SizedBox(width: 8),
        Expanded(child: _chip(SubscriptionTier.plus)),
        const SizedBox(width: 8),
        Expanded(child: _chip(SubscriptionTier.pro)),
      ],
    );
  }

  Widget _chip(SubscriptionTier t) {
    final isSelected = selected == t;
    final LinearGradient gradient;
    final Color color;
    final IconData icon;
    final String label;
    switch (t) {
      case SubscriptionTier.free:
        color = AppColors.tierFree;
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        );
        icon = Icons.person_outline_rounded;
        label = 'Ücretsiz';
        break;
      case SubscriptionTier.plus:
        color = AppColors.tierPlus;
        gradient = AppColors.tierPlusGradient;
        icon = Icons.star_rounded;
        label = 'Plus';
        break;
      case SubscriptionTier.pro:
        color = AppColors.tierPro;
        gradient = AppColors.tierProGradient;
        icon = Icons.workspace_premium_rounded;
        label = 'Pro';
        break;
    }

    return GestureDetector(
      onTap: () => onTap(t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        height: 54,
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected
              ? null
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.border),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header (gradient icon + ShaderMask title + subtitle) ─────────────
class _PaywallHeader extends StatelessWidget {
  final SubscriptionTier tier;
  final _PlanData plan;
  final LinearGradient gradient;
  final Color color;
  final bool isDark;

  const _PaywallHeader({
    required this.tier,
    required this.plan,
    required this.gradient,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Column(
        key: ValueKey(tier),
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(plan.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (bounds) => gradient.createShader(bounds),
            child: Text(
              '${plan.name} Plan',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 23,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              plan.subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.65)
                    : AppColors.textSecondaryFor(context),
                height: 1.3,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature Checklist (Amie style) ──────────────────────────────────
class _FeatureChecklist extends StatelessWidget {
  final List<_FeatureItem> features;
  final Color color;
  final bool isDark;

  const _FeatureChecklist({
    required this.features,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < features.length; i++) ...[
              _FeatureRow(item: features[i], color: color, isDark: isDark),
              if (i < features.length - 1) const SizedBox(height: 7),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final _FeatureItem item;
  final Color color;
  final bool isDark;

  const _FeatureRow({
    required this.item,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final included = item.included;
    return Row(
      children: [
        Icon(
          Icons.check_rounded,
          size: 16,
          color: included
              ? color
              : (isDark
                  ? Colors.white.withValues(alpha: 0.20)
                  : AppColors.textTertiary.withValues(alpha: 0.5)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: included ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12.5,
              color: included
                  ? (isDark ? Colors.white : AppColors.textPrimaryFor(context))
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.35)
                      : AppColors.textTertiaryFor(context)),
              decoration: included ? null : TextDecoration.lineThrough,
              decorationColor: AppColors.textTertiaryFor(context),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Pricing Cards (Aylık + Yıllık stacked) ──────────────────────────
class _PricingCards extends StatelessWidget {
  final String monthlyLabel;
  final String yearlyLabel;
  final int? savingsPercent;
  final bool isYearly;
  final ValueChanged<bool> onSelect;
  final Color color;
  final LinearGradient gradient;
  final bool isDark;

  const _PricingCards({
    required this.monthlyLabel,
    required this.yearlyLabel,
    required this.savingsPercent,
    required this.isYearly,
    required this.onSelect,
    required this.color,
    required this.gradient,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        _PricingCard(
          title: 'Aylık',
          price: monthlyLabel,
          selected: !isYearly,
          onTap: () => onSelect(false),
          color: color,
          gradient: gradient,
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _PricingCard(
                title: 'Yıllık',
                price: yearlyLabel,
                subtitle: savingsPercent != null
                    ? loc.paywallYearlySavingsSub(savingsPercent!)
                    : 'Yılın tamamı için en avantajlı seçenek',
                selected: isYearly,
                onTap: () => onSelect(true),
                color: color,
                gradient: gradient,
                isDark: isDark,
              ),
              if (savingsPercent != null)
                Positioned(
                  top: -12,
                  left: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      loc.paywallSaveBadge(savingsPercent!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final LinearGradient gradient;
  final bool isDark;

  const _PricingCard({
    required this.title,
    required this.price,
    this.subtitle,
    required this.selected,
    required this.onTap,
    required this.color,
    required this.gradient,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? (selected
                  ? color.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.04))
              : (selected
                  ? color.withValues(alpha: 0.06)
                  : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? color
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.border),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: selected ? gradient : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? color : AppColors.textTertiaryFor(context),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
                      ),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.55)
                            : AppColors.textTertiaryFor(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              price,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CTA Button (gradient + glow) ────────────────────────────────────
class _CtaButton extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final Color color;
  final bool busy;
  final VoidCallback? onTap;

  const _CtaButton({
    required this.label,
    required this.gradient,
    required this.color,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: EdgeInsets.zero,
          ),
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Restore button ──────────────────────────────────────────────────
class _RestoreButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool busy;

  const _RestoreButton({required this.onTap, required this.busy});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton.icon(
        onPressed: onTap,
        icon: busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.restore_rounded, size: 18),
        label: const Text('Satin alimi geri yukle'),
      ),
    );
  }
}

// ─── Security footer ─────────────────────────────────────────────────
class _SecurityFooter extends StatelessWidget {
  const _SecurityFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded,
            size: 13, color: AppColors.textTertiaryFor(context)),
        const SizedBox(width: 4),
        Text(
          'Güvenli ödeme • İstediğinde iptal',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ─── Floating close button ───────────────────────────────────────────
class _FloatingCloseButton extends StatelessWidget {
  final bool isDark;
  const _FloatingCloseButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.white,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.pop(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.close_rounded,
              size: 22,
              color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Data ────────────────────────────────────────────────────────────
class _PlanData {
  final String name;
  final String monthlyPrice;
  final String yearlyPrice;
  final IconData icon;
  final String subtitle;
  final List<_FeatureItem> features;

  const _PlanData({
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.icon,
    required this.subtitle,
    required this.features,
  });
}

class _FeatureItem {
  final String label;
  final bool included;

  const _FeatureItem(this.label, this.included);
}

// ─── Success Dialog (preserved) ──────────────────────────────────────
class _PurchaseSuccessDialog extends StatefulWidget {
  const _PurchaseSuccessDialog();

  @override
  State<_PurchaseSuccessDialog> createState() => _PurchaseSuccessDialogState();
}

class _PurchaseSuccessDialogState extends State<_PurchaseSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurfaceVariant
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = Curves.easeOut.transform(_controller.value);
                    return Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0),
                      child: Stack(
                        children: List.generate(14, (i) {
                          return Positioned(
                            left: 8 + (i % 7) * 36 + (i.isEven ? -16 : 16) * t,
                            top: 4 + (i ~/ 7) * 20 + (110 * t),
                            child: Text(
                              i.isEven ? '🎉' : '✨',
                              style: TextStyle(fontSize: 12 + (i % 3) * 2.0),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.success, AppColors.primary],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 34),
                ),
                const SizedBox(height: 12),
                Text(
                  'Satin alma basarili!',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Planin aktif edildi. Tum ozelliklerin keyfini cikar.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryFor(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Harika'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
