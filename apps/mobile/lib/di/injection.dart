import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_config.dart';

final getIt = GetIt.instance;

/// Initialize dependency injection container
/// Call this once at app startup before running the app
Future<void> initializeDependencies() async {
  // ==================== External Dependencies ====================

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);

  // Connectivity
  getIt.registerLazySingleton(() => Connectivity());

  // Dio HTTP Client
  getIt.registerLazySingleton(() => _createDioClient());

  // ==================== Data Sources ====================
  // Will be added as features are implemented:
  // - Auth Local/Remote Data Sources
  // - Game Local/Remote Data Sources
  // - User Local/Remote Data Sources
  // - Audio Player/Recorder Services

  // ==================== Repositories ====================
  // Will be added as features are implemented:
  // - AuthRepository
  // - GameRepository
  // - UserRepository

  // ==================== Use Cases ====================
  // Will be added as features are implemented:
  // - Auth Use Cases (Login, Register, etc.)
  // - Game Use Cases (GetSpeeches, CreateSession, etc.)
  // - User Use Cases (GetProfile, UpdateProfile, etc.)

  // ==================== BLoCs ====================
  // BLoCs are registered as factories (new instance each time)
  // Will be added as features are implemented:
  // - AuthBloc
  // - GameBloc
  // - HistoryBloc
  // - ProfileBloc
}

/// Create configured Dio client for HTTP requests
Dio _createDioClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${AppConfig.baseUrl}${AppConfig.apiPrefix}',
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptors
  dio.interceptors.add(LogInterceptor(
    request: true,
    requestHeader: true,
    requestBody: true,
    responseHeader: true,
    responseBody: true,
    error: true,
    logPrint: (obj) {
      // Use logger package for better logging
      print('[DIO] $obj');
    },
  ));

  // Auth interceptor (will be added later)
  // dio.interceptors.add(AuthInterceptor());

  return dio;
}

/// Reset all singletons (useful for testing)
void resetDependencies() {
  getIt.reset();
}
