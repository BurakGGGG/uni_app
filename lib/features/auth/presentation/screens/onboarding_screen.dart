import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../router/redirect_utils.dart';
import '../../../assistant/data/robot_memory.dart';
import '../../../assistant/domain/robot_mood.dart';
import '../../../assistant/domain/robot_scripts.dart';
import '../../../assistant/presentation/widgets/robot_avatar.dart';


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

/// İçerik alanının üst boşluğu (Atla düğmesinin altı).
const double _contentTopPadding = 80;

/// Alt kontrollerin (nokta + ileri düğmesi) kapladığı boşluk.
const double _contentBottomPadding = 120;

const double _contentPadding = _contentTopPadding + _contentBottomPadding;

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

  /// Sayfaların GÖRSEL kimliği. Başlık/gövde [RobotScripts.onboardingPages]
  /// içinde yaşar — böylece Üni'nin ağzından çıkar ve iki dilli olur.
  static const _pages = [
    _PageStyle(
      glowColor: AppColors.primary,
      gradientColors: [Color(0xFF0A0A18), Color(0xFF1A1040)],
      accentColor: AppColors.primary,
    ),
    _PageStyle(
      glowColor: AppColors.accent,
      gradientColors: [Color(0xFF0A0A18), Color(0xFF0A1A2E)],
      accentColor: AppColors.accent,
    ),
    _PageStyle(
      glowColor: AppColors.secondary,
      gradientColors: [Color(0xFF0A0A18), Color(0xFF1A0A1A)],
      accentColor: AppColors.secondary,
    ),
    _PageStyle(
      glowColor: AppColors.primary,
      gradientColors: [Color(0xFF0A0A18), Color(0xFF101030)],
      accentColor: AppColors.primary,
    ),
  ];

  /// Son sayfada Üni'nin sorduğu ad.
  final _nameController = TextEditingController();

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
    _nameController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Navigation ────────────────────────────────────────────────────

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    // Ad verildiyse Üni hatırlasın; boş bırakılırsa hiç yazılmaz.
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await RobotMemory(prefs).setDisplayName(name);
    }
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
                    // İçerik — kısa ekranda ve klavye açıkken taşmasın diye
                    // kaydırılabilir: yer varken ortalanır, yetmeyince kayar.
                    SafeArea(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final keyboard =
                              MediaQuery.viewInsetsOf(context).bottom;
                          final available =
                              constraints.maxHeight - _contentPadding - keyboard;
                          return SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              32,
                              _contentTopPadding,
                              32,
                              _contentBottomPadding + keyboard,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: available > 0 ? available : 0,
                              ),
                              child: Center(
                                child: _PageContent(
                                  style: page,
                                  copy: RobotScripts.onboardingPages[index],
                                  pulseController: _pulseController,
                                  // Ekran başına tek animasyonlu avatar
                                  // kuralı: PageView komşu sayfaları
                                  // canlı tutar.
                                  animateAvatar: index == _currentPage,
                                  nameController: index == _pages.length - 1
                                      ? _nameController
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
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
                    label: RobotScripts.isEn ? 'Skip' : 'Atla',
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

class _PageStyle {
  final Color glowColor;
  final List<Color> gradientColors;
  final Color accentColor;

  const _PageStyle({
    required this.glowColor,
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
  final _PageStyle style;
  final OnboardingCopy copy;
  final AnimationController pulseController;
  final bool animateAvatar;

  /// Yalnız son sayfada dolu — Üni'nin isim sorusu.
  final TextEditingController? nameController;

  const _PageContent({
    required this.style,
    required this.copy,
    required this.pulseController,
    required this.animateAvatar,
    this.nameController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      // Kaydırma görünümü içinde olduğundan doğal yükseklik; ortalama
      // işini saran Center yapıyor.
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Üni ──
        _GlowingRobot(
          mood: copy.mood,
          color: style.glowColor,
          pulseController: pulseController,
          animated: animateAvatar,
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

        // ── Başlık ──
        Text(
          copy.title,
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

        // ── Gövde ──
        Text(
          copy.body,
          style: AppTextStyles.bodyLarge.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.7,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 500.ms)
            .slideY(begin: 0.3, end: 0),

        if (nameController != null) ...[
          const SizedBox(height: 28),
          _NameField(controller: nameController!, accent: style.accentColor)
              .animate()
              .fadeIn(delay: 600.ms, duration: 500.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ],
    );
  }
}

/// Üni'nin isim kutusu — boş bırakılabilir, zorlama yok.
class _NameField extends StatelessWidget {
  final TextEditingController controller;
  final Color accent;

  const _NameField({required this.controller, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: 24,
          style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
          decoration: InputDecoration(
            counterText: '',
            hintText: RobotScripts.onboardingNameHint,
            hintStyle: AppTextStyles.titleMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.35),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accent, width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          RobotScripts.onboardingNameSkip,
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Glowing Robot — Üni, nabız gibi atan hâlenin içinde
// ═══════════════════════════════════════════════════════════════════════

class _GlowingRobot extends StatelessWidget {
  final RobotMood mood;
  final Color color;
  final AnimationController pulseController;
  final bool animated;

  const _GlowingRobot({
    required this.mood,
    required this.color,
    required this.pulseController,
    required this.animated,
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
          alignment: Alignment.center,
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
      child: RobotAvatar(size: 104, mood: mood, animated: animated),
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
