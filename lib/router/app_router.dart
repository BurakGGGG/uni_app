import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../features/reviews/presentation/providers/review_providers.dart';
import '../core/providers/shared_preferences_provider.dart';
import 'go_router_refresh_stream.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/home/presentation/screens/explore_screen.dart';
import '../features/comparison/presentation/screens/comparison_screen.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/university/presentation/screens/university_detail_screen.dart';
import '../features/university/presentation/screens/department_detail_screen.dart';
import '../features/home/presentation/screens/search_screen.dart';
import '../features/university/presentation/screens/city_universities_screen.dart';
import '../features/university/presentation/screens/all_cities_screen.dart';
import '../features/reviews/presentation/screens/write_review_screen.dart';
import '../features/reviews/presentation/screens/my_reviews_screen.dart';
import '../features/reviews/domain/models/review_model.dart';
import 'app_shell.dart';

/// Uygulama route isimleri
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String explore = '/explore';
  static const String compare = '/compare';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String universityDetail = '/university/:uniId';
  static const String placeDetail = '/university/:uniId/place/:placeId';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String editProfile = '/edit-profile';
  static const String cityDetail = '/city/:cityId';
  static const String departmentDetail = '/department/:deptId';
  static const String allCities = '/cities';
  static const String writeReview = '/write-review/:type/:targetId';
}

/// GoRouter konfigürasyon provider'ı
final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);

  return GoRouter(
    initialLocation: (prefs.getBool('onboarding_completed') ?? false) ? AppRoutes.home : AppRoutes.onboarding,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    redirect: (context, state) {
      final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final path = state.uri.path;
      final isGoingToAuth = path == AppRoutes.login || path == AppRoutes.register;
      final isGoingToOnboarding = path == AppRoutes.onboarding;

      // 1. Onboarding bitmemişse
      if (!hasCompletedOnboarding && !isGoingToOnboarding) {
        return AppRoutes.onboarding;
      }

      // 2. Korumalı Rotalar (Sprint 3'te yorum rotaları buraya eklenecek)
      final protectedRoutes = [AppRoutes.editProfile, '/my-reviews'];
      final isGoingToProtected = protectedRoutes.contains(path) || path.startsWith('/write-review') || path.startsWith('/edit-review');

      if (isGoingToProtected && !isLoggedIn) {
        final encodedPath = Uri.encodeComponent(state.uri.toString());
        return '${AppRoutes.login}?from=$encodedPath'; // Kullanıcı giriş yapmamışsa login'e at, geri döneceği yeri sakla
      }

      // 3. Giriş yapmış kullanıcı auth sayfalarına erişemez
      if (isLoggedIn && isGoingToAuth) {
        // from parametresi varsa oraya yönlendir (korumalı rotadan gelmiş olabilir)
        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty) {
          return from;
        }
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
    // ─── Arama ───────────────────────────────────────────────────
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),

    // ─── Auth & Profile Routes ───────────────────────────────────
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/university/:uniId',
      builder: (context, state) => UniversityDetailScreen(
        universityId: state.pathParameters['uniId']!,
      ),
    ),
    GoRoute(
      path: '/write-review/:type/:targetId',
      builder: (context, state) {
        final typeStr = state.pathParameters['type']!;
        final targetId = state.pathParameters['targetId']!;
        final type = typeStr == 'department'
            ? ReviewType.department
            : ReviewType.university;
        // Department ise universityId'yi query parametreden al
        final universityId = state.uri.queryParameters['uni'] ?? targetId;
        return WriteReviewScreen(
          type: type,
          targetId: targetId,
          universityId: universityId,
        );
      },
    ),
    GoRoute(
      path: '/edit-review/:reviewId',
      builder: (context, state) {
        final reviewId = state.pathParameters['reviewId']!;
        return Consumer(
          builder: (context, ref, _) {
            final reviewAsync = ref.watch(reviewDetailProvider(reviewId));
            return reviewAsync.when(
              data: (r) {
                if (r == null) {
                  return const Scaffold(body: Center(child: Text('Yorum bulunamadı')));
                }
                return WriteReviewScreen(
                  targetId: r.targetId,
                  type: r.type,
                  universityId: r.universityId,
                  initialReview: r,
                );
              },
              loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
              error: (e, _) => Scaffold(body: Center(child: Text('Hata: $e'))),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/my-reviews',
      builder: (context, state) => const MyReviewsScreen(),
    ),
    GoRoute(
      path: AppRoutes.departmentDetail,
      builder: (context, state) => DepartmentDetailScreen(
        departmentId: state.pathParameters['deptId']!,
      ),
    ),
    GoRoute(
      path: AppRoutes.cityDetail,
      builder: (context, state) => CityUniversitiesScreen(
        cityId: state.pathParameters['cityId']!,
      ),
    ),
    GoRoute(
      path: AppRoutes.allCities,
      builder: (context, state) => const AllCitiesScreen(),
    ),

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
});
