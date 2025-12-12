import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hive/hive.dart';

import 'package:english_learning_app/core/constants/storage_keys.dart';
import 'package:english_learning_app/presentation/blocs/settings/settings_bloc.dart';
import 'package:english_learning_app/presentation/blocs/settings/settings_event.dart';
import 'package:english_learning_app/presentation/blocs/settings/settings_state.dart';

import 'settings_bloc_test.mocks.dart';

// Generate mocks
@GenerateMocks([Box])
void main() {
  late SettingsBloc settingsBloc;
  late MockBox mockSettingsBox;

  setUp(() {
    mockSettingsBox = MockBox();
    settingsBloc = SettingsBloc(settingsBox: mockSettingsBox);
  });

  tearDown(() {
    settingsBloc.close();
  });

  group('SettingsBloc', () {
    test('initial state should be SettingsInitial', () {
      expect(settingsBloc.state, equals(const SettingsInitial()));
    });

    group('SettingsLoadRequested', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoaded] with default values when loading succeeds',
        build: () {
          when(mockSettingsBox.get(StorageKeys.themeMode,
                  defaultValue: 'system'))
              .thenReturn('system');
          when(mockSettingsBox.get(StorageKeys.languageCode,
                  defaultValue: 'en'))
              .thenReturn('en');
          return settingsBloc;
        },
        act: (bloc) => bloc.add(const SettingsLoadRequested()),
        expect: () => [
          const SettingsLoaded(
            themeMode: ThemeMode.system,
            languageCode: 'en',
          ),
        ],
        verify: (_) {
          verify(mockSettingsBox.get(StorageKeys.themeMode,
                  defaultValue: 'system'))
              .called(1);
          verify(mockSettingsBox.get(StorageKeys.languageCode,
                  defaultValue: 'en'))
              .called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoaded] with light theme when stored',
        build: () {
          when(mockSettingsBox.get(StorageKeys.themeMode,
                  defaultValue: 'system'))
              .thenReturn('light');
          when(mockSettingsBox.get(StorageKeys.languageCode,
                  defaultValue: 'en'))
              .thenReturn('en');
          return settingsBloc;
        },
        act: (bloc) => bloc.add(const SettingsLoadRequested()),
        expect: () => [
          const SettingsLoaded(
            themeMode: ThemeMode.light,
            languageCode: 'en',
          ),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoaded] with dark theme when stored',
        build: () {
          when(mockSettingsBox.get(StorageKeys.themeMode,
                  defaultValue: 'system'))
              .thenReturn('dark');
          when(mockSettingsBox.get(StorageKeys.languageCode,
                  defaultValue: 'en'))
              .thenReturn('en');
          return settingsBloc;
        },
        act: (bloc) => bloc.add(const SettingsLoadRequested()),
        expect: () => [
          const SettingsLoaded(
            themeMode: ThemeMode.dark,
            languageCode: 'en',
          ),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoaded] with Vietnamese language when stored',
        build: () {
          when(mockSettingsBox.get(StorageKeys.themeMode,
                  defaultValue: 'system'))
              .thenReturn('system');
          when(mockSettingsBox.get(StorageKeys.languageCode,
                  defaultValue: 'en'))
              .thenReturn('vi');
          return settingsBloc;
        },
        act: (bloc) => bloc.add(const SettingsLoadRequested()),
        expect: () => [
          const SettingsLoaded(
            themeMode: ThemeMode.system,
            languageCode: 'vi',
          ),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsError] when loading fails',
        build: () {
          when(mockSettingsBox.get(StorageKeys.themeMode,
                  defaultValue: 'system'))
              .thenThrow(Exception('Storage error'));
          return settingsBloc;
        },
        act: (bloc) => bloc.add(const SettingsLoadRequested()),
        expect: () => [
          predicate<SettingsState>((state) {
            if (state is! SettingsError) return false;
            return state.message.contains('Failed to load settings');
          }),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'defaults to system theme for invalid theme value',
        build: () {
          when(mockSettingsBox.get(StorageKeys.themeMode,
                  defaultValue: 'system'))
              .thenReturn('invalid');
          when(mockSettingsBox.get(StorageKeys.languageCode,
                  defaultValue: 'en'))
              .thenReturn('en');
          return settingsBloc;
        },
        act: (bloc) => bloc.add(const SettingsLoadRequested()),
        expect: () => [
          const SettingsLoaded(
            themeMode: ThemeMode.system,
            languageCode: 'en',
          ),
        ],
      );
    });

    group('ThemeChanged', () {
      const tLoadedState = SettingsLoaded(
        themeMode: ThemeMode.system,
        languageCode: 'en',
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoaded] with light theme and saves to storage',
        build: () {
          when(mockSettingsBox.put(StorageKeys.themeMode, 'light'))
              .thenAnswer((_) async => {});
          return settingsBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) => bloc.add(const ThemeChanged(ThemeMode.light)),
        expect: () => [
          const SettingsLoaded(
            themeMode: ThemeMode.light,
            languageCode: 'en',
          ),
        ],
        verify: (_) {
          verify(mockSettingsBox.put(StorageKeys.themeMode, 'light')).called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoaded] with dark theme and saves to storage',
        build: () {
          when(mockSettingsBox.put(StorageKeys.themeMode, 'dark'))
              .thenAnswer((_) async => {});
          return settingsBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) => bloc.add(const ThemeChanged(ThemeMode.dark)),
        expect: () => [
          const SettingsLoaded(
            themeMode: ThemeMode.dark,
            languageCode: 'en',
          ),
        ],
        verify: (_) {
          verify(mockSettingsBox.put(StorageKeys.themeMode, 'dark')).called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoaded] with system theme and saves to storage',
        build: () {
          when(mockSettingsBox.put(StorageKeys.themeMode, 'system'))
              .thenAnswer((_) async => {});
          return settingsBloc;
        },
        seed: () => tLoadedState.copyWith(themeMode: ThemeMode.dark),
        act: (bloc) => bloc.add(const ThemeChanged(ThemeMode.system)),
        expect: () => [
          const SettingsLoaded(
            themeMode: ThemeMode.system,
            languageCode: 'en',
          ),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsError, SettingsLoaded] when save fails',
        build: () {
          when(mockSettingsBox.put(StorageKeys.themeMode, 'light'))
              .thenThrow(Exception('Storage error'));
          return settingsBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) => bloc.add(const ThemeChanged(ThemeMode.light)),
        expect: () => [
          predicate<SettingsState>((state) {
            if (state is! SettingsError) return false;
            return state.message.contains('Failed to change theme');
          }),
          tLoadedState, // Restores previous state
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'ignores theme change when not in SettingsLoaded state',
        build: () => settingsBloc,
        seed: () => const SettingsInitial(),
        act: (bloc) => bloc.add(const ThemeChanged(ThemeMode.light)),
        expect: () => [],
        verify: (_) {
          verifyNever(mockSettingsBox.put(any, any));
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'preserves language code when changing theme',
        build: () {
          when(mockSettingsBox.put(StorageKeys.themeMode, 'dark'))
              .thenAnswer((_) async => {});
          return settingsBloc;
        },
        seed: () => const SettingsLoaded(
          themeMode: ThemeMode.light,
          languageCode: 'vi',
        ),
        act: (bloc) => bloc.add(const ThemeChanged(ThemeMode.dark)),
        expect: () => [
          const SettingsLoaded(
            themeMode: ThemeMode.dark,
            languageCode: 'vi', // Language preserved
          ),
        ],
      );
    });

    group('LanguageChanged', () {
      const tLoadedState = SettingsLoaded(
        themeMode: ThemeMode.system,
        languageCode: 'en',
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoaded] with Vietnamese and saves to storage',
        build: () {
          when(mockSettingsBox.put(StorageKeys.languageCode, 'vi'))
              .thenAnswer((_) async => {});
          return settingsBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) => bloc.add(const LanguageChanged('vi')),
        expect: () => [
          const SettingsLoaded(
            themeMode: ThemeMode.system,
            languageCode: 'vi',
          ),
        ],
        verify: (_) {
          verify(mockSettingsBox.put(StorageKeys.languageCode, 'vi')).called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoaded] with English and saves to storage',
        build: () {
          when(mockSettingsBox.put(StorageKeys.languageCode, 'en'))
              .thenAnswer((_) async => {});
          return settingsBloc;
        },
        seed: () => tLoadedState.copyWith(languageCode: 'vi'),
        act: (bloc) => bloc.add(const LanguageChanged('en')),
        expect: () => [
          const SettingsLoaded(
            themeMode: ThemeMode.system,
            languageCode: 'en',
          ),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsError, SettingsLoaded] for unsupported language',
        build: () => settingsBloc,
        seed: () => tLoadedState,
        act: (bloc) => bloc.add(const LanguageChanged('fr')),
        expect: () => [
          const SettingsError('Unsupported language'),
          tLoadedState, // Restores previous state
        ],
        verify: (_) {
          verifyNever(mockSettingsBox.put(StorageKeys.languageCode, any));
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsError, SettingsLoaded] when save fails',
        build: () {
          when(mockSettingsBox.put(StorageKeys.languageCode, 'vi'))
              .thenThrow(Exception('Storage error'));
          return settingsBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) => bloc.add(const LanguageChanged('vi')),
        expect: () => [
          predicate<SettingsState>((state) {
            if (state is! SettingsError) return false;
            return state.message.contains('Failed to change language');
          }),
          tLoadedState, // Restores previous state
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'ignores language change when not in SettingsLoaded state',
        build: () => settingsBloc,
        seed: () => const SettingsInitial(),
        act: (bloc) => bloc.add(const LanguageChanged('vi')),
        expect: () => [],
        verify: (_) {
          verifyNever(mockSettingsBox.put(any, any));
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'preserves theme mode when changing language',
        build: () {
          when(mockSettingsBox.put(StorageKeys.languageCode, 'vi'))
              .thenAnswer((_) async => {});
          return settingsBloc;
        },
        seed: () => const SettingsLoaded(
          themeMode: ThemeMode.dark,
          languageCode: 'en',
        ),
        act: (bloc) => bloc.add(const LanguageChanged('vi')),
        expect: () => [
          const SettingsLoaded(
            themeMode: ThemeMode.dark, // Theme preserved
            languageCode: 'vi',
          ),
        ],
      );
    });

    group('Multiple changes', () {
      const tLoadedState = SettingsLoaded(
        themeMode: ThemeMode.system,
        languageCode: 'en',
      );

      blocTest<SettingsBloc, SettingsState>(
        'handles theme change followed by language change',
        build: () {
          when(mockSettingsBox.put(StorageKeys.themeMode, 'dark'))
              .thenAnswer((_) async => {});
          when(mockSettingsBox.put(StorageKeys.languageCode, 'vi'))
              .thenAnswer((_) async => {});
          return settingsBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) async {
          bloc.add(const ThemeChanged(ThemeMode.dark));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const LanguageChanged('vi'));
        },
        expect: () => [
          const SettingsLoaded(themeMode: ThemeMode.dark, languageCode: 'en'),
          const SettingsLoaded(themeMode: ThemeMode.dark, languageCode: 'vi'),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'handles rapid theme changes',
        build: () {
          when(mockSettingsBox.put(StorageKeys.themeMode, any))
              .thenAnswer((_) async => {});
          return settingsBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) {
          bloc.add(const ThemeChanged(ThemeMode.light));
          bloc.add(const ThemeChanged(ThemeMode.dark));
          bloc.add(const ThemeChanged(ThemeMode.system));
        },
        verify: (_) {
          verify(mockSettingsBox.put(StorageKeys.themeMode, any))
              .called(greaterThan(0));
        },
      );
    });

    group('Edge cases', () {
      const tLoadedState = SettingsLoaded(
        themeMode: ThemeMode.system,
        languageCode: 'en',
      );

      blocTest<SettingsBloc, SettingsState>(
        'handles same theme change (no-op but still saves)',
        build: () {
          when(mockSettingsBox.put(StorageKeys.themeMode, 'system'))
              .thenAnswer((_) async => {});
          return settingsBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) => bloc.add(const ThemeChanged(ThemeMode.system)),
        expect: () => [
          const SettingsLoaded(
            themeMode: ThemeMode.system,
            languageCode: 'en',
          ),
        ],
        verify: (_) {
          verify(mockSettingsBox.put(StorageKeys.themeMode, 'system'))
              .called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'handles same language change (no-op but still saves)',
        build: () {
          when(mockSettingsBox.put(StorageKeys.languageCode, 'en'))
              .thenAnswer((_) async => {});
          return settingsBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) => bloc.add(const LanguageChanged('en')),
        expect: () => [
          const SettingsLoaded(
            themeMode: ThemeMode.system,
            languageCode: 'en',
          ),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'validates language code case-insensitively',
        build: () => settingsBloc,
        seed: () => tLoadedState,
        act: (bloc) => bloc.add(const LanguageChanged('FR')),
        expect: () => [
          const SettingsError('Unsupported language'),
          tLoadedState,
        ],
      );
    });
  });
}
