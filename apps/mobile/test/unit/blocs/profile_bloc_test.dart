import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:english_learning_app/core/constants/enums.dart';
import 'package:english_learning_app/core/errors/failures.dart';
import 'package:english_learning_app/domain/entities/user.dart';
import 'package:english_learning_app/domain/usecases/user/delete_account_usecase.dart';
import 'package:english_learning_app/domain/usecases/user/get_profile_usecase.dart';
import 'package:english_learning_app/domain/usecases/user/update_profile_usecase.dart';
import 'package:english_learning_app/presentation/blocs/profile/profile_bloc.dart';
import 'package:english_learning_app/presentation/blocs/profile/profile_event.dart';
import 'package:english_learning_app/presentation/blocs/profile/profile_state.dart';

import 'profile_bloc_test.mocks.dart';

// Generate mocks
@GenerateMocks([
  GetProfileUseCase,
  UpdateProfileUseCase,
  DeleteAccountUseCase,
])
void main() {
  late ProfileBloc profileBloc;
  late MockGetProfileUseCase mockGetProfileUseCase;
  late MockUpdateProfileUseCase mockUpdateProfileUseCase;
  late MockDeleteAccountUseCase mockDeleteAccountUseCase;

  // Test data
  final tUser = User(
    id: '123',
    email: 'test@example.com',
    username: 'testuser',
    displayName: 'Test User',
    authProvider: AuthProvider.email,
    createdAt: DateTime(2024, 1, 1),
  );

  final tUpdatedUser = User(
    id: '123',
    email: 'test@example.com',
    username: 'testuser',
    displayName: 'Updated Name',
    authProvider: AuthProvider.email,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 15),
  );

  const tNetworkFailure = NetworkFailure(
    message: 'No internet connection',
    code: 'network/no-connection',
  );

  setUp(() {
    mockGetProfileUseCase = MockGetProfileUseCase();
    mockUpdateProfileUseCase = MockUpdateProfileUseCase();
    mockDeleteAccountUseCase = MockDeleteAccountUseCase();

    profileBloc = ProfileBloc(
      getProfileUseCase: mockGetProfileUseCase,
      updateProfileUseCase: mockUpdateProfileUseCase,
      deleteAccountUseCase: mockDeleteAccountUseCase,
    );
  });

  tearDown(() {
    profileBloc.close();
  });

  group('ProfileBloc', () {
    test('initial state should be ProfileInitial', () {
      expect(profileBloc.state, equals(const ProfileInitial()));
    });

    group('ProfileLoadRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileLoaded] when profile loads successfully',
        build: () {
          when(mockGetProfileUseCase()).thenAnswer((_) async => Right(tUser));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ProfileLoadRequested()),
        expect: () => [
          const ProfileLoading(),
          ProfileLoaded(tUser),
        ],
        verify: (_) {
          verify(mockGetProfileUseCase()).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileError] when loading fails',
        build: () {
          when(mockGetProfileUseCase())
              .thenAnswer((_) async => const Left(tNetworkFailure));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ProfileLoadRequested()),
        expect: () => [
          const ProfileLoading(),
          const ProfileError('No internet connection'),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileError] when user not found',
        build: () {
          when(mockGetProfileUseCase()).thenAnswer(
            (_) async => const Left(
              AuthFailure(message: 'User not found', code: 'auth/not-found'),
            ),
          );
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ProfileLoadRequested()),
        expect: () => [
          const ProfileLoading(),
          const ProfileError('User not found'),
        ],
      );
    });

    group('ProfileUpdateRequested', () {
      const tNewName = 'Updated Name';
      const tNewAvatarUrl = 'https://example.com/avatar.jpg';

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileUpdating, ProfileUpdated] when update succeeds',
        build: () {
          when(mockUpdateProfileUseCase(any))
              .thenAnswer((_) async => Right(tUpdatedUser));
          return profileBloc;
        },
        seed: () => ProfileLoaded(tUser),
        act: (bloc) => bloc.add(
          const ProfileUpdateRequested(name: tNewName),
        ),
        expect: () => [
          ProfileUpdating(tUser),
          ProfileUpdated(tUpdatedUser),
        ],
        verify: (_) {
          final captured =
              verify(mockUpdateProfileUseCase(captureAny)).captured;
          expect(captured.length, 1);
          final params = captured[0] as UpdateProfileParams;
          expect(params.name, tNewName);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'updates avatar URL successfully',
        build: () {
          when(mockUpdateProfileUseCase(any))
              .thenAnswer((_) async => Right(tUpdatedUser));
          return profileBloc;
        },
        seed: () => ProfileLoaded(tUser),
        act: (bloc) => bloc.add(
          const ProfileUpdateRequested(avatarUrl: tNewAvatarUrl),
        ),
        expect: () => [
          ProfileUpdating(tUser),
          ProfileUpdated(tUpdatedUser),
        ],
        verify: (_) {
          final captured =
              verify(mockUpdateProfileUseCase(captureAny)).captured;
          final params = captured[0] as UpdateProfileParams;
          expect(params.avatarUrl, tNewAvatarUrl);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'updates both name and avatar URL',
        build: () {
          when(mockUpdateProfileUseCase(any))
              .thenAnswer((_) async => Right(tUpdatedUser));
          return profileBloc;
        },
        seed: () => ProfileLoaded(tUser),
        act: (bloc) => bloc.add(
          const ProfileUpdateRequested(
            name: tNewName,
            avatarUrl: tNewAvatarUrl,
          ),
        ),
        expect: () => [
          ProfileUpdating(tUser),
          ProfileUpdated(tUpdatedUser),
        ],
        verify: (_) {
          final captured =
              verify(mockUpdateProfileUseCase(captureAny)).captured;
          final params = captured[0] as UpdateProfileParams;
          expect(params.name, tNewName);
          expect(params.avatarUrl, tNewAvatarUrl);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileUpdating, ProfileError, ProfileLoaded] when update fails',
        build: () {
          when(mockUpdateProfileUseCase(any))
              .thenAnswer((_) async => const Left(tNetworkFailure));
          return profileBloc;
        },
        seed: () => ProfileLoaded(tUser),
        act: (bloc) => bloc.add(
          const ProfileUpdateRequested(name: tNewName),
        ),
        expect: () => [
          ProfileUpdating(tUser),
          const ProfileError('No internet connection'),
          ProfileLoaded(tUser), // Returns to previous state
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'ignores update when not in ProfileLoaded state',
        build: () => profileBloc,
        seed: () => const ProfileInitial(),
        act: (bloc) => bloc.add(
          const ProfileUpdateRequested(name: tNewName),
        ),
        expect: () => [],
        verify: (_) {
          verifyNever(mockUpdateProfileUseCase(any));
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'handles validation error',
        build: () {
          when(mockUpdateProfileUseCase(any)).thenAnswer(
            (_) async => const Left(
              ValidationFailure(message: 'Name is too short'),
            ),
          );
          return profileBloc;
        },
        seed: () => ProfileLoaded(tUser),
        act: (bloc) => bloc.add(const ProfileUpdateRequested(name: 'A')),
        expect: () => [
          ProfileUpdating(tUser),
          const ProfileError('Name is too short'),
          ProfileLoaded(tUser),
        ],
      );
    });

    group('AccountDeleteRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [AccountDeleting, AccountDeleted] when deletion succeeds',
        build: () {
          when(mockDeleteAccountUseCase())
              .thenAnswer((_) async => const Right(unit));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const AccountDeleteRequested()),
        expect: () => [
          const AccountDeleting(),
          const AccountDeleted(),
        ],
        verify: (_) {
          verify(mockDeleteAccountUseCase()).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [AccountDeleting, ProfileError] when deletion fails',
        build: () {
          when(mockDeleteAccountUseCase())
              .thenAnswer((_) async => const Left(tNetworkFailure));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const AccountDeleteRequested()),
        expect: () => [
          const AccountDeleting(),
          const ProfileError('No internet connection'),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'handles authentication error during deletion',
        build: () {
          when(mockDeleteAccountUseCase()).thenAnswer(
            (_) async => const Left(
              AuthFailure(
                message: 'Authentication required',
                code: 'auth/required',
              ),
            ),
          );
          return profileBloc;
        },
        act: (bloc) => bloc.add(const AccountDeleteRequested()),
        expect: () => [
          const AccountDeleting(),
          const ProfileError('Authentication required'),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'handles server error during deletion',
        build: () {
          when(mockDeleteAccountUseCase()).thenAnswer(
            (_) async => const Left(
              ServerFailure(message: 'Server error', code: 'server/error'),
            ),
          );
          return profileBloc;
        },
        act: (bloc) => bloc.add(const AccountDeleteRequested()),
        expect: () => [
          const AccountDeleting(),
          const ProfileError('Server error'),
        ],
      );
    });

    group('State transitions', () {
      blocTest<ProfileBloc, ProfileState>(
        'handles load followed by update',
        build: () {
          when(mockGetProfileUseCase()).thenAnswer((_) async => Right(tUser));
          when(mockUpdateProfileUseCase(any))
              .thenAnswer((_) async => Right(tUpdatedUser));
          return profileBloc;
        },
        act: (bloc) async {
          bloc.add(const ProfileLoadRequested());
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const ProfileUpdateRequested(name: 'Updated Name'));
        },
        expect: () => [
          const ProfileLoading(),
          ProfileLoaded(tUser),
          ProfileUpdating(tUser),
          ProfileUpdated(tUpdatedUser),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'handles multiple update requests',
        build: () {
          when(mockUpdateProfileUseCase(any))
              .thenAnswer((_) async => Right(tUpdatedUser));
          return profileBloc;
        },
        seed: () => ProfileLoaded(tUser),
        act: (bloc) async {
          bloc.add(const ProfileUpdateRequested(name: 'Name 1'));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const ProfileUpdateRequested(name: 'Name 2'));
        },
        verify: (_) {
          verify(mockUpdateProfileUseCase(any)).called(2);
        },
      );
    });

    group('Edge cases', () {
      blocTest<ProfileBloc, ProfileState>(
        'handles empty name update',
        build: () {
          when(mockUpdateProfileUseCase(any))
              .thenAnswer((_) async => Right(tUser));
          return profileBloc;
        },
        seed: () => ProfileLoaded(tUser),
        act: (bloc) => bloc.add(const ProfileUpdateRequested(name: '')),
        expect: () => [
          ProfileUpdating(tUser),
          ProfileUpdated(tUser),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'handles null values in update',
        build: () {
          when(mockUpdateProfileUseCase(any))
              .thenAnswer((_) async => Right(tUser));
          return profileBloc;
        },
        seed: () => ProfileLoaded(tUser),
        act: (bloc) => bloc.add(const ProfileUpdateRequested()),
        expect: () => [
          ProfileUpdating(tUser),
          ProfileUpdated(tUser),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'handles rapid load requests',
        build: () {
          when(mockGetProfileUseCase()).thenAnswer((_) async => Right(tUser));
          return profileBloc;
        },
        act: (bloc) {
          bloc.add(const ProfileLoadRequested());
          bloc.add(const ProfileLoadRequested());
          bloc.add(const ProfileLoadRequested());
        },
        verify: (_) {
          verify(mockGetProfileUseCase()).called(greaterThan(0));
        },
      );
    });
  });
}
