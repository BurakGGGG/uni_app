import 'package:go_router/go_router.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/home/presentation/screens/explore_screen.dart';
import '../features/comparison/presentation/screens/comparison_screen.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import 'app_shell.dart';

/// Uygulama route isimleri
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String explore = '/explore';
  static const String compare = '/compare';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String universityDetail = '/university/:id';
  static const String departmentDetail = '/university/:uniId/department/:deptId';
  static const String placeDetail = '/university/:uniId/place/:placeId';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
}

/// GoRouter konfigürasyonu
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: true,
  routes: [
    // ─── Shell Route (Bottom Navigation) ─────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Ana Sayfa
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeScreen(),
              ),
            ),
          ],
        ),
        // Keşfet
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.explore,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ExploreScreen(),
              ),
            ),
          ],
        ),
        // Karşılaştır
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.compare,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ComparisonScreen(),
              ),
            ),
          ],
        ),
        // Favoriler
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.favorites,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: FavoritesScreen(),
              ),
            ),
          ],
        ),
        // Profil
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProfileScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
