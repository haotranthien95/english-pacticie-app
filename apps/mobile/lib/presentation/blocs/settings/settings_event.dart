import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Events for Settings BLoC
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load settings
class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested();
}

/// Event to change theme
class ThemeChanged extends SettingsEvent {
  final ThemeMode themeMode;

  const ThemeChanged(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

/// Event to change language
class LanguageChanged extends SettingsEvent {
  final String languageCode;

  const LanguageChanged(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}
