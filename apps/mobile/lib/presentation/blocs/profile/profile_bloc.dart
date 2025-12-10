import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/user/delete_account_usecase.dart';
import '../../../domain/usecases/user/get_profile_usecase.dart';
import '../../../domain/usecases/user/update_profile_usecase.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// BLoC for managing user profile
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final DeleteAccountUseCase deleteAccountUseCase;

  ProfileBloc({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    required this.deleteAccountUseCase,
  }) : super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<AccountDeleteRequested>(_onAccountDeleteRequested);
  }

  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await getProfileUseCase();

    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (user) => emit(ProfileLoaded(user)),
    );
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded) {
      final currentUser = (state as ProfileLoaded).user;
      emit(ProfileUpdating(currentUser));

      final result = await updateProfileUseCase(
        UpdateProfileParams(
          name: event.name,
          avatarUrl: event.avatarUrl,
        ),
      );

      result.fold(
        (failure) {
          emit(ProfileError(failure.message));
          // Return to loaded state with current user
          emit(ProfileLoaded(currentUser));
        },
        (user) => emit(ProfileUpdated(user)),
      );
    }
  }

  Future<void> _onAccountDeleteRequested(
    AccountDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const AccountDeleting());

    final result = await deleteAccountUseCase();

    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (_) => emit(const AccountDeleted()),
    );
  }
}
