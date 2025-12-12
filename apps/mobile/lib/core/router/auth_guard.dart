import 'package:flutter/material.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_state.dart';
import '../../di/injection.dart';

/// Auth guard to protect routes that require authentication
///
/// This guard checks the authentication status and can be used
/// in go_router's redirect callback to protect routes.
class AuthGuard {
  final AuthBloc _authBloc;

  AuthGuard() : _authBloc = getIt<AuthBloc>();

  /// Checks if the user is currently authenticated
  bool get isAuthenticated {
    final state = _authBloc.state;
    return state is AuthAuthenticated;
  }

  /// Determines the redirect path based on authentication status
  ///
  /// Returns:
  /// - `null` if no redirect is needed
  /// - `/login` if user is not authenticated and trying to access protected route
  /// - `/home` if user is authenticated and on an auth page
  String? redirect(BuildContext context, String currentLocation) {
    final isOnAuthPage = currentLocation == '/login' ||
        currentLocation == '/register' ||
        currentLocation == '/';

    // If not authenticated and trying to access protected route, redirect to login
    if (!isAuthenticated && !isOnAuthPage) {
      return '/login';
    }

    // If authenticated and on auth page, redirect to home
    if (isAuthenticated && isOnAuthPage) {
      return '/home';
    }

    // No redirect needed
    return null;
  }

  /// List of routes that don't require authentication
  static const List<String> publicRoutes = [
    '/',
    '/login',
    '/register',
  ];

  /// Checks if a route is public (doesn't require authentication)
  static bool isPublicRoute(String path) {
    return publicRoutes.contains(path);
  }

  /// Checks if a route requires authentication
  static bool requiresAuth(String path) {
    return !isPublicRoute(path);
  }

  /// Stream of authentication state changes
  ///
  /// Can be used with go_router's refreshListenable to automatically
  /// trigger route refresh when auth state changes
  Stream<AuthState> get authStateStream => _authBloc.stream;
}
