import 'package:english_learning_app/presentation/blocs/auth/auth_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import 'core/utils/logger.dart';
import 'data/datasources/local/hive_storage.dart';
import 'di/injection.dart';
import 'firebase_options.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/screens/auth/splash_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger based on build mode
  AppLogger.initialize(
    level: kDebugMode ? Level.debug : Level.warning,
    printTime: true,
    printEmojis: true,
  );

  AppLogger.info('🚀 Starting English Learning App...');

  AppLogger.info('🚀 Starting English Learning App...');

  // Lock orientation to portrait mode
  AppLogger.debug('Setting orientation to portrait mode...');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase with platform-specific options
  AppLogger.debug('Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AppLogger.info('✅ Firebase initialized successfully');

  // Initialize Hive storage
  AppLogger.debug('Initializing Hive storage...');
  await HiveStorage.initialize();
  AppLogger.info('✅ Hive storage initialized successfully');

  // Initialize dependency injection
  AppLogger.debug('Initializing dependency injection...');
  await initializeDependencies();
  AppLogger.info('✅ Dependency injection configured successfully');

  AppLogger.info('✨ App initialization complete, launching app...');

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
      child: MaterialApp(
        title: 'English Practice',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
