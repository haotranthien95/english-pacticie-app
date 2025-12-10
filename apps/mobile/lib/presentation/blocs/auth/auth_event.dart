import 'package:equatable/equatable.dart';
import '../../../core/constants/enums.dart';

/// Base class for all AuthBloc events
/// Using imperative naming (command style): LoginRequested, not UserLoggedIn
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Check authentication status on app start
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Event: User requests login with email and password
class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Event: User requests registration
class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String username;
  final String? displayName;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.username,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, username, displayName];
}

/// Event: User requests social login (Google, Apple, Facebook)
class SocialLoginRequested extends AuthEvent {
  final AuthProvider provider;

  const SocialLoginRequested({required this.provider});

  @override
  List<Object?> get props => [provider];
}

/// Event: User requests logout
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
