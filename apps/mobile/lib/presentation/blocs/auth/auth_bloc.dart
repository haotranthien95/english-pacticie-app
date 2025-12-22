import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/usecases/auth/login_usecase.dart';
import '../../../domain/usecases/auth/register_usecase.dart';
import '../../../domain/usecases/auth/social_login_usecase.dart';
import '../../../domain/usecases/auth/logout_usecase.dart';
import '../../../domain/usecases/auth/get_current_user_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC for authentication state management
/// Handles login, registration, social auth, and logout flows
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final SocialLoginUseCase socialLoginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.socialLoginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(const AuthInitial()) {
    // Register event handlers
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<SocialLoginRequested>(_onSocialLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  /// Check authentication status on app start
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.info('[AuthBloc] Checking authentication status...');
    emit(const AuthLoading());

    final result = await getCurrentUserUseCase();

    result.fold(
      (failure) {
        AppLogger.info('[AuthBloc] No authenticated user found');
        emit(const AuthUnauthenticated());
      },
      (user) {
        AppLogger.info('[AuthBloc] User authenticated: ${user.email}');
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  /// Handle login request
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.info('[AuthBloc] Login attempt for: ${event.email}');
    emit(const AuthLoading());

    final result = await loginUseCase(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) {
        AppLogger.error('[AuthBloc] Login failed: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (user) {
        AppLogger.info('[AuthBloc] Login successful: ${user.email}');
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  /// Handle registration request
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.info('[AuthBloc] Registration attempt for: ${event.email}');
    emit(const AuthLoading());

    final result = await registerUseCase(
      email: event.email,
      password: event.password,
      username: event.username,
      displayName: event.displayName,
    );

    result.fold(
      (failure) {
        AppLogger.error('[AuthBloc] Registration failed: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (user) {
        AppLogger.info('[AuthBloc] Registration successful: ${user.email}');
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  /// Handle social login request
  Future<void> _onSocialLoginRequested(
    SocialLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.info('[AuthBloc] Social login attempt with: ${event.provider}');
    emit(const AuthLoading());

    final result = await socialLoginUseCase(provider: event.provider);

    result.fold(
      (failure) {
        AppLogger.error('[AuthBloc] Social login failed: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (user) {
        AppLogger.info('[AuthBloc] Social login successful: ${user.email}');
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  /// Handle logout request
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.info('[AuthBloc] Logout requested');
    emit(const AuthLoading());

    final result = await logoutUseCase();

    result.fold(
      (failure) {
        AppLogger.error('[AuthBloc] Logout failed: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (_) {
        AppLogger.info('[AuthBloc] Logout successful');
        emit(const AuthUnauthenticated());
      },
    );
  }
}
