import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';

/// User entity representing an authenticated user
/// Domain layer - pure business logic without implementation details
class User extends Equatable {
  final String id;
  final String email;
  final String username;
  final String? displayName;
  final AuthProvider authProvider;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    required this.authProvider,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        username,
        displayName,
        authProvider,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'User(id: $id, email: $email, username: $username, displayName: $displayName, authProvider: $authProvider)';
  }

  /// Create a copy with modified fields
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    AuthProvider? authProvider,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
