import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:english_learning_app/core/constants/enums.dart';
import 'package:english_learning_app/core/errors/exceptions.dart';
import 'package:english_learning_app/core/errors/failures.dart';
import 'package:english_learning_app/data/datasources/local/auth_local_datasource.dart';
import 'package:english_learning_app/data/datasources/remote/auth_remote_datasource.dart';
import 'package:english_learning_app/data/datasources/remote/firebase_auth_service.dart';
import 'package:english_learning_app/data/models/user_model.dart';
import 'package:english_learning_app/data/repositories/auth_repository_impl.dart';
import 'package:english_learning_app/domain/entities/user.dart';

import 'auth_repository_test.mocks.dart';

// Generate mocks
@GenerateMocks([
  AuthRemoteDataSource,
  AuthLocalDataSource,
  FirebaseAuthService,
])
void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockFirebaseAuthService mockFirebaseAuthService;

  // Test data
  const tEmail = 'test@example.com';
  const tPassword = 'Password123!';
  const tUsername = 'testuser';
  const tDisplayName = 'Test User';
  const tToken = 'jwt-token-12345';
  const tOAuthToken = 'oauth-token-67890';

  final tUserModel = UserModel(
    id: '123',
    email: tEmail,
    username: tUsername,
    displayName: tDisplayName,
    authProvider: AuthProvider.email,
    createdAt: DateTime(2024, 1, 1),
  );

  final tUser = User(
    id: '123',
    email: tEmail,
    username: tUsername,
    displayName: tDisplayName,
    authProvider: AuthProvider.email,
    createdAt: DateTime(2024, 1, 1),
  );

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    mockFirebaseAuthService = MockFirebaseAuthService();

    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      firebaseAuthService: mockFirebaseAuthService,
    );
  });

  group('register', () {
    test('should return User when registration succeeds', () async {
      // arrange
      when(mockRemoteDataSource.register(
        email: tEmail,
        password: tPassword,
        username: tUsername,
        displayName: tDisplayName,
      )).thenAnswer(
        (_) async => {'user': tUserModel, 'token': tToken},
      );
      when(mockLocalDataSource.saveToken(any)).thenAnswer((_) async => {});
      when(mockLocalDataSource.saveUser(any)).thenAnswer((_) async => {});

      // act
      final result = await repository.register(
        email: tEmail,
        password: tPassword,
        username: tUsername,
        displayName: tDisplayName,
      );

      // assert
      expect(result, isA<Right<Failure, User>>());
      result.fold(
        (failure) => fail('Should return Right'),
        (user) {
          expect(user.id, tUser.id);
          expect(user.email, tUser.email);
          expect(user.username, tUser.username);
        },
      );
      verify(mockLocalDataSource.saveToken(tToken)).called(1);
      verify(mockLocalDataSource.saveUser(tUserModel)).called(1);
    });

    test('should return NetworkFailure when NetworkException is thrown', () async {
      // arrange
      when(mockRemoteDataSource.register(
        email: tEmail,
        password: tPassword,
        username: tUsername,
        displayName: tDisplayName,
      )).thenThrow(const NetworkException(message: 'No internet'));

      // act
      final result = await repository.register(
        email: tEmail,
        password: tPassword,
        username: tUsername,
        displayName: tDisplayName,
      );

      // assert
      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'No internet');
        },
        (_) => fail('Should return Left'),
      );
      verifyNever(mockLocalDataSource.saveToken(any));
      verifyNever(mockLocalDataSource.saveUser(any));
    });

    test('should return ServerFailure when ServerException is thrown', () async {
      // arrange
      when(mockRemoteDataSource.register(
        email: tEmail,
        password: tPassword,
        username: tUsername,
        displayName: tDisplayName,
      )).thenThrow(const ServerException(message: 'Server error'));

      // act
      final result = await repository.register(
        email: tEmail,
        password: tPassword,
        username: tUsername,
        displayName: tDisplayName,
      );

      // assert
      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Server error');
        },
        (_) => fail('Should return Left'),
      );
    });

    test('should return ValidationFailure when ValidationException is thrown', () async {
      // arrange
      when(mockRemoteDataSource.register(
        email: tEmail,
        password: tPassword,
        username: tUsername,
        displayName: tDisplayName,
      )).thenThrow(const ValidationException(message: 'Email already exists'));

      // act
      final result = await repository.register(
        email: tEmail,
        password: tPassword,
        username: tUsername,
        displayName: tDisplayName,
      );

      // assert
      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, 'Email already exists');
        },
        (_) => fail('Should return Left'),
      );
    });

    test('should return StorageFailure when StorageException is thrown', () async {
      // arrange
      when(mockRemoteDataSource.register(
        email: tEmail,
        password: tPassword,
        username: tUsername,
        displayName: tDisplayName,
      )).thenAnswer(
        (_) async => {'user': tUserModel, 'token': tToken},
      );
      when(mockLocalDataSource.saveToken(any))
          .thenThrow(const StorageException(message: 'Storage error'));

      // act
      final result = await repository.register(
        email: tEmail,
        password: tPassword,
        username: tUsername,
        displayName: tDisplayName,
      );

      // assert
      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (failure) {
          expect(failure, isA<StorageFailure>());
          expect(failure.message, 'Storage error');
        },
        (_) => fail('Should return Left'),
      );
    });

    test('should return UnknownFailure when unexpected error occurs', () async {
      // arrange
      when(mockRemoteDataSource.register(
        email: tEmail,
        password: tPassword,
        username: tUsername,
        displayName: tDisplayName,
      )).thenThrow(Exception('Unexpected error'));

      // act
      final result = await repository.register(
        email: tEmail,
        password: tPassword,
        username: tUsername,
        displayName: tDisplayName,
      );

      // assert
      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, contains('Registration failed'));
        },
        (_) => fail('Should return Left'),
      );
    });
  });

  group('login', () {
    test('should return User when login succeeds', () async {
      // arrange
      when(mockRemoteDataSource.login(
        email: tEmail,
        password: tPassword,
      )).thenAnswer(
        (_) async => {'user': tUserModel, 'token': tToken},
      );
      when(mockLocalDataSource.saveToken(any)).thenAnswer((_) async => {});
      when(mockLocalDataSource.saveUser(any)).thenAnswer((_) async => {});

      // act
      final result = await repository.login(
        email: tEmail,
        password: tPassword,
      );

      // assert
      expect(result, isA<Right<Failure, User>>());
      result.fold(
        (_) => fail('Should return Right'),
        (user) {
          expect(user.email, tEmail);
          expect(user.username, tUsername);
        },
      );
      verify(mockLocalDataSource.saveToken(tToken)).called(1);
      verify(mockLocalDataSource.saveUser(tUserModel)).called(1);
    });

    test('should return AuthFailure when AuthException is thrown', () async {
      // arrange
      when(mockRemoteDataSource.login(
        email: tEmail,
        password: tPassword,
      )).thenThrow(const AuthException(message: 'Invalid credentials'));

      // act
      final result = await repository.login(
        email: tEmail,
        password: tPassword,
      );

      // assert
      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, 'Invalid credentials');
        },
        (_) => fail('Should return Left'),
      );
    });

    test('should return NetworkFailure when no connection', () async {
      // arrange
      when(mockRemoteDataSource.login(
        email: tEmail,
        password: tPassword,
      )).thenThrow(const NetworkException(message: 'No internet'));

      // act
      final result = await repository.login(
        email: tEmail,
        password: tPassword,
      );

      // assert
      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
        },
        (_) => fail('Should return Left'),
      );
    });
  });

  group('socialLogin', () {
    final tGoogleUserModel = UserModel(
      id: '456',
      email: 'google@example.com',
      username: 'googleuser',
      displayName: 'Google User',
      authProvider: AuthProvider.google,
      createdAt: DateTime(2024, 1, 1),
    );

    test('should return User when Google login succeeds', () async {
      // arrange
      when(mockFirebaseAuthService.getOAuthToken(AuthProvider.google)).thenAnswer(
        (_) async => {'token': tOAuthToken, 'provider': 'google'},
      );
      when(mockRemoteDataSource.socialLogin(
        provider: 'google',
        token: tOAuthToken,
      )).thenAnswer(
        (_) async => {'user': tGoogleUserModel, 'token': tToken},
      );
      when(mockLocalDataSource.saveToken(any)).thenAnswer((_) async => {});
      when(mockLocalDataSource.saveUser(any)).thenAnswer((_) async => {});

      // act
      final result = await repository.socialLogin(
        provider: AuthProvider.google,
      );

      // assert
      expect(result, isA<Right<Failure, User>>());
      verify(mockFirebaseAuthService.getOAuthToken(AuthProvider.google)).called(1);
      verify(mockRemoteDataSource.socialLogin(
        provider: 'google',
        token: tOAuthToken,
      )).called(1);
      verify(mockLocalDataSource.saveToken(tToken)).called(1);
      verify(mockLocalDataSource.saveUser(tGoogleUserModel)).called(1);
    });

    test('should return User when Apple login succeeds', () async {
      // arrange
      when(mockFirebaseAuthService.getOAuthToken(AuthProvider.apple)).thenAnswer(
        (_) async => {'token': tOAuthToken, 'provider': 'apple'},
      );
      when(mockRemoteDataSource.socialLogin(
        provider: 'apple',
        token: tOAuthToken,
      )).thenAnswer(
        (_) async => {'user': tGoogleUserModel, 'token': tToken},
      );
      when(mockLocalDataSource.saveToken(any)).thenAnswer((_) async => {});
      when(mockLocalDataSource.saveUser(any)).thenAnswer((_) async => {});

      // act
      final result = await repository.socialLogin(
        provider: AuthProvider.apple,
      );

      // assert
      expect(result, isA<Right<Failure, User>>());
      verify(mockFirebaseAuthService.getOAuthToken(AuthProvider.apple)).called(1);
    });

    test('should return AuthFailure when OAuth is cancelled', () async {
      // arrange
      when(mockFirebaseAuthService.getOAuthToken(AuthProvider.google))
          .thenThrow(const AuthException(message: 'User cancelled'));

      // act
      final result = await repository.socialLogin(
        provider: AuthProvider.google,
      );

      // assert
      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, 'User cancelled');
        },
        (_) => fail('Should return Left'),
      );
      verifyNever(mockRemoteDataSource.socialLogin(
        provider: anyNamed('provider'),
        token: anyNamed('token'),
      ));
    });

    test('should return NetworkFailure when social login has network error', () async {
      // arrange
      when(mockFirebaseAuthService.getOAuthToken(AuthProvider.facebook)).thenAnswer(
        (_) async => {'token': tOAuthToken, 'provider': 'facebook'},
      );
      when(mockRemoteDataSource.socialLogin(
        provider: 'facebook',
        token: tOAuthToken,
      )).thenThrow(const NetworkException(message: 'No internet'));

      // act
      final result = await repository.socialLogin(
        provider: AuthProvider.facebook,
      );

      // assert
      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
        },
        (_) => fail('Should return Left'),
      );
    });
  });

  group('logout', () {
    test('should return Unit when logout succeeds', () async {
      // arrange
      when(mockFirebaseAuthService.signOut()).thenAnswer((_) async => {});
      when(mockLocalDataSource.deleteToken()).thenAnswer((_) async => {});
      when(mockLocalDataSource.deleteUser()).thenAnswer((_) async => {});

      // act
      final result = await repository.logout();

      // assert
      expect(result, const Right(unit));
      verify(mockFirebaseAuthService.signOut()).called(1);
      verify(mockLocalDataSource.deleteToken()).called(1);
      verify(mockLocalDataSource.deleteUser()).called(1);
    });

    test('should return AuthFailure when Firebase sign out fails', () async {
      // arrange
      when(mockFirebaseAuthService.signOut())
          .thenThrow(const AuthException(message: 'Sign out failed'));

      // act
      final result = await repository.logout();

      // assert
      expect(result, isA<Left<Failure, Unit>>());
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, 'Sign out failed');
        },
        (_) => fail('Should return Left'),
      );
    });

    test('should return StorageFailure when clearing storage fails', () async {
      // arrange
      when(mockFirebaseAuthService.signOut()).thenAnswer((_) async => {});
      when(mockLocalDataSource.deleteToken())
          .thenThrow(const StorageException(message: 'Storage error'));

      // act
      final result = await repository.logout();

      // assert
      expect(result, isA<Left<Failure, Unit>>());
      result.fold(
        (failure) {
          expect(failure, isA<StorageFailure>());
        },
        (_) => fail('Should return Left'),
      );
    });
  });

  group('getCurrentUser', () {
    test('should return User when authenticated', () async {
      // arrange
      when(mockLocalDataSource.isAuthenticated()).thenAnswer((_) async => true);
      when(mockLocalDataSource.getUser()).thenAnswer((_) async => tUserModel);

      // act
      final result = await repository.getCurrentUser();

      // assert
      expect(result, isA<Right<Failure, User>>());
      result.fold(
        (_) => fail('Should return Right'),
        (user) {
          expect(user.email, tEmail);
          expect(user.username, tUsername);
        },
      );
      verify(mockLocalDataSource.isAuthenticated()).called(1);
      verify(mockLocalDataSource.getUser()).called(1);
    });

    test('should return AuthFailure when not authenticated', () async {
      // arrange
      when(mockLocalDataSource.isAuthenticated()).thenAnswer((_) async => false);

      // act
      final result = await repository.getCurrentUser();

      // assert
      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, 'Not authenticated');
        },
        (_) => fail('Should return Left'),
      );
      verifyNever(mockLocalDataSource.getUser());
    });

    test('should return CacheFailure when CacheException is thrown', () async {
      // arrange
      when(mockLocalDataSource.isAuthenticated()).thenAnswer((_) async => true);
      when(mockLocalDataSource.getUser()).thenThrow(const CacheException(message: 'Cache error'));

      // act
      final result = await repository.getCurrentUser();

      // assert
      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
        },
        (_) => fail('Should return Left'),
      );
    });
  });

  group('isAuthenticated', () {
    test('should return true when user is authenticated', () async {
      // arrange
      when(mockLocalDataSource.isAuthenticated()).thenAnswer((_) async => true);

      // act
      final result = await repository.isAuthenticated();

      // assert
      expect(result, true);
      verify(mockLocalDataSource.isAuthenticated()).called(1);
    });

    test('should return false when user is not authenticated', () async {
      // arrange
      when(mockLocalDataSource.isAuthenticated()).thenAnswer((_) async => false);

      // act
      final result = await repository.isAuthenticated();

      // assert
      expect(result, false);
    });

    test('should return false when exception occurs', () async {
      // arrange
      when(mockLocalDataSource.isAuthenticated()).thenThrow(Exception('Error'));

      // act
      final result = await repository.isAuthenticated();

      // assert
      expect(result, false);
    });
  });

  group('getToken', () {
    test('should return token when it exists', () async {
      // arrange
      when(mockLocalDataSource.getToken()).thenAnswer((_) async => tToken);

      // act
      final result = await repository.getToken();

      // assert
      expect(result, tToken);
      verify(mockLocalDataSource.getToken()).called(1);
    });

    test('should return null when token does not exist', () async {
      // arrange
      when(mockLocalDataSource.getToken()).thenAnswer((_) async => null);

      // act
      final result = await repository.getToken();

      // assert
      expect(result, null);
    });

    test('should return null when exception occurs', () async {
      // arrange
      when(mockLocalDataSource.getToken()).thenThrow(Exception('Error'));

      // act
      final result = await repository.getToken();

      // assert
      expect(result, null);
    });
  });
}
