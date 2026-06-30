import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/discover/presentation/pages/discover_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/journal/presentation/pages/journal_page.dart';
import '../../features/marathon/data/marathon_data.dart';
import '../../features/marathon/presentation/pages/marathon_details_page.dart';
import '../../features/marathon/presentation/pages/marathon_page.dart';
import '../../features/movie_details/presentation/pages/movie_details_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/preference_settings_page.dart';
import '../../features/random_pick/presentation/pages/random_pick_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shell/presentation/pages/app_shell.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/statistics/presentation/pages/statistics_page.dart';
import '../../features/watched/presentation/pages/watched_page.dart';
import '../../features/watchlist/presentation/pages/watchlist_page.dart';

class AppRouter {
  const AppRouter._();

  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (context, state) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) => const DiscoverPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/marathons',
                builder: (context, state) => const MarathonPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pick',
                builder: (context, state) => const RandomPickPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/movie/:id',
        builder: (context, state) =>
            MovieDetailsPage(movieId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/journal',
        builder: (context, state) => const JournalPage(),
      ),
      GoRoute(
        path: '/watchlist',
        builder: (context, state) => const WatchlistPage(),
      ),
      GoRoute(
        path: '/marathon/:id',
        builder: (context, state) {
          final marathon = marathonById(state.pathParameters['id']!);
          return MarathonDetailsPage(marathon: marathon);
        },
      ),
      GoRoute(
        path: '/watched',
        builder: (context, state) => const WatchedPage(),
      ),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const StatisticsPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/preferences',
        builder: (context, state) => const PreferenceSettingsPage(),
      ),
    ],
  );
}
