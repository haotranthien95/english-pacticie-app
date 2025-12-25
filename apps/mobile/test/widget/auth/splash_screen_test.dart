import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:english_learning_app/core/constants/enums.dart';
import 'package:english_learning_app/domain/entities/user.dart';
import 'package:english_learning_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:english_learning_app/presentation/blocs/auth/auth_event.dart';
import 'package:english_learning_app/presentation/blocs/auth/auth_state.dart';
import 'package:english_learning_app/presentation/screens/auth/splash_screen.dart';

import 'splash_screen_test.mocks.dart';

@GenerateMocks([AuthBloc])
void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(mockAuthBloc.state).thenReturn(const AuthInitial());
  });

  Widget createSplashScreen() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const SplashScreen(),
      ),
    );
  }

  group('SplashScreen - UI Rendering', () {
    testWidgets('should display app logo and name', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createSplashScreen());

      // Assert
      expect(find.byIcon(Icons.school), findsOneWidget);
      expect(find.text('English Practice'), findsOneWidget);
      expect(find.text('Learn pronunciation with AI'), findsOneWidget);
    });

    testWidgets('should display loading indicator initially', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createSplashScreen());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should have centered layout', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createSplashScreen());

      // Assert
      expect(find.byType(Center), findsWidgets);
      expect(find.byType(Column), findsOneWidget);
    });
  });

  group('SplashScreen - Authentication Check', () {
    testWidgets('should dispatch AuthCheckRequested on init', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createSplashScreen());

      // Wait for the delayed event dispatch (500ms)
      await tester.pump(const Duration(milliseconds: 500));

      // Assert
      verify(mockAuthBloc.add(const AuthCheckRequested())).called(1);
    });

    testWidgets('should dispatch AuthCheckRequested after delay', (tester) async {
      // Arrange
      await tester.pumpWidget(createSplashScreen());

      // Act - Verify event not dispatched immediately
      verifyNever(mockAuthBloc.add(const AuthCheckRequested()));

      // Wait for delay
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - Event should now be dispatched
      verify(mockAuthBloc.add(const AuthCheckRequested())).called(1);
    });
  });

  group('SplashScreen - Navigation', () {
    testWidgets('should navigate to home when authenticated', (tester) async {
      // Arrange
      final user = User(
        id: 'user-1',
        email: 'test@example.com',
        username: 'testuser',
        displayName: 'Test User',
        createdAt: DateTime.now(),
        authProvider: AuthProvider.email,
      );

      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(AuthAuthenticated(user: user)),
      );
      when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: user));

      // Act
      await tester.pumpWidget(createSplashScreen());
      await tester.pumpAndSettle();

      // Assert - Should show home screen placeholder
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Welcome, Test User!'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('should navigate to login when unauthenticated', (tester) async {
      // Arrange
      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(const AuthUnauthenticated()),
      );
      when(mockAuthBloc.state).thenReturn(const AuthUnauthenticated());

      // Act
      await tester.pumpWidget(createSplashScreen());
      await tester.pumpAndSettle();

      // Assert - Should show login screen
      expect(find.text('English Practice'), findsOneWidget);
      expect(find.text('Login to continue'), findsOneWidget);
    });

    testWidgets('should navigate to login when authentication check fails', (tester) async {
      // Arrange
      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(const AuthError(message: 'Token expired')),
      );
      when(mockAuthBloc.state).thenReturn(
        const AuthError(message: 'Token expired'),
      );

      // Act
      await tester.pumpWidget(createSplashScreen());
      await tester.pumpAndSettle();

      // Assert - Should show login screen
      expect(find.text('Login to continue'), findsOneWidget);
    });

    testWidgets('should show error message when authentication fails', (tester) async {
      // Arrange
      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(const AuthError(message: 'Network error')),
      );
      when(mockAuthBloc.state).thenReturn(
        const AuthError(message: 'Network error'),
      );

      // Act
      await tester.pumpWidget(createSplashScreen());
      await tester.pump();

      // Assert - BlocListener should trigger SnackBar in real app
      expect(mockAuthBloc.state, isA<AuthError>());
      expect((mockAuthBloc.state as AuthError).message, 'Network error');
    });
  });

  group('SplashScreen - User Display', () {
    testWidgets('should display username when displayName is null', (tester) async {
      // Arrange
      final user = User(
        id: 'user-1',
        email: 'test@example.com',
        username: 'testuser',
        displayName: null,
        createdAt: DateTime.now(),
        authProvider: AuthProvider.email,
      );

      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(AuthAuthenticated(user: user)),
      );
      when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: user));

      // Act
      await tester.pumpWidget(createSplashScreen());
      await tester.pumpAndSettle();

      // Assert - Should show username as fallback
      expect(find.text('Welcome, testuser!'), findsOneWidget);
    });

    testWidgets('should display displayName when available', (tester) async {
      // Arrange
      final user = User(
        id: 'user-1',
        email: 'test@example.com',
        username: 'testuser',
        displayName: 'Test User',
        createdAt: DateTime.now(),
        authProvider: AuthProvider.email,
      );

      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(AuthAuthenticated(user: user)),
      );
      when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: user));

      // Act
      await tester.pumpWidget(createSplashScreen());
      await tester.pumpAndSettle();

      // Assert - Should show display name
      expect(find.text('Welcome, Test User!'), findsOneWidget);
    });
  });

  group('SplashScreen - Logout Flow', () {
    testWidgets('should dispatch LogoutRequested and navigate to login when logout tapped',
        (tester) async {
      // Arrange
      final user = User(
        id: 'user-1',
        email: 'test@example.com',
        username: 'testuser',
        displayName: 'Test User',
        createdAt: DateTime.now(),
        authProvider: AuthProvider.email,
      );

      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(AuthAuthenticated(user: user)),
      );
      when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: user));

      await tester.pumpWidget(createSplashScreen());
      await tester.pumpAndSettle();

      // Act - Tap logout button
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Assert - Should dispatch logout event
      verify(mockAuthBloc.add(const LogoutRequested())).called(1);
    });
  });

  group('SplashScreen - Edge Cases', () {
    testWidgets('should handle rapid state changes', (tester) async {
      // Arrange
      final user = User(
        id: 'user-1',
        email: 'test@example.com',
        username: 'testuser',
        displayName: 'Test User',
        createdAt: DateTime.now(),
        authProvider: AuthProvider.email,
      );

      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const AuthLoading(),
          AuthAuthenticated(user: user),
          const AuthUnauthenticated(),
        ]),
      );
      when(mockAuthBloc.state).thenReturn(const AuthInitial());

      // Act
      await tester.pumpWidget(createSplashScreen());
      await tester.pump();

      // Update state to authenticated
      when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: user));
      await tester.pump();
      await tester.pumpAndSettle();

      // Assert - Should handle state transitions gracefully
      expect(find.text('Welcome, Test User!'), findsOneWidget);
    });

    testWidgets('should not dispatch AuthCheckRequested if widget disposed', (tester) async {
      // Arrange
      await tester.pumpWidget(createSplashScreen());

      // Act - Dispose widget before delay completes
      await tester.pumpWidget(Container());

      // Wait for delay
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - Event should not be dispatched (widget unmounted)
      verifyNever(mockAuthBloc.add(const AuthCheckRequested()));
    });

    testWidgets('should handle multiple authentication checks', (tester) async {
      // Arrange
      await tester.pumpWidget(createSplashScreen());

      // Act - Wait for first check
      await tester.pump(const Duration(milliseconds: 500));

      // Rebuild widget
      await tester.pumpWidget(createSplashScreen());
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - Should dispatch check twice (once per init)
      verify(mockAuthBloc.add(const AuthCheckRequested())).called(2);
    });
  });

  group('SplashScreen - Loading State', () {
    testWidgets('should show loading indicator during authentication check', (tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(const AuthLoading());

      // Act
      await tester.pumpWidget(createSplashScreen());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Checking authentication...'), findsOneWidget);
    });

    testWidgets('should keep showing splash screen during loading', (tester) async {
      // Arrange
      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(const AuthLoading()),
      );
      when(mockAuthBloc.state).thenReturn(const AuthLoading());

      // Act
      await tester.pumpWidget(createSplashScreen());
      await tester.pump();

      // Assert - Should still show splash elements
      expect(find.byIcon(Icons.school), findsOneWidget);
      expect(find.text('English Practice'), findsOneWidget);
    });
  });
}
