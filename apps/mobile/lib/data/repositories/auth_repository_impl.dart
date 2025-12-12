import 'package:dartz/dartz.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../datasources/remote/firebase_auth_service.dart';
import '../models/user_model.dart';

/// Implementation of AuthRepository
/// Combines local and remote data sources with Either error handling
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final FirebaseAuthService firebaseAuthService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.firebaseAuthService,
  });

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    try {
      // Call backend API
      final result = await remoteDataSource.register(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
      );

      // Extract user and token
      final user = result['user'] as UserModel;
      final token = result['token'] as String;

      // Save to local storage
      await localDataSource.saveToken(token);
      await localDataSource.saveUser(user);

      return Right(user);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Registration failed: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Call backend API
      final result = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Extract user and token
      final user = result['user'] as UserModel;
      final token = result['token'] as String;

      // Save to local storage
      await localDataSource.saveToken(token);
      await localDataSource.saveUser(user);

      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Login failed: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> socialLogin({
    required AuthProvider provider,
  }) async {
    try {
      // Step 1: Get OAuth token from Firebase
      final oAuthData = await firebaseAuthService.getOAuthToken(provider);
      final oAuthToken = oAuthData['token']!;
      final providerValue = oAuthData['provider']!;

      // Step 2: Exchange OAuth token for backend JWT
      final result = await remoteDataSource.socialLogin(
        provider: providerValue,
        token: oAuthToken,
      );

      // Extract user and token
      final user = result['user'] as UserModel;
      final token = result['token'] as String;

      // Save to local storage
      await localDataSource.saveToken(token);
      await localDataSource.saveUser(user);

      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Social login failed: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      // Sign out from Firebase
      await firebaseAuthService.signOut();

      // Clear local storage
      await localDataSource.deleteToken();
      await localDataSource.deleteUser();

      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Logout failed: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      // Check if user is authenticated
      final isAuth = await isAuthenticated();
      if (!isAuth) {
        return const Left(AuthFailure(message: 'Not authenticated'));
      }

      // Get user from local storage
      final user = await localDataSource.getUser();
      return Right(user);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to get user: $e'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await localDataSource.isAuthenticated();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await localDataSource.getToken();
    } catch (e) {
      return null;
    }
  }
}
