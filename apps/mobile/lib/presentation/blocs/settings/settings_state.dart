import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// States for Settings BLoC
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Settings loaded
class SettingsLoaded extends SettingsState {
  final ThemeMode themeMode;
  final String languageCode;

  const SettingsLoaded({
    required this.themeMode,
    required this.languageCode,
  });

  @override
  List<Object?> get props => [themeMode, languageCode];

  SettingsLoaded copyWith({
    ThemeMode? themeMode,
    String? languageCode,
  }) {
    return SettingsLoaded(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

/// Error loading settings
class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
