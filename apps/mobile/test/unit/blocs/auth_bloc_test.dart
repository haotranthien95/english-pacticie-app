import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:english_learning_app/core/constants/enums.dart';
import 'package:english_learning_app/core/errors/failures.dart';
import 'package:english_learning_app/domain/entities/user.dart';
import 'package:english_learning_app/domain/usecases/auth/login_usecase.dart';
import 'package:english_learning_app/domain/usecases/auth/register_usecase.dart';
import 'package:english_learning_app/domain/usecases/auth/social_login_usecase.dart';
import 'package:english_learning_app/domain/usecases/auth/logout_usecase.dart';
import 'package:english_learning_app/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:english_learning_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:english_learning_app/presentation/blocs/auth/auth_event.dart';
import 'package:english_learning_app/presentation/blocs/auth/auth_state.dart';

import 'auth_bloc_test.mocks.dart';

// Generate mocks for use cases
@GenerateMocks([
  LoginUseCase,
  RegisterUseCase,
  SocialLoginUseCase,
  LogoutUseCase,
  GetCurrentUserUseCase,
])
void main() {
  late AuthBloc authBloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockSocialLoginUseCase mockSocialLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;

  // Test data
  const tEmail = 'test@example.com';
  const tPassword = 'Password123!';
  const tUsername = 'testuser';
  const tDisplayName = 'Test User';
  final tUser = User(
    id: '123',
    email: tEmail,
    username: tUsername,
    displayName: tDisplayName,
    authProvider: AuthProvider.email,
    createdAt: DateTime(2024, 1, 1),
  );
  const tAuthFailure = AuthFailure(
    message: 'Invalid credentials',
    code: 'auth/invalid-credentials',
  );
  const tNetworkFailure = NetworkFailure(
    message: 'No internet connection',
    code: 'network/no-connection',
  );

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    mockSocialLoginUseCase = MockSocialLoginUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();

    authBloc = AuthBloc(
      loginUseCase: mockLoginUseCase,
      registerUseCase: mockRegisterUseCase,
      socialLoginUseCase: mockSocialLoginUseCase,
      logoutUseCase: mockLogoutUseCase,
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state should be AuthInitial', () {
      expect(authBloc.state, equals(const AuthInitial()));
    });

    group('AuthCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when user is logged in',
        build: () {
          when(mockGetCurrentUserUseCase())
              .thenAnswer((_) async => Right(tUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthLoading(),
          AuthAuthenticated(user: tUser),
        ],
        verify: (_) {
          verify(mockGetCurrentUserUseCase()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when user is not logged in',
        build: () {
          when(mockGetCurrentUserUseCase())
              .thenAnswer((_) async => const Left(tAuthFailure));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(),
        ],
        verify: (_) {
          verify(mockGetCurrentUserUseCase()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] on token expired',
        build: () {
          when(mockGetCurrentUserUseCase()).thenAnswer(
            (_) async => const Left(
              AuthFailure(
                message: 'Token expired',
                code: 'auth/token-expired',
              ),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(),
        ],
      );
    });

    group('LoginRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when login succeeds',
        build: () {
          when(mockLoginUseCase(email: tEmail, password: tPassword))
              .thenAnswer((_) async => Right(tUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const LoginRequested(email: tEmail, password: tPassword),
        ),
        expect: () => [
          const AuthLoading(),
          AuthAuthenticated(user: tUser),
        ],
        verify: (_) {
          verify(mockLoginUseCase(email: tEmail, password: tPassword))
              .called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when login fails with invalid credentials',
        build: () {
          when(mockLoginUseCase(email: tEmail, password: tPassword))
              .thenAnswer((_) async => const Left(tAuthFailure));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const LoginRequested(email: tEmail, password: tPassword),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Invalid credentials'),
        ],
        verify: (_) {
          verify(mockLoginUseCase(email: tEmail, password: tPassword))
              .called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when login fails with network error',
        build: () {
          when(mockLoginUseCase(email: tEmail, password: tPassword))
              .thenAnswer((_) async => const Left(tNetworkFailure));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const LoginRequested(email: tEmail, password: tPassword),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'No internet connection'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when login fails with user not found',
        build: () {
          when(mockLoginUseCase(email: tEmail, password: tPassword)).thenAnswer(
            (_) async => const Left(
              AuthFailure(
                message: 'User not found',
                code: 'auth/user-not-found',
              ),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const LoginRequested(email: tEmail, password: tPassword),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'User not found'),
        ],
      );
    });

    group('RegisterRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when registration succeeds',
        build: () {
          when(mockRegisterUseCase(
            email: tEmail,
            password: tPassword,
            username: tUsername,
            displayName: tDisplayName,
          )).thenAnswer((_) async => Right(tUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const RegisterRequested(
            email: tEmail,
            password: tPassword,
            username: tUsername,
            displayName: tDisplayName,
          ),
        ),
        expect: () => [
          const AuthLoading(),
          AuthAuthenticated(user: tUser),
        ],
        verify: (_) {
          verify(mockRegisterUseCase(
            email: tEmail,
            password: tPassword,
            username: tUsername,
            displayName: tDisplayName,
          )).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when registration succeeds without displayName',
        build: () {
          final userWithoutDisplayName = User(
            id: '123',
            email: tEmail,
            username: tUsername,
            authProvider: AuthProvider.email,
            createdAt: DateTime(2024, 1, 1),
          );
          when(mockRegisterUseCase(
            email: tEmail,
            password: tPassword,
            username: tUsername,
            displayName: null,
          )).thenAnswer((_) async => Right(userWithoutDisplayName));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const RegisterRequested(
            email: tEmail,
            password: tPassword,
            username: tUsername,
          ),
        ),
        expect: () => [
          const AuthLoading(),
          AuthAuthenticated(
            user: User(
              id: '123',
              email: tEmail,
              username: tUsername,
              authProvider: AuthProvider.email,
              createdAt: DateTime(2024, 1, 1),
            ),
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when email already exists',
        build: () {
          when(mockRegisterUseCase(
            email: tEmail,
            password: tPassword,
            username: tUsername,
            displayName: tDisplayName,
          )).thenAnswer(
            (_) async => const Left(
              AuthFailure(
                message: 'Email already in use',
                code: 'auth/email-already-in-use',
              ),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const RegisterRequested(
            email: tEmail,
            password: tPassword,
            username: tUsername,
            displayName: tDisplayName,
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Email already in use'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when username already exists',
        build: () {
          when(mockRegisterUseCase(
            email: tEmail,
            password: tPassword,
            username: tUsername,
            displayName: tDisplayName,
          )).thenAnswer(
            (_) async => const Left(
              AuthFailure(
                message: 'Username already taken',
                code: 'auth/username-taken',
              ),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const RegisterRequested(
            email: tEmail,
            password: tPassword,
            username: tUsername,
            displayName: tDisplayName,
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Username already taken'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when password is weak',
        build: () {
          when(mockRegisterUseCase(
            email: tEmail,
            password: tPassword,
            username: tUsername,
            displayName: tDisplayName,
          )).thenAnswer(
            (_) async => const Left(
              AuthFailure(
                message: 'Password is too weak',
                code: 'auth/weak-password',
              ),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const RegisterRequested(
            email: tEmail,
            password: tPassword,
            username: tUsername,
            displayName: tDisplayName,
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Password is too weak'),
        ],
      );
    });

    group('SocialLoginRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when Google login succeeds',
        build: () {
          final googleUser = User(
            id: '456',
            email: 'google@example.com',
            username: 'googleuser',
            displayName: 'Google User',
            authProvider: AuthProvider.google,
            createdAt: DateTime(2024, 1, 1),
          );
          when(mockSocialLoginUseCase(provider: AuthProvider.google))
              .thenAnswer((_) async => Right(googleUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const SocialLoginRequested(provider: AuthProvider.google),
        ),
        expect: () => [
          const AuthLoading(),
          AuthAuthenticated(
            user: User(
              id: '456',
              email: 'google@example.com',
              username: 'googleuser',
              displayName: 'Google User',
              authProvider: AuthProvider.google,
              createdAt: DateTime(2024, 1, 1),
            ),
          ),
        ],
        verify: (_) {
          verify(mockSocialLoginUseCase(provider: AuthProvider.google))
              .called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when Apple login succeeds',
        build: () {
          final appleUser = User(
            id: '789',
            email: 'apple@example.com',
            username: 'appleuser',
            displayName: 'Apple User',
            authProvider: AuthProvider.apple,
            createdAt: DateTime(2024, 1, 1),
          );
          when(mockSocialLoginUseCase(provider: AuthProvider.apple))
              .thenAnswer((_) async => Right(appleUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const SocialLoginRequested(provider: AuthProvider.apple),
        ),
        expect: () => [
          const AuthLoading(),
          AuthAuthenticated(
            user: User(
              id: '789',
              email: 'apple@example.com',
              username: 'appleuser',
              displayName: 'Apple User',
              authProvider: AuthProvider.apple,
              createdAt: DateTime(2024, 1, 1),
            ),
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when Facebook login succeeds',
        build: () {
          final facebookUser = User(
            id: '012',
            email: 'facebook@example.com',
            username: 'facebookuser',
            displayName: 'Facebook User',
            authProvider: AuthProvider.facebook,
            createdAt: DateTime(2024, 1, 1),
          );
          when(mockSocialLoginUseCase(provider: AuthProvider.facebook))
              .thenAnswer((_) async => Right(facebookUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const SocialLoginRequested(provider: AuthProvider.facebook),
        ),
        expect: () => [
          const AuthLoading(),
          AuthAuthenticated(
            user: User(
              id: '012',
              email: 'facebook@example.com',
              username: 'facebookuser',
              displayName: 'Facebook User',
              authProvider: AuthProvider.facebook,
              createdAt: DateTime(2024, 1, 1),
            ),
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when social login is cancelled',
        build: () {
          when(mockSocialLoginUseCase(provider: AuthProvider.google))
              .thenAnswer(
            (_) async => const Left(
              AuthFailure(
                message: 'Sign in cancelled by user',
                code: 'auth/cancelled',
              ),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const SocialLoginRequested(provider: AuthProvider.google),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Sign in cancelled by user'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when social login fails with network error',
        build: () {
          when(mockSocialLoginUseCase(provider: AuthProvider.apple))
              .thenAnswer((_) async => const Left(tNetworkFailure));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const SocialLoginRequested(provider: AuthProvider.apple),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'No internet connection'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when social login account already exists',
        build: () {
          when(mockSocialLoginUseCase(provider: AuthProvider.facebook))
              .thenAnswer(
            (_) async => const Left(
              AuthFailure(
                message: 'Account already exists with different credentials',
                code: 'auth/account-exists-with-different-credential',
              ),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const SocialLoginRequested(provider: AuthProvider.facebook),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(
            message: 'Account already exists with different credentials',
          ),
        ],
      );
    });

    group('LogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when logout succeeds',
        build: () {
          when(mockLogoutUseCase()).thenAnswer((_) async => const Right(unit));
          return authBloc;
        },
        act: (bloc) => bloc.add(const LogoutRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(),
        ],
        verify: (_) {
          verify(mockLogoutUseCase()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when logout fails',
        build: () {
          when(mockLogoutUseCase()).thenAnswer(
            (_) async => const Left(
              AuthFailure(
                message: 'Failed to logout',
                code: 'auth/logout-failed',
              ),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const LogoutRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Failed to logout'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when logout fails with network error',
        build: () {
          when(mockLogoutUseCase())
              .thenAnswer((_) async => const Left(tNetworkFailure));
          return authBloc;
        },
        act: (bloc) => bloc.add(const LogoutRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'No internet connection'),
        ],
      );
    });

    group('Multiple events', () {
      blocTest<AuthBloc, AuthState>(
        'handles multiple login attempts correctly',
        build: () {
          when(mockLoginUseCase(email: tEmail, password: tPassword))
              .thenAnswer((_) async => const Left(tAuthFailure));
          when(mockLoginUseCase(email: tEmail, password: 'CorrectPassword123!'))
              .thenAnswer((_) async => Right(tUser));
          return authBloc;
        },
        act: (bloc) async {
          bloc.add(const LoginRequested(email: tEmail, password: tPassword));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(
            const LoginRequested(
              email: tEmail,
              password: 'CorrectPassword123!',
            ),
          );
        },
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Invalid credentials'),
          const AuthLoading(),
          AuthAuthenticated(user: tUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'handles login followed by logout',
        build: () {
          when(mockLoginUseCase(email: tEmail, password: tPassword))
              .thenAnswer((_) async => Right(tUser));
          when(mockLogoutUseCase()).thenAnswer((_) async => const Right(unit));
          return authBloc;
        },
        act: (bloc) async {
          bloc.add(const LoginRequested(email: tEmail, password: tPassword));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const LogoutRequested());
        },
        expect: () => [
          const AuthLoading(),
          AuthAuthenticated(user: tUser),
          const AuthLoading(),
          const AuthUnauthenticated(),
        ],
      );
    });

    group('State persistence', () {
      blocTest<AuthBloc, AuthState>(
        'maintains AuthAuthenticated state after successful login',
        build: () {
          when(mockLoginUseCase(email: tEmail, password: tPassword))
              .thenAnswer((_) async => Right(tUser));
          return authBloc;
        },
        act: (bloc) =>
            bloc.add(const LoginRequested(email: tEmail, password: tPassword)),
        expect: () => [
          const AuthLoading(),
          AuthAuthenticated(user: tUser),
        ],
        verify: (bloc) {
          expect(bloc.state, equals(AuthAuthenticated(user: tUser)));
        },
      );

      blocTest<AuthBloc, AuthState>(
        'maintains AuthUnauthenticated state after logout',
        build: () {
          when(mockLogoutUseCase()).thenAnswer((_) async => const Right(unit));
          return authBloc;
        },
        act: (bloc) => bloc.add(const LogoutRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(),
        ],
        verify: (bloc) {
          expect(bloc.state, equals(const AuthUnauthenticated()));
        },
      );
    });
  });
}
