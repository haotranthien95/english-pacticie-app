import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/user_remote_datasource.dart';

/// Implementation of UserRepository
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final userModel = await remoteDataSource.getProfile();
      return Right(userModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnauthorizedException catch (e) {
      // Clear token on unauthorized
      await localDataSource.deleteToken();
      return Left(UnauthorizedFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to load profile: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    try {
      final userModel = await remoteDataSource.updateProfile(
        name: name,
        avatarUrl: avatarUrl,
      );
      return Right(userModel.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnauthorizedException catch (e) {
      // Clear token on unauthorized
      await localDataSource.deleteToken();
      return Left(UnauthorizedFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update profile: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await remoteDataSource.deleteAccount();

      // Clear local token after successful deletion
      await localDataSource.deleteToken();

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnauthorizedException catch (e) {
      // Clear token anyway
      await localDataSource.deleteToken();
      return Left(UnauthorizedFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete account: $e'));
    }
  }
}
