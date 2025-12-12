import 'package:equatable/equatable.dart';

/// Base failure class for Either pattern (Left value)
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() =>
      'Failure: $message${code != null ? " (code: $code)" : ""}';
}

/// Server/API related failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

/// Network/connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
  });
}

/// Authentication/authorization failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });
}

/// Unauthorized (401) failures - token expired or invalid
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    required super.message,
    super.code = '401',
  });
}

/// Data parsing/serialization failures
class DataFailure extends Failure {
  const DataFailure({
    required super.message,
    super.code,
  });
}

/// Local storage failures
class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.code,
  });
}

/// Audio recording/playback failures
class AudioFailure extends Failure {
  const AudioFailure({
    required super.message,
    super.code,
  });
}

/// Cache related failures
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
  });
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
  });
}

/// Unexpected/unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
  });
}
