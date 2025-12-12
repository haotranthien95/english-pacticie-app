import '../../core/constants/enums.dart';
import '../../domain/entities/user.dart';

/// User model for data layer with JSON serialization
/// Extends User entity and adds fromJson/toJson capabilities
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.username,
    super.displayName,
    required super.authProvider,
    required super.createdAt,
    super.updatedAt,
  });

  /// Create UserModel from JSON response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      authProvider:
          AuthProviderExtension.fromValue(json['auth_provider'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert UserModel to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'auth_provider': authProvider.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create UserModel from User entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      username: user.username,
      displayName: user.displayName,
      authProvider: user.authProvider,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  /// Convert to User entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      username: username,
      displayName: displayName,
      authProvider: authProvider,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    AuthProvider? authProvider,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
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
