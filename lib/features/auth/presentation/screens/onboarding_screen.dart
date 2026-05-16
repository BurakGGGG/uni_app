import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';

/// Onboarding sayfası — sadece ilk açılışta gösterilir
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPageData(
      icon: Icons.school_rounded,
      iconColor: AppColors.primary,
      title: 'Üniversiteni Keşfet',
      description:
          'Türkiye\'deki üniversiteleri kampüs yaşamı, sosyal olanaklar ve eğitim kalitesine göre keşfet.',
    ),
    _OnboardingPageData(
      icon: Icons.rate_review_rounded,
      iconColor: AppColors.secondary,
      title: 'Gerçek Yorumlar',
      description:
          'edu.tr doğrulamalı öğrencilerin gerçek deneyimlerini oku. Sahte yorum yok, sadece gerçek hikayeler.',
    ),
    _OnboardingPageData(
      icon: Icons.compare_arrows_rounded,
      iconColor: AppColors.accent,
      title: 'Tercihini Kolaylaştır',
      description:
          'Üniversiteleri yan yana karşılaştır, favori listeni oluştur ve hayalindeki üniversiteyi bul.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      context.go('/login');
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.animNormal,
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Atla butonu ──────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Atla',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textTertiaryFor(context),
                    ),
                  ),
                ),
              ),
            ),

            // ─── Sayfa içeriği ────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _OnboardingPage(data: _pages[index]);
                },
              ),
            ),

            // ─── Dot indicator + Buton ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Row(
                children: [
                  // Dot indicator
                  Row(
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: AppConstants.animNormal,
                        margin: const EdgeInsets.only(right: 8),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // İleri / Başla butonu
                  SizedBox(
                    height: 52,
                    child: GradientButton(
                      text: _currentPage == _pages.length - 1
                          ? 'Başla'
                          : 'İleri',
                      isExpanded: false,
                      onPressed: _nextPage,
                      icon: _currentPage == _pages.length - 1
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Onboarding Page Data ───────────────────────────────────────────

class _OnboardingPageData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _OnboardingPageData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });
}

// ─── Onboarding Page Widget ─────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // İkon container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: data.iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 64,
              color: data.iconColor,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut),

          const SizedBox(height: 48),

          // Başlık
          Text(
            data.title,
            style: AppTextStyles.displaySmall,
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0),

          const SizedBox(height: 16),

          // Açıklama
          Text(
            data.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondaryFor(context),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }
}
