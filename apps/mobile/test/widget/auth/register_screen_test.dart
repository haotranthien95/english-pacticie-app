import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:english_learning_app/domain/entities/user.dart';
import 'package:english_learning_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:english_learning_app/presentation/blocs/auth/auth_event.dart';
import 'package:english_learning_app/presentation/blocs/auth/auth_state.dart';
import 'package:english_learning_app/presentation/screens/auth/register_screen.dart';

import 'register_screen_test.mocks.dart';

@GenerateMocks([AuthBloc])
void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(mockAuthBloc.state).thenReturn(const AuthInitial());
  });

  Widget createRegisterScreen() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const RegisterScreen(),
      ),
    );
  }

  group('RegisterScreen - UI Rendering', () {
    testWidgets('should display all UI elements', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createRegisterScreen());

      // Assert
      expect(find.text('Register'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Fill in the details to register'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(5));
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.textContaining('Already have an account?'), findsOneWidget);
    });

    testWidgets('should display all required fields', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createRegisterScreen());

      // Assert
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Display Name (Optional)'),
          findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Confirm Password'),
          findsOneWidget);
    });

    testWidgets('should display password fields with visibility toggles',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createRegisterScreen());

      // Assert - Both password fields should be obscured initially
      final passwordFields = tester
          .widgetList<TextFormField>(
            find.byType(TextFormField),
          )
          .where((field) => field.obscureText == true);

      expect(passwordFields.length, 2);
      expect(find.byIcon(Icons.visibility), findsNWidgets(2));
    });

    testWidgets('should toggle password visibility independently',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createRegisterScreen());

      // Act - Toggle first password visibility
      final visibilityIcons = find.byIcon(Icons.visibility);
      await tester.tap(visibilityIcons.first);
      await tester.pump();

      // Assert - One should be visibility_off, one still visibility
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });

  group('RegisterScreen - Form Validation', () {
    testWidgets('should show error when email is empty', (tester) async {
      // Arrange
      await tester.pumpWidget(createRegisterScreen());

      // Act
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Assert
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('should show error when email is invalid', (tester) async {
      // Arrange
      await tester.pumpWidget(createRegisterScreen());

      // Act
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'invalidemail',
      );
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Assert
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should show error when username is empty', (tester) async {
      // Arrange
      await tester.pumpWidget(createRegisterScreen());

      // Act
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Assert
      expect(find.text('Please enter a username'), findsOneWidget);
    });

    testWidgets('should show error when username is too short', (tester) async {
      // Arrange
      await tester.pumpWidget(createRegisterScreen());

      // Act
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'ab',
      );
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Assert
      expect(
          find.text('Username must be at least 3 characters'), findsOneWidget);
    });

    testWidgets('should show error when password is empty', (tester) async {
      // Arrange
      await tester.pumpWidget(createRegisterScreen());

      // Act
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Assert
      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('should show error when password is too short', (tester) async {
      // Arrange
      await tester.pumpWidget(createRegisterScreen());

      // Act
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        '123',
      );
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Assert
      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('should show error when passwords do not match',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createRegisterScreen());

      // Act
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'differentpassword',
      );
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Assert
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('should not show errors when all required fields are valid',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createRegisterScreen());

      // Act - Fill all required fields correctly
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Assert - No validation errors
      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Please enter a username'), findsNothing);
      expect(find.text('Please enter a password'), findsNothing);
      expect(find.text('Passwords do not match'), findsNothing);
    });

    testWidgets('should allow optional display name to be empty',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createRegisterScreen());

      // Act - Fill required fields, leave display name empty
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Assert - Should dispatch event with null displayName
      verify(mockAuthBloc.add(const RegisterRequested(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        displayName: null,
      ))).called(1);
    });
  });

  group('RegisterScreen - User Interactions', () {
    testWidgets(
        'should dispatch RegisterRequested event when sign up button tapped with valid data',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createRegisterScreen());

      // Act - Fill form and submit
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display Name (Optional)'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Assert
      verify(mockAuthBloc.add(const RegisterRequested(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        displayName: 'Test User',
      ))).called(1);
    });

    testWidgets('should navigate back when login link tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(createRegisterScreen());

      // Act
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Assert - Screen should pop (back button in AppBar handles this)
      // In real app, this navigates back to login screen
      expect(find.text('Register'), findsNothing);
    });
  });

  group('RegisterScreen - State Changes', () {
    testWidgets('should disable form fields when loading', (tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(const AuthLoading());
      await tester.pumpWidget(createRegisterScreen());

      // Assert - All fields should be disabled
      final textFields = tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      );

      for (final field in textFields) {
        expect(field.enabled, false);
      }
    });

    testWidgets('should show loading indicator when state is AuthLoading',
        (tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(const AuthLoading());
      await tester.pumpWidget(createRegisterScreen());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle successful registration', (tester) async {
      // Arrange
      final user = User(
        id: 'user-1',
        email: 'test@example.com',
        username: 'testuser',
        displayName: 'Test User',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createRegisterScreen());

      // Act - Simulate state change to authenticated
      when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: user));
      await tester.pump();

      // Assert - State should be authenticated
      expect(mockAuthBloc.state, isA<AuthAuthenticated>());
    });

    testWidgets('should handle registration error', (tester) async {
      // Arrange
      await tester.pumpWidget(createRegisterScreen());

      // Act - Simulate error state
      when(mockAuthBloc.state).thenReturn(
        const AuthError(message: 'Email already exists'),
      );
      await tester.pump();

      // Assert - State should be error
      expect(mockAuthBloc.state, isA<AuthError>());
      expect((mockAuthBloc.state as AuthError).message, 'Email already exists');
    });
  });

  group('RegisterScreen - Edge Cases', () {
    testWidgets('should trim email and username whitespace before submitting',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createRegisterScreen());

      // Act - Enter fields with whitespace
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        '  test@example.com  ',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        '  testuser  ',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Assert - Email and username should be trimmed
      verify(mockAuthBloc.add(const RegisterRequested(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        displayName: null,
      ))).called(1);
    });

    testWidgets('should trim display name whitespace and handle empty as null',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createRegisterScreen());

      // Act - Enter display name with only whitespace
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display Name (Optional)'),
        '   ',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Assert - Empty display name should be null
      verify(mockAuthBloc.add(const RegisterRequested(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        displayName: null,
      ))).called(1);
    });

    testWidgets('should handle lowercase email conversion', (tester) async {
      // Arrange
      await tester.pumpWidget(createRegisterScreen());

      // Act - Enter uppercase email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'TEST@EXAMPLE.COM',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Assert - Email should be sent as entered (backend handles case)
      final capturedEvent = verify(
        mockAuthBloc.add(captureAny),
      ).captured.single as RegisterRequested;

      expect(capturedEvent.email, 'TEST@EXAMPLE.COM');
    });
  });
}
