import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:english_learning_app/core/constants/enums.dart';
import 'package:english_learning_app/domain/entities/tag.dart';
import 'package:english_learning_app/presentation/blocs/game/game_config_bloc.dart';
import 'package:english_learning_app/presentation/blocs/game/game_config_event.dart';
import 'package:english_learning_app/presentation/blocs/game/game_config_state.dart';
import 'package:english_learning_app/presentation/screens/game/game_config_screen.dart';

import 'game_config_screen_test.mocks.dart';

@GenerateMocks([GameConfigBloc])
void main() {
  late MockGameConfigBloc mockGameConfigBloc;

  setUp(() {
    mockGameConfigBloc = MockGameConfigBloc();
    when(mockGameConfigBloc.stream).thenAnswer((_) => const Stream.empty());
    when(mockGameConfigBloc.state).thenReturn(const GameConfigInitial());
  });

  Widget createGameConfigScreen() {
    return MaterialApp(
      home: BlocProvider<GameConfigBloc>.value(
        value: mockGameConfigBloc,
        child: const GameConfigScreen(),
      ),
    );
  }

  group('GameConfigScreen - UI Rendering', () {
    testWidgets('should display loading indicator when loading', (tester) async {
      // Arrange
      when(mockGameConfigBloc.state).thenReturn(const GameConfigLoading());

      // Act
      await tester.pumpWidget(createGameConfigScreen());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error message when error occurs', (tester) async {
      // Arrange
      when(mockGameConfigBloc.state).thenReturn(
        const GameConfigError('Failed to load tags'),
      );

      // Act
      await tester.pumpWidget(createGameConfigScreen());

      // Assert
      expect(find.text('Failed to load tags'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should display config form when ready', (tester) async {
      // Arrange
      final tags = [
        const Tag(id: '1', name: 'Technology'),
        const Tag(id: '2', name: 'Business'),
      ];

      when(mockGameConfigBloc.state).thenReturn(
        GameConfigReady(
          availableTags: tags,
          selectedLevel: SpeechLevel.beginner,
          selectedType: SpeechType.word,
          selectedTagIds: const [],
          speechCount: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createGameConfigScreen());

      // Assert
      expect(find.text('Game Setup'), findsOneWidget);
      expect(find.text('Difficulty Level'), findsOneWidget);
      expect(find.text('Speech Type'), findsOneWidget);
      expect(find.text('Topics (Optional)'), findsOneWidget);
      expect(find.text('Number of Speeches'), findsOneWidget);
      expect(find.text('Listen Only'), findsOneWidget);
      expect(find.text('Listen & Repeat'), findsOneWidget);
    });
  });

  group('GameConfigScreen - Level Selection', () {
    testWidgets('should display all difficulty levels', (tester) async {
      // Arrange
      when(mockGameConfigBloc.state).thenReturn(
        const GameConfigReady(
          availableTags: [],
          selectedLevel: SpeechLevel.beginner,
          selectedType: SpeechType.word,
          selectedTagIds: [],
          speechCount: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createGameConfigScreen());

      // Assert
      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
    });

    testWidgets('should dispatch LevelChanged when level selected', (tester) async {
      // Arrange
      when(mockGameConfigBloc.state).thenReturn(
        const GameConfigReady(
          availableTags: [],
          selectedLevel: SpeechLevel.beginner,
          selectedType: SpeechType.word,
          selectedTagIds: [],
          speechCount: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createGameConfigScreen());
      await tester.tap(find.text('Intermediate'));
      await tester.pump();

      // Assert
      verify(mockGameConfigBloc.add(
        const LevelChanged(SpeechLevel.intermediate),
      )).called(1);
    });
  });

  group('GameConfigScreen - Type Selection', () {
    testWidgets('should display speech types', (tester) async {
      // Arrange
      when(mockGameConfigBloc.state).thenReturn(
        const GameConfigReady(
          availableTags: [],
          selectedLevel: SpeechLevel.beginner,
          selectedType: SpeechType.word,
          selectedTagIds: [],
          speechCount: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createGameConfigScreen());

      // Assert
      expect(find.text('Listen Only'), findsAtLeastNWidgets(1));
      expect(find.text('Listen & Repeat'), findsAtLeastNWidgets(1));
    });

    testWidgets('should dispatch TypeChanged when type selected', (tester) async {
      // Arrange
      when(mockGameConfigBloc.state).thenReturn(
        const GameConfigReady(
          availableTags: [],
          selectedLevel: SpeechLevel.beginner,
          selectedType: SpeechType.word,
          selectedTagIds: [],
          speechCount: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createGameConfigScreen());

      // Find the radio button for Listen & Repeat in the type selector (not the start button)
      final typeRadio = find.ancestor(
        of: find.text('Listen & Repeat'),
        matching: find.byType(RadioListTile<SpeechType>),
      );
      await tester.tap(typeRadio.first);
      await tester.pump();

      // Assert
      verify(mockGameConfigBloc.add(
        const TypeChanged(SpeechType.phrase),
      )).called(1);
    });
  });

  group('GameConfigScreen - Tag Selection', () {
    testWidgets('should display available tags', (tester) async {
      // Arrange
      final tags = [
        const Tag(id: '1', name: 'Technology'),
        const Tag(id: '2', name: 'Business'),
        const Tag(id: '3', name: 'Travel'),
      ];

      when(mockGameConfigBloc.state).thenReturn(
        GameConfigReady(
          availableTags: tags,
          selectedLevel: SpeechLevel.beginner,
          selectedType: SpeechType.word,
          selectedTagIds: const [],
          speechCount: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createGameConfigScreen());

      // Assert
      expect(find.text('Technology'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('Travel'), findsOneWidget);
    });

    testWidgets('should dispatch TagToggled when tag selected', (tester) async {
      // Arrange
      final tags = [
        const Tag(id: '1', name: 'Technology'),
      ];

      when(mockGameConfigBloc.state).thenReturn(
        GameConfigReady(
          availableTags: tags,
          selectedLevel: SpeechLevel.beginner,
          selectedType: SpeechType.word,
          selectedTagIds: const [],
          speechCount: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createGameConfigScreen());
      await tester.tap(find.text('Technology'));
      await tester.pump();

      // Assert
      verify(mockGameConfigBloc.add(
        const TagToggled('1'),
      )).called(1);
    });

    testWidgets('should show selected tags with checkmarks', (tester) async {
      // Arrange
      final tags = [
        const Tag(id: '1', name: 'Technology'),
        const Tag(id: '2', name: 'Business'),
      ];

      when(mockGameConfigBloc.state).thenReturn(
        GameConfigReady(
          availableTags: tags,
          selectedLevel: SpeechLevel.beginner,
          selectedType: SpeechType.word,
          selectedTagIds: const ['1'],
          speechCount: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createGameConfigScreen());

      // Assert - Selected tag should have visual indication
      final selectedChip = find.ancestor(
        of: find.text('Technology'),
        matching: find.byType(FilterChip),
      );
      expect(selectedChip, findsOneWidget);
    });
  });

  group('GameConfigScreen - Speech Count Selection', () {
    testWidgets('should display count options', (tester) async {
      // Arrange
      when(mockGameConfigBloc.state).thenReturn(
        const GameConfigReady(
          availableTags: [],
          selectedLevel: SpeechLevel.beginner,
          selectedType: SpeechType.word,
          selectedTagIds: [],
          speechCount: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createGameConfigScreen());

      // Assert
      expect(find.text('10'), findsWidgets);
      expect(find.text('20'), findsWidgets);
      expect(find.text('30'), findsWidgets);
    });

    testWidgets('should dispatch CountChanged when count selected', (tester) async {
      // Arrange
      when(mockGameConfigBloc.state).thenReturn(
        const GameConfigReady(
          availableTags: [],
          selectedLevel: SpeechLevel.beginner,
          selectedType: SpeechType.word,
          selectedTagIds: [],
          speechCount: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createGameConfigScreen());

      // Find the 20 button in speech count selector
      final countButton = find.text('20').first;
      await tester.tap(countButton);
      await tester.pump();

      // Assert
      verify(mockGameConfigBloc.add(
        const SpeechCountChanged(20),
      )).called(1);
    });
  });

  group('GameConfigScreen - Start Game', () {
    testWidgets('should dispatch GameStartRequested when Listen Only button tapped',
        (tester) async {
      // Arrange
      when(mockGameConfigBloc.state).thenReturn(
        const GameConfigReady(
          availableTags: [],
          selectedLevel: SpeechLevel.beginner,
          selectedType: SpeechType.word,
          selectedTagIds: [],
          speechCount: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createGameConfigScreen());

      // Find the Listen Only start button (the large one at bottom)
      final startButton = find.widgetWithText(ElevatedButton, 'Listen Only');
      await tester.tap(startButton);
      await tester.pump();

      // Assert
      verify(mockGameConfigBloc.add(
        const GameStartRequested(GameMode.listenOnly),
      )).called(1);
    });

    testWidgets('should dispatch GameStartRequested when Listen & Repeat button tapped',
        (tester) async {
      // Arrange
      when(mockGameConfigBloc.state).thenReturn(
        const GameConfigReady(
          availableTags: [],
          selectedLevel: SpeechLevel.beginner,
          selectedType: SpeechType.word,
          selectedTagIds: [],
          speechCount: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createGameConfigScreen());

      // Find the Listen & Repeat start button
      final startButton = find.widgetWithText(ElevatedButton, 'Listen & Repeat');
      await tester.tap(startButton);
      await tester.pump();

      // Assert
      verify(mockGameConfigBloc.add(
        const GameStartRequested(GameMode.listenAndRepeat),
      )).called(1);
    });
  });

  group('GameConfigScreen - Error Handling', () {
    testWidgets('should retry loading tags when retry button tapped', (tester) async {
      // Arrange
      when(mockGameConfigBloc.state).thenReturn(
        const GameConfigError('Network error'),
      );

      // Act
      await tester.pumpWidget(createGameConfigScreen());
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Assert
      verify(mockGameConfigBloc.add(const TagsLoadRequested())).called(1);
    });

    testWidgets('should display appropriate error icon and message', (tester) async {
      // Arrange
      when(mockGameConfigBloc.state).thenReturn(
        const GameConfigError('Server is unavailable'),
      );

      // Act
      await tester.pumpWidget(createGameConfigScreen());

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Server is unavailable'), findsOneWidget);
    });
  });

  group('GameConfigScreen - Navigation', () {
    testWidgets('should show loading when starting game', (tester) async {
      // Arrange
      when(mockGameConfigBloc.state).thenReturn(
        const GameConfigStarting(
          mode: GameMode.listenOnly,
          level: SpeechLevel.beginner,
          type: SpeechType.word,
          tagIds: [],
          count: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createGameConfigScreen());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
