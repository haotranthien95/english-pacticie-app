import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration test helper utilities
class IntegrationTestHelpers {
  /// Wait for a specific widget to appear
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
    Duration pollInterval = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(pollInterval);
    }

    throw TestFailure('Widget not found within timeout: $finder');
  }

  /// Wait for a widget to disappear
  static Future<void> waitForWidgetToDisappear(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
    Duration pollInterval = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      if (finder.evaluate().isEmpty) {
        return;
      }
      await tester.pump(pollInterval);
    }

    throw TestFailure('Widget still present after timeout: $finder');
  }

  /// Scroll until a widget is visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder item,
    Finder scrollable, {
    double delta = 300,
    int maxScrolls = 50,
  }) async {
    for (int i = 0; i < maxScrolls; i++) {
      if (item.evaluate().isNotEmpty) {
        return;
      }

      await tester.drag(scrollable, Offset(0, -delta));
      await tester.pumpAndSettle();
    }

    throw TestFailure('Could not find widget by scrolling: $item');
  }

  /// Enter text and wait for debounce
  static Future<void> enterTextAndWait(
    WidgetTester tester,
    Finder finder,
    String text, {
    Duration waitAfter = const Duration(milliseconds: 500),
  }) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
    await tester.pump(waitAfter);
  }

  /// Tap and wait for navigation
  static Future<void> tapAndWaitForNavigation(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.tap(finder);
    await tester.pumpAndSettle(timeout);
  }

  /// Verify snackbar message
  static Future<void> verifySnackbar(
    WidgetTester tester,
    String message,
  ) async {
    await waitForWidget(tester, find.text(message));
    expect(find.byType(SnackBar), findsOneWidget);
  }

  /// Dismiss snackbar
  static Future<void> dismissSnackbar(WidgetTester tester) async {
    final snackbar = find.byType(SnackBar);
    if (snackbar.evaluate().isNotEmpty) {
      await tester.drag(snackbar, const Offset(0, 100));
      await tester.pumpAndSettle();
    }
  }

  /// Verify loading indicator appears then disappears
  static Future<void> verifyLoadingIndicator(
    WidgetTester tester, {
    Duration maxWait = const Duration(seconds: 10),
  }) async {
    // Wait for loading indicator to appear
    await waitForWidget(
      tester,
      find.byType(CircularProgressIndicator),
      timeout: const Duration(seconds: 2),
    );

    // Wait for it to disappear
    await waitForWidgetToDisappear(
      tester,
      find.byType(CircularProgressIndicator),
      timeout: maxWait,
    );
  }

  /// Perform authentication (login)
  static Future<void> performLogin(
    WidgetTester tester, {
    String email = 'test@example.com',
    String password = 'testpassword123',
  }) async {
    // Wait for login screen
    await waitForWidget(tester, find.text('Login to continue'));

    // Enter credentials
    await enterTextAndWait(
      tester,
      find.widgetWithText(TextFormField, 'Email'),
      email,
    );

    await enterTextAndWait(
      tester,
      find.widgetWithText(TextFormField, 'Password'),
      password,
    );

    // Tap login button
    await tapAndWaitForNavigation(
      tester,
      find.widgetWithText(ElevatedButton, 'Login'),
    );
  }

  /// Perform logout
  static Future<void> performLogout(WidgetTester tester) async {
    // Navigate to profile if not there
    final profileTab = find.text('Profile');
    if (profileTab.evaluate().isNotEmpty) {
      await tester.tap(profileTab);
      await tester.pumpAndSettle();
    }

    // Tap settings
    final settingsButton = find.text('Settings');
    if (settingsButton.evaluate().isNotEmpty) {
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();
    }

    // Tap logout
    final logoutButton = find.text('Logout');
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    // Confirm logout if dialog appears
    final confirmButton = find.text('Confirm');
    if (confirmButton.evaluate().isNotEmpty) {
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();
    }
  }

  /// Navigate to tab by name
  static Future<void> navigateToTab(
    WidgetTester tester,
    String tabName,
  ) async {
    final tab = find.text(tabName);
    if (tab.evaluate().isEmpty) {
      throw TestFailure('Tab not found: $tabName');
    }

    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  /// Verify bottom navigation bar
  static void verifyBottomNavigation(WidgetTester tester) {
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  }

  /// Take screenshot (for debugging)
  static Future<void> takeScreenshot(
    WidgetTester tester,
    String name,
  ) async {
    // Screenshots require additional setup
    // This is a placeholder for potential screenshot functionality
    debugPrint('Screenshot would be taken here: $name');
  }

  /// Verify no errors in console
  static void verifyNoErrors() {
    // In real implementation, would check for error logs
    // This is a placeholder for error verification
  }

  /// Simulate app lifecycle event
  static Future<void> simulateAppLifecycle(
    WidgetTester tester,
    AppLifecycleState state,
  ) async {
    final binding = tester.binding;
    binding.handleAppLifecycleStateChanged(state);
    await tester.pumpAndSettle();
  }

  /// Simulate network connectivity change
  static Future<void> simulateConnectivityChange(
    WidgetTester tester,
    bool isConnected,
  ) async {
    // This would require connectivity mocking
    // Placeholder for connectivity testing
    debugPrint('Simulating connectivity: $isConnected');
    await tester.pumpAndSettle();
  }

  /// Clear all app data (logout + clear storage)
  static Future<void> clearAppData(WidgetTester tester) async {
    // This would require access to storage services
    // Placeholder for data clearing
    debugPrint('Clearing app data');
  }

  /// Generate test session data
  static Map<String, dynamic> generateTestSession({
    String mode = 'listen_only',
    String level = 'intermediate',
    int correctAnswers = 15,
    int totalSpeeches = 20,
  }) {
    return {
      'id': 'test-session-${DateTime.now().millisecondsSinceEpoch}',
      'mode': mode,
      'level': level,
      'correctAnswers': correctAnswers,
      'totalSpeeches': totalSpeeches,
      'accuracy': (correctAnswers / totalSpeeches * 100).round(),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Generate test user data
  static Map<String, dynamic> generateTestUser({
    String email = 'test@example.com',
    String username = 'testuser',
    String? displayName,
  }) {
    return {
      'id': 'test-user-${DateTime.now().millisecondsSinceEpoch}',
      'email': email,
      'username': username,
      'displayName': displayName ?? username,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Verify form field error
  static void verifyFieldError(
    WidgetTester tester,
    String fieldLabel,
    String errorMessage,
  ) {
    final field = find.ancestor(
      of: find.text(fieldLabel),
      matching: find.byType(TextFormField),
    );
    expect(field, findsOneWidget);
    expect(find.text(errorMessage), findsOneWidget);
  }

  /// Verify button is disabled
  static void verifyButtonDisabled(
    WidgetTester tester,
    String buttonText,
  ) {
    final button = find.widgetWithText(ElevatedButton, buttonText);
    expect(button, findsOneWidget);

    final widget = tester.widget<ElevatedButton>(button);
    expect(widget.onPressed, isNull);
  }

  /// Verify button is enabled
  static void verifyButtonEnabled(
    WidgetTester tester,
    String buttonText,
  ) {
    final button = find.widgetWithText(ElevatedButton, buttonText);
    expect(button, findsOneWidget);

    final widget = tester.widget<ElevatedButton>(button);
    expect(widget.onPressed, isNotNull);
  }

  /// Find text field by label
  static Finder findTextFieldByLabel(String label) {
    return find.ancestor(
      of: find.text(label),
      matching: find.byType(TextFormField),
    );
  }

  /// Find button by icon
  static Finder findButtonByIcon(IconData icon) {
    return find.ancestor(
      of: find.byIcon(icon),
      matching: find.byType(IconButton),
    );
  }

  /// Verify navigation occurred
  static Future<void> verifyNavigationTo(
    WidgetTester tester,
    String screenIndicator,
  ) async {
    await waitForWidget(
      tester,
      find.text(screenIndicator),
      timeout: const Duration(seconds: 3),
    );
  }

  /// Perform swipe gesture
  static Future<void> swipeLeft(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.drag(finder, const Offset(-300, 0));
    await tester.pumpAndSettle();
  }

  /// Perform swipe gesture
  static Future<void> swipeRight(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.drag(finder, const Offset(300, 0));
    await tester.pumpAndSettle();
  }

  /// Perform swipe up gesture
  static Future<void> swipeUp(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.drag(finder, const Offset(0, -300));
    await tester.pumpAndSettle();
  }

  /// Perform swipe down gesture
  static Future<void> swipeDown(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.drag(finder, const Offset(0, 300));
    await tester.pumpAndSettle();
  }

  /// Verify widget tree structure
  static void printWidgetTree(WidgetTester tester) {
    debugDumpApp();
  }

  /// Get widget size
  static Size getWidgetSize(WidgetTester tester, Finder finder) {
    final element = finder.evaluate().single;
    final renderBox = element.renderObject as RenderBox;
    return renderBox.size;
  }

  /// Verify minimum touch target size (48x48 dp)
  static void verifyMinimumTouchTarget(WidgetTester tester, Finder finder) {
    final size = getWidgetSize(tester, finder);
    expect(size.width >= 48, true, reason: 'Touch target width too small');
    expect(size.height >= 48, true, reason: 'Touch target height too small');
  }

  /// Wait for animation to complete
  static Future<void> waitForAnimation(
    WidgetTester tester, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    await tester.pump(duration);
    await tester.pumpAndSettle();
  }

  /// Verify text exists anywhere in widget tree
  static void verifyTextExists(String text) {
    expect(find.text(text), findsWidgets);
  }

  /// Verify text does not exist
  static void verifyTextDoesNotExist(String text) {
    expect(find.text(text), findsNothing);
  }

  /// Measure operation duration
  static Future<Duration> measureDuration(
    Future<void> Function() operation,
  ) async {
    final startTime = DateTime.now();
    await operation();
    return DateTime.now().difference(startTime);
  }

  /// Verify operation completes within timeout
  static Future<void> verifyPerformance(
    Future<void> Function() operation,
    Duration maxDuration,
  ) async {
    final duration = await measureDuration(operation);
    expect(
      duration.inMilliseconds <= maxDuration.inMilliseconds,
      true,
      reason: 'Operation took ${duration.inMilliseconds}ms, '
          'expected <= ${maxDuration.inMilliseconds}ms',
    );
  }
}
