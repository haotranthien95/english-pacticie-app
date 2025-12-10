import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

/// States for Profile BLoC
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Loading profile
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Profile loaded successfully
class ProfileLoaded extends ProfileState {
  final User user;

  const ProfileLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

/// Updating profile
class ProfileUpdating extends ProfileState {
  final User currentUser;

  const ProfileUpdating(this.currentUser);

  @override
  List<Object?> get props => [currentUser];
}

/// Profile updated successfully
class ProfileUpdated extends ProfileState {
  final User user;

  const ProfileUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Deleting account
class AccountDeleting extends ProfileState {
  const AccountDeleting();
}

/// Account deleted successfully
class AccountDeleted extends ProfileState {
  const AccountDeleted();
}

/// Error occurred
class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
