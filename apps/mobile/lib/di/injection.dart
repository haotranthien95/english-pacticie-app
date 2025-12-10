import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/app_config.dart';
import '../data/datasources/local/hive_storage.dart';
import '../data/datasources/local/auth_local_datasource.dart';
import '../data/datasources/remote/auth_remote_datasource.dart';
import '../data/datasources/remote/firebase_auth_service.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/auth/login_usecase.dart';
import '../domain/usecases/auth/register_usecase.dart';
import '../domain/usecases/auth/social_login_usecase.dart';
import '../domain/usecases/auth/logout_usecase.dart';
import '../domain/usecases/auth/get_current_user_usecase.dart';
import '../presentation/blocs/auth/auth_bloc.dart';

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

  // HiveStorage
  getIt.registerLazySingleton(() => HiveStorage());

  // Firebase Auth
  getIt.registerLazySingleton(() => firebase_auth.FirebaseAuth.instance);
  
  // Google Sign In
  getIt.registerLazySingleton(() => GoogleSignIn(
    scopes: ['email', 'profile'],
  ));

  // ==================== Data Sources ====================
  
  // Auth Data Sources
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(getIt()),
  );
  
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt()),
  );
  
  getIt.registerLazySingleton<FirebaseAuthService>(
    () => FirebaseAuthServiceImpl(
      firebaseAuth: getIt(),
      googleSignIn: getIt(),
    ),
  );

  // Game Local/Remote Data Sources (will be added in Phase 3)
  // User Local/Remote Data Sources (will be added in Phase 5)
  // Audio Player/Recorder Services (will be added in Phase 3)

  // ==================== Repositories ====================
  
  // AuthRepository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      firebaseAuthService: getIt(),
    ),
  );
  
  // GameRepository (will be added in Phase 3)
  // UserRepository (will be added in Phase 5)

  // ==================== Use Cases ====================
  
  // Auth Use Cases
  getIt.registerLazySingleton(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton(() => RegisterUseCase(getIt()));
  getIt.registerLazySingleton(() => SocialLoginUseCase(getIt()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCurrentUserUseCase(getIt()));
  
  // Game Use Cases (will be added in Phase 3)
  // User Use Cases (will be added in Phase 5)

  // ==================== BLoCs ====================
  // BLoCs are registered as factories (new instance each time)
  
  // AuthBloc
  getIt.registerFactory(
    () => AuthBloc(
      loginUseCase: getIt(),
      registerUseCase: getIt(),
      socialLoginUseCase: getIt(),
      logoutUseCase: getIt(),
      getCurrentUserUseCase: getIt(),
    ),
  );
  
  // GameBloc (will be added in Phase 3)
  // HistoryBloc (will be added in Phase 4)
  // ProfileBloc (will be added in Phase 5)
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
