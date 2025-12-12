import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/storage_keys.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// BLoC for managing app settings (theme, language)
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final Box settingsBox;

  SettingsBloc({required this.settingsBox}) : super(const SettingsInitial()) {
    on<SettingsLoadRequested>(_onSettingsLoadRequested);
    on<ThemeChanged>(_onThemeChanged);
    on<LanguageChanged>(_onLanguageChanged);
  }

  Future<void> _onSettingsLoadRequested(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      // Load theme mode from storage
      final themeModeString = settingsBox.get(
        StorageKeys.themeMode,
        defaultValue: 'system',
      ) as String;

      final themeMode = _parseThemeMode(themeModeString);

      // Load language code from storage
      final languageCode = settingsBox.get(
        StorageKeys.languageCode,
        defaultValue: 'en',
      ) as String;

      emit(SettingsLoaded(
        themeMode: themeMode,
        languageCode: languageCode,
      ));
    } catch (e) {
      emit(SettingsError('Failed to load settings: $e'));
    }
  }

  Future<void> _onThemeChanged(
    ThemeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;

      try {
        // Save to storage
        await settingsBox.put(
          StorageKeys.themeMode,
          _themeModeToString(event.themeMode),
        );

        // Emit new state
        emit(currentState.copyWith(themeMode: event.themeMode));
      } catch (e) {
        emit(SettingsError('Failed to change theme: $e'));
        // Restore previous state
        emit(currentState);
      }
    }
  }

  Future<void> _onLanguageChanged(
    LanguageChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;

      try {
        // Validate language code
        if (!['en', 'vi'].contains(event.languageCode)) {
          emit(const SettingsError('Unsupported language'));
          emit(currentState);
          return;
        }

        // Save to storage
        await settingsBox.put(
          StorageKeys.languageCode,
          event.languageCode,
        );

        // Emit new state
        emit(currentState.copyWith(languageCode: event.languageCode));
      } catch (e) {
        emit(SettingsError('Failed to change language: $e'));
        // Restore previous state
        emit(currentState);
      }
    }
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
