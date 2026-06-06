import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/offline_banner.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  @override
  void dispose() {
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
                    NavigationDestination(
                      icon: const Icon(Icons.explore_outlined),
                      selectedIcon: const Icon(
                        Icons.explore_rounded,
                        color: AppColors.primary,
                      ),
                      label: AppLocalizations.of(context).homeTabExplore,
                    ),
                    NavigationDestination(
                      icon: SvgPicture.asset(
                        'assets/icons/compare_icon_outline.svg',
                        width: 24,
                        height: 24,
                        colorFilter: isDark ? ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn) : null,
                      ),
                      selectedIcon: SvgPicture.asset(
                        'assets/icons/compare_icon.svg',
                        width: 24,
                        height: 24,
                      ),
                      label: AppLocalizations.of(context).homeTabCompare,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.list_alt_outlined),
                      selectedIcon: const Icon(
                        Icons.list_alt_rounded,
                        color: AppColors.primary,
                      ),
                      label: AppLocalizations.of(context).homeTabFavorites,
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
