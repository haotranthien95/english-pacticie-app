import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:english_learning_app/core/errors/exceptions.dart';
import 'package:english_learning_app/core/errors/failures.dart';
import 'package:english_learning_app/data/datasources/local/auth_local_datasource.dart';
import 'package:english_learning_app/data/datasources/remote/user_remote_datasource.dart';
import 'package:english_learning_app/data/models/user_model.dart';
import 'package:english_learning_app/data/repositories/user_repository_impl.dart';

import 'user_repository_test.mocks.dart';

@GenerateMocks([
  UserRemoteDataSource,
  AuthLocalDataSource,
])
void main() {
  late UserRepositoryImpl repository;
  late MockUserRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockUserRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    repository = UserRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('UserRepository - getProfile', () {
    final mockUserModel = UserModel(
      id: 'user-1',
      email: 'test@example.com',
      username: 'testuser',
      displayName: 'Test User',
      avatarUrl: 'https://example.com/avatar.jpg',
      createdAt: DateTime.now(),
    );

    test('should return user profile on success', () async {
      // Arrange
      when(mockRemoteDataSource.getProfile()).thenAnswer(
        (_) async => mockUserModel,
      );

      // Act
      final result = await repository.getProfile();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return user'),
        (user) {
          expect(user.id, equals('user-1'));
          expect(user.email, equals('test@example.com'));
          expect(user.username, equals('testuser'));
          expect(user.displayName, equals('Test User'));
        },
      );
      verify(mockRemoteDataSource.getProfile()).called(1);
    });

    test('should return ServerFailure on ServerException', () async {
      // Arrange
      when(mockRemoteDataSource.getProfile()).thenThrow(
        ServerException(message: 'Server error'),
      );

      // Act
      final result = await repository.getProfile();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('Server error'));
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should return NetworkFailure on NetworkException', () async {
      // Arrange
      when(mockRemoteDataSource.getProfile()).thenThrow(
        NetworkException(message: 'No internet connection'),
      );

      // Act
      final result = await repository.getProfile();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, contains('No internet connection'));
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should clear token and return UnauthorizedFailure on UnauthorizedException', () async {
      // Arrange
      when(mockRemoteDataSource.getProfile()).thenThrow(
        UnauthorizedException(message: 'Unauthorized'),
      );
      when(mockLocalDataSource.clearToken()).thenAnswer((_) async => {});

      // Act
      final result = await repository.getProfile();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<UnauthorizedFailure>());
          expect(failure.message, contains('Unauthorized'));
        },
        (_) => fail('Should return failure'),
      );
      verify(mockLocalDataSource.clearToken()).called(1);
    });

    test('should return ServerFailure on unexpected error', () async {
      // Arrange
      when(mockRemoteDataSource.getProfile()).thenThrow(
        Exception('Unexpected error'),
      );

      // Act
      final result = await repository.getProfile();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('Failed to load profile'));
        },
        (_) => fail('Should return failure'),
      );
    });
  });

  group('UserRepository - updateProfile', () {
    final mockUserModel = UserModel(
      id: 'user-1',
      email: 'test@example.com',
      username: 'testuser',
      displayName: 'Updated Name',
      avatarUrl: 'https://example.com/new-avatar.jpg',
      createdAt: DateTime.now(),
    );

    test('should update profile with name only', () async {
      // Arrange
      when(mockRemoteDataSource.updateProfile(
        name: anyNamed('name'),
        avatarUrl: anyNamed('avatarUrl'),
      )).thenAnswer((_) async => mockUserModel);

      // Act
      final result = await repository.updateProfile(name: 'Updated Name');

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return user'),
        (user) => expect(user.displayName, equals('Updated Name')),
      );
      verify(mockRemoteDataSource.updateProfile(
        name: 'Updated Name',
        avatarUrl: null,
      )).called(1);
    });

    test('should update profile with avatarUrl only', () async {
      // Arrange
      when(mockRemoteDataSource.updateProfile(
        name: anyNamed('name'),
        avatarUrl: anyNamed('avatarUrl'),
      )).thenAnswer((_) async => mockUserModel);

      // Act
      final result = await repository.updateProfile(
        avatarUrl: 'https://example.com/new-avatar.jpg',
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return user'),
        (user) => expect(
          user.avatarUrl,
          equals('https://example.com/new-avatar.jpg'),
        ),
      );
      verify(mockRemoteDataSource.updateProfile(
        name: null,
        avatarUrl: 'https://example.com/new-avatar.jpg',
      )).called(1);
    });

    test('should update profile with both name and avatarUrl', () async {
      // Arrange
      when(mockRemoteDataSource.updateProfile(
        name: anyNamed('name'),
        avatarUrl: anyNamed('avatarUrl'),
      )).thenAnswer((_) async => mockUserModel);

      // Act
      final result = await repository.updateProfile(
        name: 'Updated Name',
        avatarUrl: 'https://example.com/new-avatar.jpg',
      );

      // Assert
      expect(result.isRight(), true);
      verify(mockRemoteDataSource.updateProfile(
        name: 'Updated Name',
        avatarUrl: 'https://example.com/new-avatar.jpg',
      )).called(1);
    });

    test('should return ValidationFailure on ValidationException', () async {
      // Arrange
      when(mockRemoteDataSource.updateProfile(
        name: anyNamed('name'),
        avatarUrl: anyNamed('avatarUrl'),
      )).thenThrow(ValidationException(message: 'Name is required'));

      // Act
      final result = await repository.updateProfile(name: '');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Name is required'));
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should return ServerFailure on ServerException', () async {
      // Arrange
      when(mockRemoteDataSource.updateProfile(
        name: anyNamed('name'),
        avatarUrl: anyNamed('avatarUrl'),
      )).thenThrow(ServerException(message: 'Server error'));

      // Act
      final result = await repository.updateProfile(name: 'Updated Name');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('Server error'));
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should return NetworkFailure on NetworkException', () async {
      // Arrange
      when(mockRemoteDataSource.updateProfile(
        name: anyNamed('name'),
        avatarUrl: anyNamed('avatarUrl'),
      )).thenThrow(NetworkException(message: 'No internet connection'));

      // Act
      final result = await repository.updateProfile(name: 'Updated Name');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, contains('No internet connection'));
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should clear token and return UnauthorizedFailure on UnauthorizedException', () async {
      // Arrange
      when(mockRemoteDataSource.updateProfile(
        name: anyNamed('name'),
        avatarUrl: anyNamed('avatarUrl'),
      )).thenThrow(UnauthorizedException(message: 'Unauthorized'));
      when(mockLocalDataSource.clearToken()).thenAnswer((_) async => {});

      // Act
      final result = await repository.updateProfile(name: 'Updated Name');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<UnauthorizedFailure>());
          expect(failure.message, contains('Unauthorized'));
        },
        (_) => fail('Should return failure'),
      );
      verify(mockLocalDataSource.clearToken()).called(1);
    });

    test('should return ServerFailure on unexpected error', () async {
      // Arrange
      when(mockRemoteDataSource.updateProfile(
        name: anyNamed('name'),
        avatarUrl: anyNamed('avatarUrl'),
      )).thenThrow(Exception('Unexpected error'));

      // Act
      final result = await repository.updateProfile(name: 'Updated Name');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('Failed to update profile'));
        },
        (_) => fail('Should return failure'),
      );
    });
  });

  group('UserRepository - deleteAccount', () {
    test('should delete account and clear token on success', () async {
      // Arrange
      when(mockRemoteDataSource.deleteAccount()).thenAnswer((_) async => {});
      when(mockLocalDataSource.clearToken()).thenAnswer((_) async => {});

      // Act
      final result = await repository.deleteAccount();

      // Assert
      expect(result.isRight(), true);
      verify(mockRemoteDataSource.deleteAccount()).called(1);
      verify(mockLocalDataSource.clearToken()).called(1);
    });

    test('should clear token after successful deletion', () async {
      // Arrange
      when(mockRemoteDataSource.deleteAccount()).thenAnswer((_) async => {});
      when(mockLocalDataSource.clearToken()).thenAnswer((_) async => {});

      // Act
      await repository.deleteAccount();

      // Assert
      verifyInOrder([
        mockRemoteDataSource.deleteAccount(),
        mockLocalDataSource.clearToken(),
      ]);
    });

    test('should return ServerFailure on ServerException', () async {
      // Arrange
      when(mockRemoteDataSource.deleteAccount()).thenThrow(
        ServerException(message: 'Server error'),
      );

      // Act
      final result = await repository.deleteAccount();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('Server error'));
        },
        (_) => fail('Should return failure'),
      );
      verifyNever(mockLocalDataSource.clearToken());
    });

    test('should return NetworkFailure on NetworkException', () async {
      // Arrange
      when(mockRemoteDataSource.deleteAccount()).thenThrow(
        NetworkException(message: 'No internet connection'),
      );

      // Act
      final result = await repository.deleteAccount();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, contains('No internet connection'));
        },
        (_) => fail('Should return failure'),
      );
      verifyNever(mockLocalDataSource.clearToken());
    });

    test('should clear token even on UnauthorizedException', () async {
      // Arrange
      when(mockRemoteDataSource.deleteAccount()).thenThrow(
        UnauthorizedException(message: 'Unauthorized'),
      );
      when(mockLocalDataSource.clearToken()).thenAnswer((_) async => {});

      // Act
      final result = await repository.deleteAccount();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<UnauthorizedFailure>());
          expect(failure.message, contains('Unauthorized'));
        },
        (_) => fail('Should return failure'),
      );
      verify(mockLocalDataSource.clearToken()).called(1);
    });

    test('should return ServerFailure on unexpected error', () async {
      // Arrange
      when(mockRemoteDataSource.deleteAccount()).thenThrow(
        Exception('Unexpected error'),
      );

      // Act
      final result = await repository.deleteAccount();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('Failed to delete account'));
        },
        (_) => fail('Should return failure'),
      );
      verifyNever(mockLocalDataSource.clearToken());
    });
  });
}
