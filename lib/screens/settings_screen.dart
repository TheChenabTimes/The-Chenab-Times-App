import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_chenab_times/screens/language_selection_screen.dart';
import 'package:the_chenab_times/services/language_service.dart';
import 'package:the_chenab_times/services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer2<ThemeService, LanguageService>(
        builder: (context, themeService, languageService, child) {
          final currentTheme = _getThemeString(themeService.themeMode);
          final currentLang = _getLanguageString(languageService.appLocale);

          return ListView(
            children: <Widget>[
              _buildSectionTitle(context, 'General'),
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Theme'),
                subtitle: Text(currentTheme),
                onTap: () => _showThemeDialog(context, themeService),
              ),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Language'),
                subtitle: Text(currentLang),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const LanguageSelectionScreen(isInitialSetup: false),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Padding _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getThemeString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  String _getLanguageString(Locale locale) {
    switch (locale.languageCode) {
      case 'hi':
        return 'Hindi';
      case 'ur':
        return 'Urdu';
      case 'en':
      default:
        return 'English';
    }
  }

  Future<void> _showThemeDialog(
    BuildContext context,
    ThemeService themeService,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: themeService.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeService.setTheme(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: themeService.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeService.setTheme(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                value: ThemeMode.system,
                groupValue: themeService.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeService.setTheme(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
