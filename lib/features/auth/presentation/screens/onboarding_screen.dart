import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../router/redirect_utils.dart';


// ═══════════════════════════════════════════════════════════════════════
//  Onboarding Screen — Premium 4-Page Experience
// ═══════════════════════════════════════════════════════════════════════

class OnboardingScreen extends StatefulWidget {
  /// Onboarding sonrası dönülecek yerel rota (ör. deep link ile gelindiyse).
  final String? from;

  const OnboardingScreen({super.key, this.from});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _floatController;
  late final AnimationController _pulseController;

  // Pre-generated bubble data per page
  late final List<_BubbleData> _orbsPage0;
  late final List<_BubbleData> _logosPage1;
  late final List<_BubbleData> _orbsPage2;
  late final List<_BubbleData> _orbsPage3;

  /// Üniversite logo asset yolları (sayfa 2 arka planı için)
  static const _uniLogoPaths = [
    'assets/logos/odtu.png',
    'assets/logos/itu.png',
    'assets/logos/hacettepe.png',
    'assets/logos/ege.png',
    'assets/logos/gazi.png',
    'assets/logos/istanbul_uni.png',
    'assets/logos/ankara_uni.png',
    'assets/logos/marmara.png',
    'assets/logos/dokuz_eylul.png',
    'assets/logos/yildiz_teknik.png',
    'assets/logos/anadolu.png',
    'assets/logos/erciyes.png',
    'assets/logos/akdeniz.png',
    'assets/logos/selcuk.png',
  ];

  /// Sayfa verileri
  static final _pages = [
    _PageData(
      icon: Icons.school_rounded,
      artAsset: 'assets/icons/compare_icon.svg',
      glowColor: AppColors.primary,
      title: "ÜniSeç'e Hoş Geldin",
      description:
          'Hayalindeki üniversiteyi keşfet, gerçek yorumları oku ve geleceğini şekillendir.',
      gradientColors: const [Color(0xFF0A0A18), Color(0xFF1A1040)],
      accentColor: AppColors.primary,
    ),
    _PageData(
      icon: Icons.explore_rounded,
      glowColor: AppColors.accent,
      title: 'Keşfet & Karşılaştır',
      description:
          '50+ üniversiteyi puan, şehir ve olanaklara göre filtrele. '
          'Yan yana karşılaştır, en uygununu bul.',
      gradientColors: const [Color(0xFF0A0A18), Color(0xFF0A1A2E)],
      accentColor: AppColors.accent,
    ),
    _PageData(
      icon: Icons.verified_rounded,
      glowColor: AppColors.secondary,
      title: 'Gerçek Öğrenci Yorumları',
      description:
          'edu.tr doğrulamalı öğrencilerin deneyimlerini oku. '
          'Sahte yorum yok, sadece gerçek hikayeler.',
      gradientColors: const [Color(0xFF0A0A18), Color(0xFF1A0A1A)],
      accentColor: AppColors.secondary,
    ),
    _PageData(
      icon: Icons.rocket_launch_rounded,
      glowColor: AppColors.primary,
      title: 'Hazır mısın?',
      description:
          'Yurt bilgileri, kampüs mekanları ve çok daha fazlası seni bekliyor. '
          'Hemen keşfetmeye başla!',
      gradientColors: const [Color(0xFF0A0A18), Color(0xFF101030)],
      accentColor: AppColors.primary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Sayfa 0 — mor + cyan soyut orblar
    _orbsPage0 = _generateOrbs(
      count: 8,
      colors: [
        AppColors.primary,
        AppColors.accent,
        AppColors.gradientPurple,
      ],
      seed: 42,
    );

    // Sayfa 1 — üniversite logoları
    _logosPage1 = _generateLogoBubbles(seed: 77);

    // Sayfa 2 — pembe / sıcak orblar
    _orbsPage2 = _generateOrbs(
      count: 7,
      colors: [
        AppColors.secondary,
        AppColors.gradientPink,
        AppColors.primary,
      ],
      seed: 123,
    );

    // Sayfa 3 — çok renkli orblar
    _orbsPage3 = _generateOrbs(
      count: 11,
      colors: [
        AppColors.primary,
        AppColors.accent,
        AppColors.secondary,
        AppColors.gradientCyan,
      ],
      seed: 256,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Navigation ────────────────────────────────────────────────────

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    // Deep link ile gelindiyse hedefe dön (ör. paylaşılan tercih listesi)
    final target = localRedirectPathFromParam(widget.from);
    context.go(target ?? '/login');
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

  // ─── Bubble Data Generators ────────────────────────────────────────

  static List<_BubbleData> _generateOrbs({
    required int count,
    required List<Color> colors,
    required int seed,
  }) {
    final rng = Random(seed);
    return List.generate(count, (i) {
      return _BubbleData(
        x: rng.nextDouble() * 0.9,
        y: rng.nextDouble() * 0.85,
        size: 80 + rng.nextDouble() * 160,
        opacity: 0.07 + rng.nextDouble() * 0.11,
        blur: 40 + rng.nextDouble() * 50,
        phase: rng.nextDouble(),
        speed: 0.3 + rng.nextDouble() * 0.6,
        color: colors[i % colors.length],
      );
    });
  }

  List<_BubbleData> _generateLogoBubbles({required int seed}) {
    final rng = Random(seed);
    return List.generate(_uniLogoPaths.length, (i) {
      return _BubbleData(
        x: 0.05 + rng.nextDouble() * 0.75,
        y: 0.05 + rng.nextDouble() * 0.75,
        size: 44 + rng.nextDouble() * 32,
        opacity: 0.15 + rng.nextDouble() * 0.20,
        blur: 0,
        phase: rng.nextDouble(),
        speed: 0.15 + rng.nextDouble() * 0.35,
        logoPath: _uniLogoPaths[i],
        color: Colors.white,
      );
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A18),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // ── Full-screen PageView ──
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient arka plan
                    _GradientBg(colors: page.gradientColors),
                    // Yüzen elementler
                    RepaintBoundary(
                      child: _buildFloatingLayer(index),
                    ),
                    // İçerik
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(32, 80, 32, 120),
                        child: _PageContent(
                          data: page,
                          pulseController: _pulseController,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // ── Atla butonu ──
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _GlassChip(
                    label: 'Atla',
                    onTap: _completeOnboarding,
                  ),
                ),
              ),
            ),

            // ── Alt kontroller ──
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _BottomControls(
                  currentPage: _currentPage,
                  pageCount: _pages.length,
                  accentColor: _pages[_currentPage].accentColor,
                  onNext: _nextPage,
                  isLastPage: _currentPage == _pages.length - 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Floating Layer Per Page ────────────────────────────────────────

  Widget _buildFloatingLayer(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return _FloatingOrbs(
          controller: _floatController,
          bubbles: _orbsPage0,
        );
      case 1:
        return _FloatingLogos(
          controller: _floatController,
          bubbles: _logosPage1,
        );
      case 2:
        return _FloatingOrbs(
          controller: _floatController,
          bubbles: _orbsPage2,
        );
      case 3:
        return _FloatingOrbs(
          controller: _floatController,
          bubbles: _orbsPage3,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Data Models
// ═══════════════════════════════════════════════════════════════════════

class _PageData {
  final IconData icon;

  /// Opsiyonel marka görseli (SVG). Verilirse Material [icon] yerine beyaz
  /// renkli olarak gradient dairenin içinde gösterilir — 1. sayfada ÜniSeç
  /// swap glyph'i için kullanılır.
  final String? artAsset;
  final Color glowColor;
  final String title;
  final String description;
  final List<Color> gradientColors;
  final Color accentColor;

  const _PageData({
    required this.icon,
    this.artAsset,
    required this.glowColor,
    required this.title,
    required this.description,
    required this.gradientColors,
    required this.accentColor,
  });
}

class _BubbleData {
  final double x, y, size, opacity, blur, phase, speed;
  final Color? color;
  final String? logoPath;

  const _BubbleData({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.blur,
    required this.phase,
    required this.speed,
    this.color,
    this.logoPath,
  });
}

// ═══════════════════════════════════════════════════════════════════════
//  Gradient Background
// ═══════════════════════════════════════════════════════════════════════

class _GradientBg extends StatelessWidget {
  final List<Color> colors;
  const _GradientBg({required this.colors});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Floating Orbs (Abstract blurred circles)
// ═══════════════════════════════════════════════════════════════════════

class _FloatingOrbs extends StatelessWidget {
  final AnimationController controller;
  final List<_BubbleData> bubbles;

  const _FloatingOrbs({required this.controller, required this.bubbles});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Stack(
          children: bubbles.map((b) {
            final dx = sin((t * b.speed + b.phase) * 2 * pi) * 25;
            final dy = cos((t * b.speed * 0.7 + b.phase) * 2 * pi) * 20;
            final screenW = MediaQuery.sizeOf(context).width;
            final screenH = MediaQuery.sizeOf(context).height;

            return Positioned(
              left: b.x * screenW + dx,
              top: b.y * screenH + dy,
              child: Container(
                width: b.size,
                height: b.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (b.color ?? Colors.white).withValues(alpha: b.opacity),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (b.color ?? Colors.white).withValues(alpha: b.opacity * 0.5),
                      blurRadius: b.blur,
                      spreadRadius: b.blur * 0.3,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Floating University Logos (Page 2 only)
// ═══════════════════════════════════════════════════════════════════════

class _FloatingLogos extends StatelessWidget {
  final AnimationController controller;
  final List<_BubbleData> bubbles;

  const _FloatingLogos({required this.controller, required this.bubbles});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Stack(
          children: bubbles.map((b) {
            final dx = sin((t * b.speed + b.phase) * 2 * pi) * 18;
            final dy = cos((t * b.speed * 0.8 + b.phase) * 2 * pi) * 14;
            final screenW = MediaQuery.sizeOf(context).width;
            final screenH = MediaQuery.sizeOf(context).height;

            return Positioned(
              left: b.x * screenW + dx,
              top: b.y * screenH + dy,
              child: Opacity(
                opacity: b.opacity,
                child: Container(
                  width: b.size,
                  height: b.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Padding(
                        padding: EdgeInsets.all(b.size * 0.2),
                        child: Image.asset(
                          b.logoPath!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.school_rounded,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: b.size * 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Page Content (Icon + Title + Description)
// ═══════════════════════════════════════════════════════════════════════

class _PageContent extends StatelessWidget {
  final _PageData data;
  final AnimationController pulseController;

  const _PageContent({required this.data, required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Glowing Icon ──
        _GlowingIcon(
          icon: data.icon,
          artAsset: data.artAsset,
          color: data.glowColor,
          pulseController: pulseController,
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 700.ms,
              curve: Curves.elasticOut,
            ),

        const SizedBox(height: 48),

        // ── Title ──
        Text(
          data.title,
          style: AppTextStyles.displayMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 500.ms)
            .slideY(begin: 0.3, end: 0),

        const SizedBox(height: 20),

        // ── Description ──
        Text(
          data.description,
          style: AppTextStyles.bodyLarge.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.7,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 500.ms)
            .slideY(begin: 0.3, end: 0),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Glowing Icon Widget
// ═══════════════════════════════════════════════════════════════════════

class _GlowingIcon extends StatelessWidget {
  final IconData icon;
  final String? artAsset;
  final Color color;
  final AnimationController pulseController;

  const _GlowingIcon({
    required this.icon,
    this.artAsset,
    required this.color,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final pulse = 0.8 + pulseController.value * 0.4; // 0.8 → 1.2
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.25 * pulse),
                color.withValues(alpha: 0.08 * pulse),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
              radius: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3 * pulse),
                blurRadius: 60 * pulse,
                spreadRadius: 10 * pulse,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withValues(alpha: 0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: artAsset != null
            ? SvgPicture.asset(
                artAsset!,
                width: 50,
                height: 50,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              )
            : Icon(icon, size: 48, color: Colors.white),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Glass Chip (Skip Button)
// ═══════════════════════════════════════════════════════════════════════

class _GlassChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GlassChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Bottom Controls (Dots + Button)
// ═══════════════════════════════════════════════════════════════════════

class _BottomControls extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final Color accentColor;
  final VoidCallback onNext;
  final bool isLastPage;

  const _BottomControls({
    required this.currentPage,
    required this.pageCount,
    required this.accentColor,
    required this.onNext,
    required this.isLastPage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Row(
        children: [
          // ── Dot indicator ──
          Row(
            children: List.generate(pageCount, (index) {
              final isActive = index == currentPage;
              return AnimatedContainer(
                duration: AppConstants.animNormal,
                margin: const EdgeInsets.only(right: 8),
                width: isActive ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive
                      ? accentColor
                      : Colors.white.withValues(alpha: 0.2),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),

          const Spacer(),

          // ── İleri / Başla butonu ──
          _NextButton(
            isLastPage: isLastPage,
            accentColor: accentColor,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Next / Start Button
// ═══════════════════════════════════════════════════════════════════════

class _NextButton extends StatelessWidget {
  final bool isLastPage;
  final Color accentColor;
  final VoidCallback onTap;

  const _NextButton({
    required this.isLastPage,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animNormal,
        height: 52,
        padding: EdgeInsets.symmetric(horizontal: isLastPage ? 28 : 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accentColor, accentColor.withValues(alpha: 0.7)],
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isLastPage ? 'Başla' : 'İleri',
              style: AppTextStyles.button,
            ),
            const SizedBox(width: 8),
            Icon(
              isLastPage
                  ? Icons.rocket_launch_rounded
                  : Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
