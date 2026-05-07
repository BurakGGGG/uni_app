import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Paywall Ekranı — Full UI
/// 3 plan kartı horizontal scroll (Free / Plus / Pro)
/// Feature check-list animasyonu, "En Popüler" badge,
/// Aylık/Yıllık toggle, "Ücretsiz Dene (7 gün)" butonu
/// RevenueCat entegrasyonu Hafta 2'de yapılacak
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with TickerProviderStateMixin {
  bool _isYearly = false;
  int _selectedPlanIndex = 1; // Plus varsayılan seçili
  final PageController _pageController = PageController(
    viewportFraction: 0.82,
    initialPage: 1,
  );

  late AnimationController _headerFadeController;
  late AnimationController _featureListController;
  late Animation<double> _headerFadeAnim;

  @override
  void initState() {
    super.initState();

    _headerFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFadeAnim = CurvedAnimation(
      parent: _headerFadeController,
      curve: Curves.easeOut,
    );

    _featureListController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerFadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _featureListController.forward();
    });
  }

  @override
  void dispose() {
    _headerFadeController.dispose();
    _featureListController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  static const _plans = [
    _PlanData(
      name: 'Free',
      monthlyPrice: 'Bedava',
      yearlyPrice: 'Bedava',
      tierColor: AppColors.tierFree,
      icon: Icons.person_outline_rounded,
      features: [
        _FeatureItem('Üniversite karşılaştırma (1/gün)', true),
        _FeatureItem('Bölüm karşılaştırma', false),
        _FeatureItem('Şehir karşılaştırma', false),
        _FeatureItem('AI karşılaştırma özeti', false),
        _FeatureItem('Pro grafikler', false),
      ],
      isPopular: false,
    ),
    _PlanData(
      name: 'Plus',
      monthlyPrice: '39.90₺/ay',
      yearlyPrice: '32.90₺/ay',
      tierColor: AppColors.tierPlus,
      icon: Icons.star_rounded,
      features: [
        _FeatureItem('Sınırsız üniversite karşılaştırma', true),
        _FeatureItem('Bölüm karşılaştırma', true),
        _FeatureItem('Şehir karşılaştırma', true),
        _FeatureItem('Reklam yok', true),
        _FeatureItem('AI karşılaştırma özeti', false),
        _FeatureItem('Pro grafikler', false),
      ],
      isPopular: true,
    ),
    _PlanData(
      name: 'Pro',
      monthlyPrice: '69.90₺/ay',
      yearlyPrice: '58.90₺/ay',
      tierColor: AppColors.tierPro,
      icon: Icons.workspace_premium_rounded,
      features: [
        _FeatureItem('Plus dahil tüm özellikler', true),
        _FeatureItem('AI karşılaştırma özeti (5/gün)', true),
        _FeatureItem('AI öneri asistanı (10/gün)', true),
        _FeatureItem('Pro grafik paketi', true),
        _FeatureItem('Trend & scatter grafikler', true),
        _FeatureItem('Isı haritası', true),
      ],
      isPopular: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? Colors.white : AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Planlar',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            )),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Başlık + Toggle (sabit) ─────────────────────
            FadeTransition(
              opacity: _headerFadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildTitle(isDark),
                    const SizedBox(height: 20),
                    _buildBillingToggle(isDark),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ─── Horizontal Plan Kartları ───────────────────
            SizedBox(
              height: 380,
              child: PageView.builder(
                controller: _pageController,
                itemCount: 3,
                onPageChanged: (i) => setState(() => _selectedPlanIndex = i),
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double scale = 1.0;
                      if (_pageController.position.haveDimensions) {
                        final page = _pageController.page ?? 1.0;
                        scale = (1 - (page - index).abs() * 0.08).clamp(0.9, 1.0);
                      }
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: _buildPlanCard(index, isDark),
                  );
                },
              ),
            ),

            // ─── Alt kısım (CTA + footer) ──────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildCtaButton(isDark),
                    const SizedBox(height: 12),
                    _buildFooter(isDark),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return Column(
      children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.rocket_launch_rounded,
              color: Colors.white, size: 26),
        ),
        const SizedBox(height: 12),
        Text(
          'Daha fazlasına erişmek için\nbir plan seç',
          textAlign: TextAlign.center,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.3,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBillingToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleBtn('Aylık', !_isYearly, isDark,
                () => setState(() => _isYearly = false)),
          ),
          Expanded(
            child: _toggleBtn('Yıllık • %20 indirim', _isYearly, isDark,
                () => setState(() => _isYearly = true),
                badge: !_isYearly ? 'TASARRUF' : null),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool selected, bool isDark, VoidCallback onTap,
      {String? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? (isDark ? Colors.white : AppColors.textPrimary)
                      : AppColors.textSecondary,
                )),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(badge,
                    style: const TextStyle(
                        fontSize: 8, fontWeight: FontWeight.w700,
                        color: AppColors.success)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(int index, bool isDark) {
    final plan = _plans[index];
    final isSelected = _selectedPlanIndex == index;
    final price = _isYearly ? plan.yearlyPrice : plan.monthlyPrice;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPlanIndex = index);
        _pageController.animateToPage(index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? (isSelected
                  ? plan.tierColor.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.04))
              : (isSelected
                  ? plan.tierColor.withValues(alpha: 0.04)
                  : AppColors.surface),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? plan.tierColor.withValues(alpha: 0.5)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: plan.tierColor.withValues(alpha: 0.15),
                  blurRadius: 24, offset: const Offset(0, 8))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ikon + isim + badge
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: plan.tierColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(plan.icon, color: plan.tierColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(plan.name,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              )),
                          if (plan.isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: AppColors.tierPlusGradient,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('EN POPÜLER',
                                  style: TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w800,
                                    color: Colors.white, letterSpacing: 0.5,
                                  )),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(price,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: plan.tierColor,
                          )),
                    ],
                  ),
                ),
                // Radio indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? plan.tierColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? plan.tierColor : AppColors.textTertiary,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.borderLight,
                height: 1,
              ),
            ),

            // Feature check-list with staggered animation
            Expanded(
              child: _AnimatedFeatureList(
                features: plan.features,
                controller: _featureListController,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaButton(bool isDark) {
    final selectedPlan = _plans[_selectedPlanIndex];
    final isFree = _selectedPlanIndex == 0;

    return Column(
      children: [
        SizedBox(
          width: double.infinity, height: 54,
          child: FilledButton(
            onPressed: () {
              if (isFree) {
                context.pop();
              } else {
                // TODO: RevenueCat satın alma akışı (Hafta 2)
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${selectedPlan.name} planı yakında aktif olacak!'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: isFree ? AppColors.textSecondary : selectedPlan.tierColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle: AppTextStyles.titleSmall
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            child: Text(isFree ? 'Mevcut Plan' : '${selectedPlan.name} Planı Seç'),
          ),
        ),
        if (!isFree && _selectedPlanIndex == 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: RevenueCat 7-gün free trial (Hafta 2)
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('7 günlük deneme yakında aktif olacak!'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              },
              icon: const Icon(Icons.card_giftcard_rounded, size: 18),
              label: const Text('7 Gün Ücretsiz Dene — Plus'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.tierPlus,
                side: BorderSide(
                    color: AppColors.tierPlus.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: AppTextStyles.labelMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline_rounded,
            size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text('Güvenli ödeme • İstediğinde iptal',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary, fontSize: 11)),
      ],
    );
  }
}

// ─── Animated Feature Check-list ─────────────────────────────────────

class _AnimatedFeatureList extends StatelessWidget {
  final List<_FeatureItem> features;
  final AnimationController controller;
  final bool isDark;

  const _AnimatedFeatureList({
    required this.features,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: features.length,
      itemBuilder: (context, index) {
        final f = features[index];
        final start = (index * 0.1).clamp(0.0, 0.7);
        final end = (start + 0.4).clamp(0.0, 1.0);

        final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        );
        final slideAnim = Tween<Offset>(
          begin: const Offset(-0.15, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        );

        return FadeTransition(
          opacity: fadeAnim,
          child: SlideTransition(
            position: slideAnim,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: f.included
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      f.included ? Icons.check_rounded : Icons.close_rounded,
                      size: 14,
                      color: f.included ? AppColors.success : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(f.label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: f.included
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : AppColors.textPrimary)
                              : AppColors.textTertiary,
                          decoration: f.included ? null : TextDecoration.lineThrough,
                          decorationColor: AppColors.textTertiary,
                        )),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Data Models (statik) ──────────────────────────────────────────

class _PlanData {
  final String name;
  final String monthlyPrice;
  final String yearlyPrice;
  final Color tierColor;
  final IconData icon;
  final List<_FeatureItem> features;
  final bool isPopular;

  const _PlanData({
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.tierColor,
    required this.icon,
    required this.features,
    required this.isPopular,
  });
}

class _FeatureItem {
  final String label;
  final bool included;

  const _FeatureItem(this.label, this.included);
}
