import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../features/reviews/presentation/providers/review_providers.dart';
import '../features/reviews/presentation/screens/all_reviews_screen.dart';
import '../features/places/presentation/screens/place_detail_screen.dart';
import '../core/providers/shared_preferences_provider.dart';
import 'go_router_refresh_stream.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/home/presentation/screens/explore_screen.dart';
import '../features/comparison/presentation/screens/comparison_hub_screen.dart';
import '../features/comparison/presentation/screens/university_comparison_screen.dart';
import '../features/comparison/presentation/screens/department_comparison_screen.dart';
import '../features/comparison/presentation/screens/city_comparison_screen.dart';
import '../features/monetization/presentation/screens/paywall_screen.dart';
import '../features/notifications/presentation/screens/notification_center_screen.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/badges_screen.dart';
import '../features/university/presentation/screens/university_detail_screen.dart';
import '../features/university/presentation/screens/department_detail_screen.dart';
import '../features/university/presentation/screens/uni_departments_screen.dart';
import '../features/university/presentation/screens/uni_places_screen.dart';
import '../features/university/presentation/screens/uni_reviews_screen.dart';
import '../features/university/presentation/screens/university_gallery_screen.dart';
import '../features/university/presentation/screens/uni_ratings_screen.dart';
import '../features/home/presentation/screens/search_screen.dart';
import '../features/university/presentation/screens/city_universities_screen.dart';
import '../features/university/presentation/screens/all_cities_screen.dart';
import '../features/reviews/presentation/screens/write_review_screen.dart';
import '../features/reviews/presentation/screens/my_reviews_screen.dart';
import '../features/reviews/domain/models/review_model.dart';
import '../features/profile/presentation/screens/public_profile_screen.dart';
import '../features/home/presentation/screens/splash_screen.dart';
import '../features/preference_lists/presentation/screens/my_lists_screen.dart';
import '../features/preference_lists/presentation/screens/list_edit_screen.dart';
import '../features/preference_lists/presentation/screens/shared_list_screen.dart';
import '../features/practice_exams/presentation/screens/practice_exams_screen.dart';
import '../features/score_calculator/presentation/screens/score_calculator_screen.dart';
import '../features/score_calculator/presentation/screens/score_result_screen.dart';
import '../features/best_programs/presentation/screens/best_programs_screen.dart';
import '../features/preference_wizard/presentation/screens/preference_wizard_screen.dart';
import '../features/preference_wizard/presentation/screens/preference_wizard_results_screen.dart';
import '../features/admin/presentation/screens/admin_panel_screen.dart';
import '../features/admin/presentation/screens/admin_story_panel_screen.dart';
import '../features/admin/presentation/screens/admin_reports_screen.dart';
import '../features/admin/presentation/screens/admin_stats_screen.dart';
import '../features/admin/presentation/screens/admin_logs_screen.dart';
import '../features/admin/presentation/screens/admin_access_denied_screen.dart';
import '../features/admin/presentation/screens/admin_suggestions_screen.dart';
import '../features/places/presentation/screens/suggest_place_screen.dart';
import 'app_shell.dart';
import 'redirect_utils.dart';

/// Uygulama route isimleri
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/';
  static const String explore = '/explore';
  static const String compare = '/compare';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String universityDetail = '/university/:uniId';
  static const String placeDetail = '/place/:placeId';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String editProfile = '/edit-profile';
  static const String badges = '/badges';
  static const String cityDetail = '/city/:cityId';
  static const String departmentDetail = '/department/:deptId';
  static const String allCities = '/cities';
  static const String writeReview = '/write-review/:type/:targetId';
  static const String allReviews = '/all-reviews';
  static const String universityDepartments = '/university/:uniId/departments';
  static const String universityPlaces = '/university/:uniId/places';
  static const String universityReviews = '/university/:uniId/reviews';
  static const String admin = '/admin';
  static const String adminStories = '/admin/stories';
  static const String adminReports = '/admin/reports';
  static const String adminStats = '/admin/stats';
  static const String adminLogs = '/admin/logs';
  static const String adminSuggestions = '/admin/suggestions';
  static const String suggestPlace = '/suggest-place';
  static const String forbidden = '/403';
  static const String preferenceWizard = '/preference-wizard';
  static const String preferenceWizardResults = '/preference-wizard/results';
  static const String scoreCalculator = '/score-calculator';
  static const String scoreCalculatorHistory = '/score-calculator/history';
  static const String myLists = '/my-lists';
  static const String bestPrograms = '/best-programs';
  static const String practiceExams = '/practice-exams';
}

/// GoRouter konfigürasyon provider'ı
final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) {
      final hasCompletedOnboarding =
          prefs.getBool('onboarding_completed') ?? false;
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final path = state.uri.path;
      final isGoingToAuth =
          path == AppRoutes.login || path == AppRoutes.register;
      final isGoingToOnboarding = path == AppRoutes.onboarding;
      final isGoingToSplash = path == AppRoutes.splash;
      final isGoingToAdmin =
          path == AppRoutes.admin || path.startsWith('${AppRoutes.admin}/');

      // 0. Splash ekranındayken yönlendirme yapma
      if (isGoingToSplash) {
        return null;
      }

      // 1. Onboarding bitmemişse — hedef rota (ör. paylaşım deep link'i)
      // kaybolmasın diye from parametresiyle taşınır
      if (!hasCompletedOnboarding && !isGoingToOnboarding) {
        final target = state.uri.toString();
        if (target == AppRoutes.home) return AppRoutes.onboarding;
        return routeWithLocalFrom(AppRoutes.onboarding, target);
      }

      // 2. Korumalı Rotalar (Sprint 3'te yorum rotaları buraya eklenecek)
      final protectedRoutes = [AppRoutes.editProfile, '/my-reviews', AppRoutes.suggestPlace];
      final isGoingToProtected =
          protectedRoutes.contains(path) ||
          isGoingToAdmin ||
          path.startsWith('/write-review') ||
          path.startsWith('/edit-review');

      if (isGoingToProtected && !isLoggedIn) {
        final encodedPath = Uri.encodeComponent(state.uri.toString());
        return '${AppRoutes.login}?from=$encodedPath'; // Kullanıcı giriş yapmamışsa login'e at, geri döneceği yeri sakla
      }

      // 3. Giriş yapmış kullanıcı auth sayfalarına erişemez
      if (isLoggedIn && isGoingToAuth) {
        // from parametresi varsa oraya yönlendir (korumalı rotadan gelmiş olabilir)
        final from = localRedirectPathFromParam(
          state.uri.queryParameters['from'],
        );
        if (from != null) {
          return from;
        }
        return AppRoutes.home;
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sayfa bulunamadı',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aradığınız içerik taşınmış veya silinmiş olabilir.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
      ),
    ),
    routes: [
      // ─── Splash ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ─── Admin ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.forbidden,
        builder: (context, state) => const AdminAccessDeniedScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) =>
            const _AdminRouteGuard(child: AdminPanelScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminStories,
        builder: (context, state) =>
            const _AdminRouteGuard(child: AdminStoryPanelScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminReports,
        builder: (context, state) =>
            const _AdminRouteGuard(child: AdminReportsScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminStats,
        builder: (context, state) =>
            const _AdminRouteGuard(child: AdminStatsScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminLogs,
        builder: (context, state) =>
            const _AdminRouteGuard(child: AdminLogsScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminSuggestions,
        builder: (context, state) =>
            const _AdminRouteGuard(child: AdminSuggestionsScreen()),
      ),
      GoRoute(
        path: AppRoutes.suggestPlace,
        builder: (context, state) => SuggestPlaceScreen(
          universityId: state.uri.queryParameters['uniId'] ?? '',
          universityName: state.uri.queryParameters['uniName'] ?? '',
        ),
      ),

      // ─── Arama ───────────────────────────────────────────────────
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),

      // ─── Bildirimler ──────────────────────────────────────────────
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),

      // ─── Tüm Yorumlar ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.allReviews,
        builder: (context, state) => const AllReviewsScreen(),
      ),

      // ─── Mekan Detayı ─────────────────────────────────────────
      GoRoute(
        path: '/place/:placeId',
        builder: (context, state) =>
            PlaceDetailScreen(placeId: state.pathParameters['placeId']!),
      ),

      // ─── Auth & Profile Routes ───────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) =>
            OnboardingScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) =>
            LoginScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) =>
            RegisterScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),

      // ─── Public Profil ─────────────────────────────────────────
      GoRoute(
        path: '/user/:userId',
        builder: (context, state) =>
            PublicProfileScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        path: '/university/:uniId',
        builder: (context, state) => UniversityDetailScreen(
          universityId: state.pathParameters['uniId']!,
        ),
      ),
      GoRoute(
        path: '/university/:uniId/departments',
        builder: (context, state) =>
            UniDepartmentsScreen(universityId: state.pathParameters['uniId']!),
      ),
      GoRoute(
        path: '/university/:uniId/places',
        builder: (context, state) =>
            UniPlacesScreen(universityId: state.pathParameters['uniId']!),
      ),
      GoRoute(
        path: '/university/:uniId/reviews',
        builder: (context, state) =>
            UniReviewsScreen(universityId: state.pathParameters['uniId']!),
      ),
      GoRoute(
        path: '/university/:uniId/gallery',
        builder: (context, state) => UniversityGalleryScreen(
          universityId: state.pathParameters['uniId']!,
        ),
      ),
      GoRoute(
        path: '/university/:uniId/ratings',
        builder: (context, state) =>
            UniRatingsScreen(universityId: state.pathParameters['uniId']!),
      ),
      // NOT: Giriş kontrolü global redirect'teki korumalı rota listesinde
      // yapılır (/write-review oradadır). Route seviyesinde currentUserProvider
      // okumak, provider henüz yüklenmemişken giriş yapmış kullanıcıyı da
      // login'e fırlatan bir yarış durumu yaratıyordu.
      GoRoute(
        path: '/write-review/:type/:targetId',
        builder: (context, state) {
          final typeStr = state.pathParameters['type']!;
          final targetId = state.pathParameters['targetId']!;
          final type = ReviewType.values.firstWhere(
            (t) => t.name == typeStr,
            orElse: () => ReviewType.university,
          );
          // Department ise universityId'yi query parametreden al
          // Place ise universityId query param'dan gelir
          final universityId = state.uri.queryParameters['uni'] ?? targetId;
          final placeSubType = state.uri.queryParameters['pt'];
          return WriteReviewScreen(
            type: type,
            targetId: targetId,
            universityId: universityId,
            placeSubType: placeSubType,
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
                    return const Scaffold(
                      body: Center(child: Text('Yorum bulunamadı')),
                    );
                  }
                  return WriteReviewScreen(
                    targetId: r.targetId,
                    type: r.type,
                    universityId: r.universityId,
                    initialReview: r,
                  );
                },
                loading: () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    Scaffold(body: Center(child: Text('Hata: $e'))),
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
        path: AppRoutes.badges,
        builder: (context, state) => const BadgesScreen(),
      ),
      GoRoute(
        path: AppRoutes.departmentDetail,
        builder: (context, state) => DepartmentDetailScreen(
          departmentId: state.pathParameters['deptId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.cityDetail,
        builder: (context, state) =>
            CityUniversitiesScreen(cityId: state.pathParameters['cityId']!),
      ),
      GoRoute(
        path: AppRoutes.allCities,
        builder: (context, state) => const AllCitiesScreen(),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/my-lists/:listId',
        builder: (context, state) =>
            ListEditScreen(listId: state.pathParameters['listId']!),
      ),
      GoRoute(
        path: '/list/:shareSlug',
        builder: (context, state) =>
            SharedListScreen(shareSlug: state.pathParameters['shareSlug']!),
      ),

      // ─── Karşılaştırma Alt Rotaları ────────────────────────────────
      GoRoute(
        path: '/compare/university',
        builder: (context, state) => UniversityComparisonScreen(
          initialAId: state.uri.queryParameters['a'],
          initialBId: state.uri.queryParameters['b'],
        ),
      ),
      GoRoute(
        path: '/compare/department',
        builder: (context, state) => DepartmentComparisonScreen(
          initialAId: state.uri.queryParameters['a'],
          initialBId: state.uri.queryParameters['b'],
        ),
      ),
      GoRoute(
        path: '/compare/city',
        builder: (context, state) => CityComparisonScreen(
          initialAId: state.uri.queryParameters['a'],
          initialBId: state.uri.queryParameters['b'],
        ),
      ),
      GoRoute(
        path: '/compare/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),

      // ─── Puan Hesaplayıcı ─────────────────────────────────────────
      GoRoute(
        path: '/score-calculator',
        builder: (context, state) => const ScoreCalculatorScreen(),
      ),
      // Eski "Deneme Geçmişi" rotası Denemelerim'e taşındı; dışarıdan gelen
      // linkler kırılmasın diye yönlendiriliyor.
      GoRoute(
        path: AppRoutes.scoreCalculatorHistory,
        redirect: (context, state) => AppRoutes.practiceExams,
      ),
      GoRoute(
        path: '/score-result',
        builder: (context, state) => const ScoreResultScreen(),
      ),

      // ─── Denemelerim ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.practiceExams,
        builder: (context, state) => const PracticeExamsScreen(),
      ),

      // ─── En İyi Bölümler ─────────────────────────────────────────
      // ?dept=Tıp → tek bölümün programları; ?category=muhendislik → alan.
      GoRoute(
        path: AppRoutes.bestPrograms,
        builder: (context, state) => BestProgramsScreen(
          departmentName: state.uri.queryParameters['dept'],
          categoryKey: state.uri.queryParameters['category'],
        ),
      ),

      // ─── Tercih Robotu ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.preferenceWizard,
        builder: (context, state) => const PreferenceWizardScreen(),
      ),
      GoRoute(
        path: AppRoutes.preferenceWizardResults,
        builder: (context, state) => const PreferenceWizardResultsScreen(),
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
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),
          // Keşfet
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.explore,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ExploreScreen()),
              ),
            ],
          ),
          // Karşılaştır
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.compare,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ComparisonHubScreen()),
              ),
            ],
          ),
          // Listelerim
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-lists',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MyListsScreen()),
              ),
            ],
          ),
          // Profil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AdminRouteGuard extends ConsumerWidget {
  final Widget child;

  const _AdminRouteGuard({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(currentUserAdminProvider);

    return isAdminAsync.when(
      data: (isAdmin) {
        if (isAdmin) return child;
        return const AdminAccessDeniedScreen();
      },
      loading: () => const AdminAccessCheckScreen(),
      error: (_, _) => AdminAccessDeniedScreen(
        title: 'Yetki doğrulanamadı',
        message:
            'Admin yetkisi kontrol edilirken bir sorun oluştu. Admin ekranı güvenli şekilde kapatıldı.',
        onRetry: () => ref.invalidate(currentUserAdminProvider),
      ),
    );
  }
}
