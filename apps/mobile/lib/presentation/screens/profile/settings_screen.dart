import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../di/injection.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';

/// Screen for app settings (theme, language)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<SettingsBloc>()..add(const SettingsLoadRequested()),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is! SettingsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Appearance Section
              const Text(
                'Appearance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Theme Mode Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.brightness_6,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Theme',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildThemeOptions(context, state.themeMode),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Language Section
              const Text(
                'Language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Language Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.language,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'App Language',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLanguageOptions(context, state.languageCode),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // About Section
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeOptions(BuildContext context, ThemeMode currentMode) {
    return Column(
      children: [
        RadioListTile<ThemeMode>(
          title: const Text('Light'),
          subtitle: const Text('Always use light theme'),
          value: ThemeMode.light,
          groupValue: currentMode,
          onChanged: (value) {
            if (value != null) {
              context.read<SettingsBloc>().add(ThemeChanged(value));
            }
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Dark'),
          subtitle: const Text('Always use dark theme'),
          value: ThemeMode.dark,
          groupValue: currentMode,
          onChanged: (value) {
            if (value != null) {
              context.read<SettingsBloc>().add(ThemeChanged(value));
            }
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text('System'),
          subtitle: const Text('Follow system theme'),
          value: ThemeMode.system,
          groupValue: currentMode,
          onChanged: (value) {
            if (value != null) {
              context.read<SettingsBloc>().add(ThemeChanged(value));
            }
          },
        ),
      ],
    );
  }

  Widget _buildLanguageOptions(BuildContext context, String currentLanguage) {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('English'),
          subtitle: const Text('English'),
          value: 'en',
          groupValue: currentLanguage,
          onChanged: (value) {
            if (value != null) {
              context.read<SettingsBloc>().add(LanguageChanged(value));
            }
          },
        ),
        RadioListTile<String>(
          title: const Text('Vietnamese'),
          subtitle: const Text('Tiếng Việt'),
          value: 'vi',
          groupValue: currentLanguage,
          onChanged: (value) {
            if (value != null) {
              context.read<SettingsBloc>().add(LanguageChanged(value));
            }
          },
        ),
      ],
    );
  }
}
