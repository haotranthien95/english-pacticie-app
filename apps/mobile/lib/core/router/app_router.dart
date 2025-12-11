import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/speech.dart';
import '../../domain/entities/game_session.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_state.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/game/game_config_screen.dart';
import '../../presentation/screens/game/game_summary_screen.dart';
import '../../presentation/screens/game/listen_only_game_screen.dart';
import '../../presentation/screens/game/listen_repeat_game_screen.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/history/session_detail_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/settings_screen.dart';
import '../../di/injection.dart';

/// Route paths
class AppRoutes {
  // Auth routes
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';

  // Main app routes (protected)
  static const home = '/home';
  static const gameConfig = '/game-config';
  static const listenOnlyGame = '/game/listen-only';
  static const listenRepeatGame = '/game/listen-repeat';
  static const gameSummary = '/game/summary';
  static const history = '/history';
  static const sessionDetail = '/history/:sessionId';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const settings = '/settings';
}

/// Creates and configures the app router with go_router
GoRouter createAppRouter(BuildContext context) {
  final authBloc = getIt<AuthBloc>();

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isOnAuthPage = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.splash;

      // If not authenticated and trying to access protected route, redirect to login
      if (!isAuthenticated && !isOnAuthPage) {
        return AppRoutes.login;
      }

      // If authenticated and on auth page, redirect to home
      if (isAuthenticated && isOnAuthPage) {
        return AppRoutes.home;
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Protected routes with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeScreen(navigationShell: navigationShell);
        },
        branches: [
          // Home branch (Game Config)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.gameConfig,
                builder: (context, state) => const GameConfigScreen(),
              ),
            ],
          ),

          // History branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':sessionId',
                    builder: (context, state) {
                      final sessionId = state.pathParameters['sessionId'];
                      if (sessionId == null) {
                        return const Scaffold(
                          body: Center(child: Text('Session not found')),
                        );
                      }
                      return SessionDetailScreen(sessionId: sessionId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Profile branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Game routes (not in bottom nav)
      GoRoute(
        path: AppRoutes.home,
        redirect: (context, state) => AppRoutes.gameConfig,
      ),

      GoRoute(
        path: AppRoutes.listenOnlyGame,
        builder: (context, state) {
          // Game screens will be launched from game config with proper BLoC setup
          // This route is here for navigation completeness
          return const Scaffold(
            body: Center(child: Text('Launch game from config screen')),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.listenRepeatGame,
        builder: (context, state) {
          // Game screens will be launched from game config with proper BLoC setup
          // This route is here for navigation completeness
          return const Scaffold(
            body: Center(child: Text('Launch game from config screen')),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.gameSummary,
        builder: (context, state) {
          final session = state.extra as GameSession?;
          if (session == null) {
            return const Scaffold(
              body: Center(child: Text('No session provided')),
            );
          }
          return GameSummaryScreen(session: session);
        },
      ),

      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Helper class to refresh router when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (authState) => notifyListeners(),
        );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
