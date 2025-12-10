import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

/// Base class for all AuthBloc states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before authentication check
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State: Checking authentication status
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State: User is authenticated
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// State: User is not authenticated
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// State: Authentication error occurred
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
