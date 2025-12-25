import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:english_learning_app/core/constants/enums.dart';
import 'package:english_learning_app/core/errors/exceptions.dart';
import 'package:english_learning_app/core/errors/failures.dart';
import 'package:english_learning_app/data/datasources/local/game_local_datasource.dart';
import 'package:english_learning_app/data/datasources/remote/game_remote_datasource.dart';
import 'package:english_learning_app/data/models/game_session_model.dart';
import 'package:english_learning_app/data/models/speech_model.dart';
import 'package:english_learning_app/data/models/tag_model.dart';
import 'package:english_learning_app/data/repositories/game_repository_impl.dart';

import 'game_repository_test.mocks.dart';

@GenerateMocks([
  GameLocalDataSource,
  GameRemoteDataSource,
  Connectivity,
])
void main() {
  late GameRepositoryImpl repository;
  late MockGameLocalDataSource mockLocalDataSource;
  late MockGameRemoteDataSource mockRemoteDataSource;
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockLocalDataSource = MockGameLocalDataSource();
    mockRemoteDataSource = MockGameRemoteDataSource();
    mockConnectivity = MockConnectivity();
    repository = GameRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      connectivity: mockConnectivity,
    );
  });

  group('GameRepository - getTags', () {
    final mockTags = [
      const TagModel(id: '1', name: 'Technology'),
      const TagModel(id: '2', name: 'Business'),
    ];

    test('should return tags from remote when connected', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockRemoteDataSource.getTags()).thenAnswer(
        (_) async => mockTags,
      );
      when(mockLocalDataSource.cacheTags(any)).thenAnswer((_) async => {});

      // Act
      final result = await repository.getTags();

      // Assert
      expect(result, equals(Right(mockTags)));
      verify(mockRemoteDataSource.getTags()).called(1);
      verify(mockLocalDataSource.cacheTags(mockTags)).called(1);
    });

    test('should cache tags after fetching from remote', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockRemoteDataSource.getTags()).thenAnswer(
        (_) async => mockTags,
      );
      when(mockLocalDataSource.cacheTags(any)).thenAnswer((_) async => {});

      // Act
      await repository.getTags();

      // Assert
      verify(mockLocalDataSource.cacheTags(mockTags)).called(1);
    });

    test('should return cached tags when offline', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.none],
      );
      when(mockLocalDataSource.getCachedTags()).thenAnswer(
        (_) async => mockTags,
      );

      // Act
      final result = await repository.getTags();

      // Assert
      expect(result, equals(Right(mockTags)));
      verify(mockLocalDataSource.getCachedTags()).called(1);
      verifyNever(mockRemoteDataSource.getTags());
    });

    test('should return NetworkFailure when offline and no cached tags', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.none],
      );
      when(mockLocalDataSource.getCachedTags()).thenAnswer(
        (_) async => [],
      );

      // Act
      final result = await repository.getTags();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return cached tags on NetworkException', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockRemoteDataSource.getTags()).thenThrow(
        NetworkException(message: 'Connection timeout'),
      );
      when(mockLocalDataSource.getCachedTags()).thenAnswer(
        (_) async => mockTags,
      );

      // Act
      final result = await repository.getTags();

      // Assert
      expect(result, equals(Right(mockTags)));
      verify(mockLocalDataSource.getCachedTags()).called(1);
    });

    test('should return NetworkFailure on NetworkException with no cache', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockRemoteDataSource.getTags()).thenThrow(
        NetworkException(message: 'Connection timeout'),
      );
      when(mockLocalDataSource.getCachedTags()).thenAnswer(
        (_) async => [],
      );

      // Act
      final result = await repository.getTags();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return ServerFailure on ServerException', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockRemoteDataSource.getTags()).thenThrow(
        ServerException(message: 'Server error'),
      );

      // Act
      final result = await repository.getTags();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return StorageFailure on StorageException', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockRemoteDataSource.getTags()).thenThrow(
        StorageException(message: 'Storage error'),
      );

      // Act
      final result = await repository.getTags();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<StorageFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return UnknownFailure on unexpected error', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockRemoteDataSource.getTags()).thenThrow(
        Exception('Unexpected error'),
      );

      // Act
      final result = await repository.getTags();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('GameRepository - getRandomSpeeches', () {
    final mockSpeeches = [
      SpeechModel(
        id: '1',
        text: 'Hello World',
        level: SpeechLevel.beginner,
        type: SpeechType.word,
        audioUrl: 'https://example.com/audio1.mp3',
        tagIds: [],
        createdAt: DateTime(2024, 1, 1),
      ),
      SpeechModel(
        id: '2',
        text: 'Good morning',
        level: SpeechLevel.beginner,
        type: SpeechType.phrase,
        audioUrl: 'https://example.com/audio2.mp3',
        tagIds: [],
        createdAt: DateTime(2024, 1, 1),
      ),
    ];

    test('should return speeches from remote when connected', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockRemoteDataSource.getRandomSpeeches(
        level: anyNamed('level'),
        type: anyNamed('type'),
        tagIds: anyNamed('tagIds'),
        count: anyNamed('count'),
      )).thenAnswer((_) async => mockSpeeches);
      when(mockLocalDataSource.cacheSpeeches(any)).thenAnswer((_) async => {});

      // Act
      final result = await repository.getRandomSpeeches(
        level: SpeechLevel.beginner,
        type: SpeechType.word,
        count: 10,
      );

      // Assert
      expect(result, equals(Right(mockSpeeches)));
      verify(mockRemoteDataSource.getRandomSpeeches(
        level: SpeechLevel.beginner,
        type: SpeechType.word,
        tagIds: null,
        count: 10,
      )).called(1);
      verify(mockLocalDataSource.cacheSpeeches(mockSpeeches)).called(1);
    });

    test('should pass tagIds to remote datasource', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockRemoteDataSource.getRandomSpeeches(
        level: anyNamed('level'),
        type: anyNamed('type'),
        tagIds: anyNamed('tagIds'),
        count: anyNamed('count'),
      )).thenAnswer((_) async => mockSpeeches);
      when(mockLocalDataSource.cacheSpeeches(any)).thenAnswer((_) async => {});

      // Act
      await repository.getRandomSpeeches(
        level: SpeechLevel.intermediate,
        type: SpeechType.phrase,
        tagIds: ['tag1', 'tag2'],
        count: 5,
      );

      // Assert
      verify(mockRemoteDataSource.getRandomSpeeches(
        level: SpeechLevel.intermediate,
        type: SpeechType.phrase,
        tagIds: ['tag1', 'tag2'],
        count: 5,
      )).called(1);
    });

    test('should return cached speeches when offline', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.none],
      );
      when(mockLocalDataSource.getCachedSpeeches(
        level: anyNamed('level'),
        type: anyNamed('type'),
        tagIds: anyNamed('tagIds'),
      )).thenAnswer((_) async => mockSpeeches);

      // Act
      final result = await repository.getRandomSpeeches(
        level: SpeechLevel.beginner,
        type: SpeechType.word,
        count: 10,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return speeches'),
        (speeches) => expect(speeches.length, lessThanOrEqualTo(10)),
      );
      verifyNever(mockRemoteDataSource.getRandomSpeeches(
        level: anyNamed('level'),
        type: anyNamed('type'),
        tagIds: anyNamed('tagIds'),
        count: anyNamed('count'),
      ));
    });

    test('should shuffle and limit cached speeches', () async {
      // Arrange
      final manySpeeches = List.generate(
        20,
        (i) => SpeechModel(
          id: '$i',
          text: 'Speech $i',
          level: SpeechLevel.beginner,
          type: SpeechType.sentence,
          audioUrl: 'https://example.com/audio$i.mp3',
          tagIds: const [],
          createdAt: DateTime(2024, 1, 1),
        ),
      );
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.none],
      );
      when(mockLocalDataSource.getCachedSpeeches(
        level: anyNamed('level'),
        type: anyNamed('type'),
        tagIds: anyNamed('tagIds'),
      )).thenAnswer((_) async => manySpeeches);

      // Act
      final result = await repository.getRandomSpeeches(
        level: SpeechLevel.beginner,
        type: SpeechType.sentence,
        count: 5,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return speeches'),
        (speeches) => expect(speeches.length, equals(5)),
      );
    });

    test('should return NetworkFailure when offline and no cached speeches', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.none],
      );
      when(mockLocalDataSource.getCachedSpeeches(
        level: anyNamed('level'),
        type: anyNamed('type'),
        tagIds: anyNamed('tagIds'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await repository.getRandomSpeeches(
        level: SpeechLevel.beginner,
        type: SpeechType.word,
        count: 10,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return cached speeches on NetworkException', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockRemoteDataSource.getRandomSpeeches(
        level: anyNamed('level'),
        type: anyNamed('type'),
        tagIds: anyNamed('tagIds'),
        count: anyNamed('count'),
      )).thenThrow(NetworkException(message: 'Connection timeout'));
      when(mockLocalDataSource.getCachedSpeeches(
        level: anyNamed('level'),
        type: anyNamed('type'),
        tagIds: anyNamed('tagIds'),
      )).thenAnswer((_) async => mockSpeeches);

      // Act
      final result = await repository.getRandomSpeeches(
        level: SpeechLevel.beginner,
        type: SpeechType.word,
        count: 10,
      );

      // Assert
      expect(result.isRight(), true);
    });

    test('should return ServerFailure on ServerException', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockRemoteDataSource.getRandomSpeeches(
        level: anyNamed('level'),
        type: anyNamed('type'),
        tagIds: anyNamed('tagIds'),
        count: anyNamed('count'),
      )).thenThrow(ServerException(message: 'Server error'));

      // Act
      final result = await repository.getRandomSpeeches(
        level: SpeechLevel.beginner,
        type: SpeechType.word,
        count: 10,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return ValidationFailure on ValidationException', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockRemoteDataSource.getRandomSpeeches(
        level: anyNamed('level'),
        type: anyNamed('type'),
        tagIds: anyNamed('tagIds'),
        count: anyNamed('count'),
      )).thenThrow(ValidationException(message: 'Invalid count'));

      // Act
      final result = await repository.getRandomSpeeches(
        level: SpeechLevel.beginner,
        type: SpeechType.word,
        count: -1,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('GameRepository - createSession', () {
    final mockSession = GameSessionModel(
      id: 'session-1',
      userId: 'user-1',
      mode: GameMode.listenOnly,
      level: SpeechLevel.beginner,
      type: SpeechType.word,
      tagIds: const [],
      results: const [],
      totalSpeeches: 10,
      correctCount: 8,
      incorrectCount: 2,
      averageScore: 80.0,
      streakCount: 5,
      startedAt: DateTime(2024, 1, 1),
      completedAt: DateTime(2024, 1, 1, 0, 5),
      syncStatus: SyncStatus.pending,
    );

    test('should save session locally and sync when connected', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockLocalDataSource.saveSession(any)).thenAnswer(
        (_) async => mockSession,
      );
      when(mockRemoteDataSource.createSession(any)).thenAnswer(
        (_) async => 'remote-id',
      );
      when(mockLocalDataSource.updateSessionSyncStatus(any, any)).thenAnswer(
        (_) async => {},
      );

      // Act
      final result = await repository.createSession(mockSession);

      // Assert
      expect(result.isRight(), true);
      verify(mockLocalDataSource.saveSession(any)).called(1);
      verify(mockRemoteDataSource.createSession(mockSession)).called(1);
      verify(mockLocalDataSource.updateSessionSyncStatus(
        mockSession.id,
        SyncStatus.synced,
      )).called(1);
    });

    test('should save locally with pending status if sync fails', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockLocalDataSource.saveSession(any)).thenAnswer(
        (_) async => mockSession,
      );
      when(mockRemoteDataSource.createSession(any)).thenThrow(
        ServerException(message: 'Sync failed'),
      );

      // Act
      final result = await repository.createSession(mockSession);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return session'),
        (session) => expect(session.syncStatus, equals(SyncStatus.pending)),
      );
      verify(mockLocalDataSource.saveSession(any)).called(1);
      verifyNever(mockLocalDataSource.updateSessionSyncStatus(any, any));
    });

    test('should save locally when offline', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.none],
      );
      when(mockLocalDataSource.saveSession(any)).thenAnswer(
        (_) async => mockSession,
      );

      // Act
      final result = await repository.createSession(mockSession);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return session'),
        (session) => expect(session.syncStatus, equals(SyncStatus.pending)),
      );
      verify(mockLocalDataSource.saveSession(any)).called(1);
      verifyNever(mockRemoteDataSource.createSession(any));
    });

    test('should return StorageFailure on StorageException', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockLocalDataSource.saveSession(any)).thenThrow(
        StorageException(message: 'Storage error'),
      );

      // Act
      final result = await repository.createSession(mockSession);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<StorageFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return UnknownFailure on unexpected error', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockLocalDataSource.saveSession(any)).thenThrow(
        Exception('Unexpected error'),
      );

      // Act
      final result = await repository.createSession(mockSession);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('GameRepository - syncPendingSessions', () {
    final pendingSessions = [
      GameSessionModel(
        id: 'session-1',
        userId: 'user-1',
        mode: GameMode.listenOnly,
        level: SpeechLevel.beginner,
        type: SpeechType.word,
        tagIds: const [],
        results: const [],
        totalSpeeches: 10,
        correctCount: 8,
        incorrectCount: 2,
        averageScore: 80.0,
        streakCount: 5,
        startedAt: DateTime(2024, 1, 1),
        completedAt: DateTime(2024, 1, 1, 0, 5),
        syncStatus: SyncStatus.pending,
      ),
      GameSessionModel(
        id: 'session-2',
        userId: 'user-1',
        mode: GameMode.listenAndRepeat,
        level: SpeechLevel.intermediate,
        type: SpeechType.phrase,
        tagIds: const [],
        results: const [],
        totalSpeeches: 15,
        correctCount: 12,
        incorrectCount: 3,
        averageScore: 80.0,
        streakCount: 8,
        startedAt: DateTime(2024, 1, 1),
        completedAt: DateTime(2024, 1, 1, 0, 10),
        syncStatus: SyncStatus.pending,
      ),
    ];

    test('should return NetworkFailure when offline', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.none],
      );

      // Act
      final result = await repository.syncPendingSessions();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return 0 when no pending sessions', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockLocalDataSource.getPendingSessions()).thenAnswer(
        (_) async => [],
      );

      // Act
      final result = await repository.syncPendingSessions();

      // Assert
      expect(result, equals(const Right(0)));
      verifyNever(mockRemoteDataSource.syncSessions(any));
    });

    test('should sync all pending sessions successfully', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockLocalDataSource.getPendingSessions()).thenAnswer(
        (_) async => pendingSessions,
      );
      when(mockLocalDataSource.updateSessionSyncStatus(any, any)).thenAnswer(
        (_) async => {},
      );
      when(mockRemoteDataSource.syncSessions(any)).thenAnswer(
        (_) async => pendingSessions.length,
      );

      // Act
      final result = await repository.syncPendingSessions();

      // Assert
      expect(result, equals(Right(pendingSessions.length)));
      verify(mockRemoteDataSource.syncSessions(pendingSessions)).called(1);
      verify(mockLocalDataSource.updateSessionSyncStatus(
        'session-1',
        SyncStatus.synced,
      )).called(1);
      verify(mockLocalDataSource.updateSessionSyncStatus(
        'session-2',
        SyncStatus.synced,
      )).called(1);
    });

    test('should update sessions to syncing status before sync', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockLocalDataSource.getPendingSessions()).thenAnswer(
        (_) async => pendingSessions,
      );
      when(mockLocalDataSource.updateSessionSyncStatus(any, any)).thenAnswer(
        (_) async => {},
      );
      when(mockRemoteDataSource.syncSessions(any)).thenAnswer(
        (_) async => pendingSessions.length,
      );

      // Act
      await repository.syncPendingSessions();

      // Assert
      verify(mockLocalDataSource.updateSessionSyncStatus(
        'session-1',
        SyncStatus.syncing,
      )).called(1);
      verify(mockLocalDataSource.updateSessionSyncStatus(
        'session-2',
        SyncStatus.syncing,
      )).called(1);
    });

    test('should mark sessions as failed on sync error', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockLocalDataSource.getPendingSessions()).thenAnswer(
        (_) async => pendingSessions,
      );
      when(mockLocalDataSource.updateSessionSyncStatus(any, any)).thenAnswer(
        (_) async => {},
      );
      when(mockRemoteDataSource.syncSessions(any)).thenThrow(
        ServerException(message: 'Sync failed'),
      );

      // Act
      final result = await repository.syncPendingSessions();

      // Assert
      expect(result.isLeft(), true);
      verify(mockLocalDataSource.updateSessionSyncStatus(
        'session-1',
        SyncStatus.failed,
      )).called(1);
      verify(mockLocalDataSource.updateSessionSyncStatus(
        'session-2',
        SyncStatus.failed,
      )).called(1);
    });

    test('should return ServerFailure on sync failure', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );
      when(mockLocalDataSource.getPendingSessions()).thenAnswer(
        (_) async => pendingSessions,
      );
      when(mockLocalDataSource.updateSessionSyncStatus(any, any)).thenAnswer(
        (_) async => {},
      );
      when(mockRemoteDataSource.syncSessions(any)).thenThrow(
        ServerException(message: 'Sync failed'),
      );

      // Act
      final result = await repository.syncPendingSessions();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('GameRepository - getSessions', () {
    final mockSessions = [
      GameSessionModel(
        id: 'session-1',
        userId: 'user-1',
        mode: GameMode.listenOnly,
        level: SpeechLevel.beginner,
        type: SpeechType.word,
        tagIds: const [],
        results: const [],
        totalSpeeches: 10,
        correctCount: 8,
        incorrectCount: 2,
        averageScore: 80.0,
        streakCount: 5,
        startedAt: DateTime(2024, 1, 1),
        completedAt: DateTime(2024, 1, 1, 0, 5),
        syncStatus: SyncStatus.synced,
      ),
    ];

    test('should return sessions from local storage', () async {
      // Arrange
      when(mockLocalDataSource.getSessions(
        userId: anyNamed('userId'),
        mode: anyNamed('mode'),
        level: anyNamed('level'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => mockSessions);

      // Act
      final result = await repository.getSessions();

      // Assert
      expect(result, equals(Right(mockSessions)));
      verify(mockLocalDataSource.getSessions(
        userId: null,
        mode: null,
        level: null,
        startDate: null,
        endDate: null,
        limit: 20,
        offset: 0,
      )).called(1);
    });

    test('should pass all filters to local datasource', () async {
      // Arrange
      final userId = 'user-1';
      final mode = GameMode.listenOnly;
      final level = SpeechLevel.beginner;
      final startDate = DateTime.now().subtract(const Duration(days: 7));
      final endDate = DateTime.now();

      when(mockLocalDataSource.getSessions(
        userId: anyNamed('userId'),
        mode: anyNamed('mode'),
        level: anyNamed('level'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => mockSessions);

      // Act
      await repository.getSessions(
        userId: userId,
        mode: mode,
        level: level,
        startDate: startDate,
        endDate: endDate,
        limit: 50,
        offset: 10,
      );

      // Assert
      verify(mockLocalDataSource.getSessions(
        userId: userId,
        mode: mode,
        level: level,
        startDate: startDate,
        endDate: endDate,
        limit: 50,
        offset: 10,
      )).called(1);
    });

    test('should return StorageFailure on StorageException', () async {
      // Arrange
      when(mockLocalDataSource.getSessions(
        userId: anyNamed('userId'),
        mode: anyNamed('mode'),
        level: anyNamed('level'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenThrow(StorageException(message: 'Storage error'));

      // Act
      final result = await repository.getSessions();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<StorageFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return UnknownFailure on unexpected error', () async {
      // Arrange
      when(mockLocalDataSource.getSessions(
        userId: anyNamed('userId'),
        mode: anyNamed('mode'),
        level: anyNamed('level'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenThrow(Exception('Unexpected error'));

      // Act
      final result = await repository.getSessions();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('GameRepository - getSessionById', () {
    final mockSession = GameSessionModel(
      id: 'session-1',
      userId: 'user-1',
      mode: GameMode.listenOnly,
      level: SpeechLevel.beginner,
      type: SpeechType.word,
      tagIds: const [],
      results: const [],
      totalSpeeches: 10,
      correctCount: 8,
      incorrectCount: 2,
      averageScore: 80.0,
      streakCount: 5,
      startedAt: DateTime(2024, 1, 1),
      completedAt: DateTime(2024, 1, 1, 0, 5),
      syncStatus: SyncStatus.synced,
    );

    test('should return session by ID from local storage', () async {
      // Arrange
      when(mockLocalDataSource.getSessionById(any)).thenAnswer(
        (_) async => mockSession,
      );

      // Act
      final result = await repository.getSessionById('session-1');

      // Assert
      expect(result, equals(Right(mockSession)));
      verify(mockLocalDataSource.getSessionById('session-1')).called(1);
    });

    test('should return StorageFailure on StorageException', () async {
      // Arrange
      when(mockLocalDataSource.getSessionById(any)).thenThrow(
        StorageException(message: 'Session not found'),
      );

      // Act
      final result = await repository.getSessionById('invalid-id');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<StorageFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return UnknownFailure on unexpected error', () async {
      // Arrange
      when(mockLocalDataSource.getSessionById(any)).thenThrow(
        Exception('Unexpected error'),
      );

      // Act
      final result = await repository.getSessionById('session-1');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('GameRepository - isConnected', () {
    test('should return true when connected to wifi', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi],
      );

      // Act
      final result = await repository.isConnected();

      // Assert
      expect(result, true);
    });

    test('should return true when connected to mobile', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.mobile],
      );

      // Act
      final result = await repository.isConnected();

      // Assert
      expect(result, true);
    });

    test('should return true when connected to ethernet', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.ethernet],
      );

      // Act
      final result = await repository.isConnected();

      // Assert
      expect(result, true);
    });

    test('should return false when not connected', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.none],
      );

      // Act
      final result = await repository.isConnected();

      // Assert
      expect(result, false);
    });

    test('should return true when multiple connections available', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi, ConnectivityResult.mobile],
      );

      // Act
      final result = await repository.isConnected();

      // Assert
      expect(result, true);
    });
  });
}
