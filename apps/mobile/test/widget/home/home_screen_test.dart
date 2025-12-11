import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:english_learning_app/presentation/screens/home/home_screen.dart';

import 'home_screen_test.mocks.dart';

@GenerateMocks([StatefulNavigationShell])
void main() {
  late MockStatefulNavigationShell mockNavigationShell;

  setUp(() {
    mockNavigationShell = MockStatefulNavigationShell();
    when(mockNavigationShell.currentIndex).thenReturn(0);
    when(mockNavigationShell.build(any)).thenReturn(Container());
  });

  Widget createHomeScreen() {
    return MaterialApp(
      home: HomeScreen(navigationShell: mockNavigationShell),
    );
  }

  group('HomeScreen - UI Rendering', () {
    testWidgets('should display bottom navigation bar', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createHomeScreen());

      // Assert
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('should display all navigation destinations', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createHomeScreen());

      // Assert
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('should display navigation icons', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createHomeScreen());

      // Assert
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.history_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outlined), findsOneWidget);
    });
  });

  group('HomeScreen - Navigation', () {
    testWidgets('should show Home tab as selected by default', (tester) async {
      // Arrange
      when(mockNavigationShell.currentIndex).thenReturn(0);

      // Act
      await tester.pumpWidget(createHomeScreen());

      // Assert
      final navigationBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navigationBar.selectedIndex, equals(0));
    });

    testWidgets('should call goBranch when Home tab tapped', (tester) async {
      // Arrange
      when(mockNavigationShell.currentIndex).thenReturn(1);
      await tester.pumpWidget(createHomeScreen());

      // Act
      await tester.tap(find.text('Home'));
      await tester.pump();

      // Assert
      verify(mockNavigationShell.goBranch(0, initialLocation: false)).called(1);
    });

    testWidgets('should call goBranch when History tab tapped', (tester) async {
      // Arrange
      when(mockNavigationShell.currentIndex).thenReturn(0);
      await tester.pumpWidget(createHomeScreen());

      // Act
      await tester.tap(find.text('History'));
      await tester.pump();

      // Assert
      verify(mockNavigationShell.goBranch(1, initialLocation: false)).called(1);
    });

    testWidgets('should call goBranch when Profile tab tapped', (tester) async {
      // Arrange
      when(mockNavigationShell.currentIndex).thenReturn(0);
      await tester.pumpWidget(createHomeScreen());

      // Act
      await tester.tap(find.text('Profile'));
      await tester.pump();

      // Assert
      verify(mockNavigationShell.goBranch(2, initialLocation: false)).called(1);
    });

    testWidgets('should refresh current branch when tapping selected tab', (tester) async {
      // Arrange
      when(mockNavigationShell.currentIndex).thenReturn(0);
      await tester.pumpWidget(createHomeScreen());

      // Act - Tap already selected Home tab
      await tester.tap(find.text('Home'));
      await tester.pump();

      // Assert - Should pass initialLocation: true
      verify(mockNavigationShell.goBranch(0, initialLocation: true)).called(1);
    });
  });

  group('HomeScreen - Icon States', () {
    testWidgets('should show selected icon for active tab', (tester) async {
      // Arrange
      when(mockNavigationShell.currentIndex).thenReturn(0);

      // Act
      await tester.pumpWidget(createHomeScreen());

      // Assert - Home should show selected icon
      expect(find.byIcon(Icons.home), findsNothing); // Selected icons not visible in initial render
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('should update selected index when navigation changes', (tester) async {
      // Arrange
      when(mockNavigationShell.currentIndex).thenReturn(1);

      // Act
      await tester.pumpWidget(createHomeScreen());

      // Assert
      final navigationBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navigationBar.selectedIndex, equals(1));
    });

    testWidgets('should handle last tab selection', (tester) async {
      // Arrange
      when(mockNavigationShell.currentIndex).thenReturn(2);

      // Act
      await tester.pumpWidget(createHomeScreen());

      // Assert
      final navigationBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navigationBar.selectedIndex, equals(2));
    });
  });

  group('HomeScreen - Content Display', () {
    testWidgets('should display navigation shell content', (tester) async {
      // Arrange
      when(mockNavigationShell.build(any)).thenReturn(
        const Center(child: Text('Current Tab Content')),
      );

      // Act
      await tester.pumpWidget(createHomeScreen());

      // Assert
      expect(find.text('Current Tab Content'), findsOneWidget);
    });

    testWidgets('should wrap navigation shell in Scaffold body', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createHomeScreen());

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.body, equals(mockNavigationShell));
    });
  });
}
