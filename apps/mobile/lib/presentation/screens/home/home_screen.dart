import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Home screen with bottom navigation bar
///
/// This screen serves as the main container for the app's primary sections:
/// - Game Config (Home tab): Start new games
/// - History: View past game sessions
/// - Profile: User profile and settings
class HomeScreen extends StatelessWidget {
  /// The current navigation shell
  final StatefulNavigationShell navigationShell;

  const HomeScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
