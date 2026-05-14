import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../university/presentation/providers/university_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _loadingController;
  late final AnimationController _glowController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _loadingFade;

  @override
  void initState() {
    super.initState();
    // Native splash'i kaldır — artık kendi Flutter splash'imiz ekranda
    FlutterNativeSplash.remove();

    // ─── Logo animasyonu (0 → 800ms) ──────────────────────────
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // ─── Text animasyonu (400ms → 1000ms) ─────────────────────
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // ─── Loading animasyonu (800ms → 1200ms) ──────────────────
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadingFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeIn),
    );

    // ─── Glow pulse animasyonu (sürekli) ──────────────────────
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Animasyonları sırayla başlat
    _startAnimations();
    _navigateToNext();
  }

  Future<void> _startAnimations() async {
    // Logo anında başla
    _logoController.forward();

    // Text 400ms sonra
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _textController.forward();

    // Loading 800ms sonra
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _loadingController.forward();
  }

  Future<void> _navigateToNext() async {
    // 1. Durumu kontrol et
    final prefs = ref.read(sharedPreferencesProvider);
    final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    final isGoingToHome = hasCompletedOnboarding && isLoggedIn;

    // 2. Minimum gösterim süresi (Animasyonların tamamlanması için)
    final minSplashDuration = Future.delayed(const Duration(milliseconds: 2500));

    // 3. Veri yükleme görevleri (sadece ana sayfaya gidecekse)
    Future<void> dataLoadFuture = Future.value();
    if (isGoingToHome) {
      // Sadece kritik verileri ön yükle (cold start optimizasyonu)
      // popular ve reviews Home açıldıktan sonra Riverpod lazy-load eder
      dataLoadFuture = Future.wait([
        ref.read(citiesProvider.future),     // Home için zorunlu
        ref.read(currentUserProvider.future), // Profil için zorunlu
      ]).catchError((_) => []); // Hata olsa bile devam et
    }

    // 4. İkisini birden bekle ama maksimum 4 saniye timeout koy
    // Böylece internet yavaşsa bile kullanıcı splash'te takılı kalmaz.
    await Future.wait([
      minSplashDuration,
      dataLoadFuture,
    ]).timeout(
      const Duration(milliseconds: 4000),
      onTimeout: () => [], // Timeout olursa sessizce geç
    );

    if (!mounted) return;

    // 5. Yönlendirme
    if (!hasCompletedOnboarding) {
      context.go('/onboarding');
    } else if (!isLoggedIn) {
      context.go('/login');
    } else {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // ─── Gradient arka plan efekti ─────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [
                    AppColors.darkSurfaceElevated, // Ortada hafif açık
                    AppColors.darkBackground, // Kenarlarda koyu
                  ],
                ),
              ),
            ),
          ),

          // ─── Logo glow efekti ─────────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                final glowOpacity =
                    0.15 + (_glowController.value * 0.15); // 0.15 → 0.30
                return Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.primary.withValues(alpha: glowOpacity),
                        blurRadius: 80,
                        spreadRadius: 20,
                      ),
                      BoxShadow(
                        color: AppColors.secondary
                            .withValues(alpha: glowOpacity * 0.5),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ─── Logo + Text + Loading ────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: SvgPicture.asset(
                    'assets/splash/unisec_mark.svg',
                    width: 130,
                    height: 130,
                  ),
                ),

                const SizedBox(height: 28),

                // "ÜniSeç" yazısı
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: const Text(
                      'ÜniSeç',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Alt yazı
                FadeTransition(
                  opacity: _textFade,
                  child: Text(
                    'Üniversite Yaşam Rehberin',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Dönen loading göstergesi ─────────────────────────
          Positioned(
            bottom: 72,
            left: 0,
            right: 0,
            child: FadeTransition(
               opacity: _loadingFade,
               child: Center(
                 child: SizedBox(
                   width: 22,
                   height: 22,
                   child: CircularProgressIndicator(
                     color: AppColors.primary,
                     strokeWidth: 2.0,
                   ),
                 ),
               ),
            ),
          ),

          // ─── Alt copyright ────────────────────────────────────
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _loadingFade,
              child: Text(
                '© 2026 ÜniSeç',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.25),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
