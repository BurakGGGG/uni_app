import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/offline_banner.dart';
import '../core/services/feature_discovery_service.dart';
import '../l10n/generated/app_localizations.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/university/presentation/providers/university_providers.dart';

/// Ana uygulama kabuğu — Bottom Navigation Bar ile 5 tab
class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  DateTime? _lastVerificationCheck;
  static const _verificationDebounce = Duration(minutes: 5);

  late final ShowcaseView _showcaseView;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ─── Showcase scope kaydı ────────────────────────────────────
    _showcaseView = ShowcaseView.register(
      scope: 'app_tour',
      blurValue: 4,
      overlayOpacity: 0.01,
      overlayColor: Colors.black,
      disableMovingAnimation: true,
      disableScaleAnimation: false,
      disableBarrierInteraction: false,
      enableAutoScroll: true,
      globalFloatingActionWidget: _buildSkipButton,
      onFinish: () => _onTourFinish(),
      onDismiss: (_) => _onTourFinish(),
    );

    // Uygulama ilk açılışında edu.tr doğrulamasını kontrol et (token'ı yenile)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVerification();
      // Veriyi home render'dan sonra prefetch et — 2sn gecikme ile CPU/network yükü azalır
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        ref.read(allUniversitiesProvider);
        ref.read(citiesProvider);
      });
    });
  }

  void _onTourFinish() {
    ref.read(featureDiscoveryProvider).markCompleted(
          FeatureDiscoveryService.homeCompleted,
        );
  }

  /// Sağ üst köşede "Atla" butonu
  FloatingActionWidget _buildSkipButton(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return FloatingActionWidget(
      right: 20,
      top: MediaQuery.of(context).padding.top + 82,
      child: GestureDetector(
        onTap: () => ShowcaseView.getNamed('app_tour').dismiss(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            'Rehberi Atla',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _showcaseView.unregister();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Uygulama arka plandan geri döndüğünde tekrar kontrol et
      _checkVerification();
    }
  }

  Future<void> _checkVerification() async {
    // Zaten doğrulanmış kullanıcı için hiç çağırma
    final profile = ref.read(currentUserProvider).value;
    if (profile != null && profile.isVerifiedStudent) return;

    // edu.tr maili olmayan kullanıcı için de çağırma
    if (profile != null && !profile.hasEduEmail) return;

    // Son çağrıdan beri 5 dakika geçmediyse debounce
    if (_lastVerificationCheck != null &&
        DateTime.now().difference(_lastVerificationCheck!) <
            _verificationDebounce) {
      return;
    }

    _lastVerificationCheck = DateTime.now();

    final success = await ref
        .read(authRepositoryProvider)
        .reloadAndCheckVerification();
    if (success && mounted) {
      // Firestore'daki güncel isVerifiedStudent değerini okutmak için her iki provider'ı yenile
      ref.invalidate(currentUserProvider);
      ref.invalidate(authStateProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: PopScope(
        canPop: widget.navigationShell.currentIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          // Home değilse Home'a dön
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.navigationShell.goBranch(0);
          });
        },
        child: Scaffold(
          body: OfflineBanner(child: widget.navigationShell),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(context),
              boxShadow: AppColors.bottomNavShadowFor(context),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: NavigationBar(
                  selectedIndex: widget.navigationShell.currentIndex,
                  onDestinationSelected: (index) {
                    if (index == widget.navigationShell.currentIndex) {
                      final ctrl = PrimaryScrollController.of(context);
                      if (ctrl.hasClients) {
                        ctrl.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    } else {
                      widget.navigationShell.goBranch(
                        index,
                        initialLocation: false,
                      );
                    }
                  },
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  height: 64,
                  indicatorColor: AppColors.primary.withValues(alpha: 0.12),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  animationDuration: const Duration(milliseconds: 400),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(
                        Icons.home_rounded,
                        color: AppColors.primary,
                      ),
                      label: AppLocalizations.of(context).homeTabHome,
                    ),
                    // ─── Keşfet tab — Showcase ile sarılı ────────
                    Showcase.withWidget(
                      key: AppTourKeys.exploreTab,
                      scope: 'app_tour',
                      disableMovingAnimation: true,
                      targetBorderRadius: BorderRadius.circular(16),
                      targetPadding: const EdgeInsets.all(4),
                      container: const _NavShowcaseTooltip(
                        title: 'Keşfet',
                        description:
                            'Tüm üniversiteleri filtrele, keşfet ve detaylarını incele.',
                        currentStep: 5,
                        totalSteps: 7,
                      ),
                      child: NavigationDestination(
                        icon: const Icon(Icons.explore_outlined),
                        selectedIcon: const Icon(
                          Icons.explore_rounded,
                          color: AppColors.primary,
                        ),
                        label: AppLocalizations.of(context).homeTabExplore,
                      ),
                    ),
                    // ─── Karşılaştır tab — Showcase ile sarılı ────────
                    Showcase.withWidget(
                      key: AppTourKeys.compareTab,
                      scope: 'app_tour',
                      disableMovingAnimation: true,
                      targetBorderRadius: BorderRadius.circular(16),
                      targetPadding: const EdgeInsets.all(4),
                      container: _NavShowcaseTooltip(
                        title: 'Karşılaştır',
                        description:
                            'Üniversiteleri, bölümleri veya şehirleri yan yana karşılaştır.',
                        currentStep: 6,
                        totalSteps: 7,
                      ),
                      child: NavigationDestination(
                        icon: SvgPicture.asset(
                          'assets/icons/compare_icon_outline.svg',
                          width: 24,
                          height: 24,
                          colorFilter: isDark
                              ? ColorFilter.mode(
                                  Colors.grey.shade400, BlendMode.srcIn)
                              : null,
                        ),
                        selectedIcon: SvgPicture.asset(
                          'assets/icons/compare_icon.svg',
                          width: 24,
                          height: 24,
                        ),
                        label: AppLocalizations.of(context).homeTabCompare,
                      ),
                    ),
                    // ─── Listelerim tab — Showcase ile sarılı ────────
                    Showcase.withWidget(
                      key: AppTourKeys.listsTab,
                      scope: 'app_tour',
                      disableMovingAnimation: true,
                      targetBorderRadius: BorderRadius.circular(16),
                      targetPadding: const EdgeInsets.all(4),
                      container: const _NavShowcaseTooltip(
                        title: 'Listelerim',
                        description:
                            'Favori üniversitelerini ve tercih listeni burada yönet.',
                        currentStep: 7,
                        totalSteps: 7,
                      ),
                      child: NavigationDestination(
                        icon: const Icon(Icons.list_alt_outlined),
                        selectedIcon: const Icon(
                          Icons.list_alt_rounded,
                          color: AppColors.primary,
                        ),
                        label: AppLocalizations.of(context).homeTabFavorites,
                      ),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.person_outline_rounded),
                      selectedIcon: const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                      ),
                      label: AppLocalizations.of(context).homeTabProfile,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom nav showcase'leri için dahili tooltip widget'ı.
///
/// AppShowcaseTooltip ile aynı tasarımı kullanır ancak
/// constructor parametreleri const uyumlu.
class _NavShowcaseTooltip extends StatelessWidget {
  const _NavShowcaseTooltip({
    required this.title,
    required this.description,
    required this.currentStep,
    required this.totalSteps,
  });

  final String title;
  final String description;
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return GestureDetector(
      onTap: () => ShowcaseView.getNamed('app_tour').next(),
      child: Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Adım göstergesi
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$currentStep/$totalSteps',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(totalSteps, (i) {
                  final isActive = i < currentStep;
                  return Container(
                    width: isActive ? 16 : 8,
                    height: 3,
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.65)
                  : const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Devam etmek için dokun',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.25),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
