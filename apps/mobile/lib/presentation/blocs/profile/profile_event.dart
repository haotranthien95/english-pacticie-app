import 'package:equatable/equatable.dart';

/// Events for Profile BLoC
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load user profile
class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
}

/// Event to update user profile
class ProfileUpdateRequested extends ProfileEvent {
  final String? name;
  final String? avatarUrl;

  const ProfileUpdateRequested({
    this.name,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [name, avatarUrl];
}

/// Event to delete user account
class AccountDeleteRequested extends ProfileEvent {
  const AccountDeleteRequested();
}
