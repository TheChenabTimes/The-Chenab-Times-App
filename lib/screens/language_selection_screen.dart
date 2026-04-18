import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_chenab_times/screens/welcome_screen.dart';
import 'package:the_chenab_times/services/language_service.dart';
import 'package:the_chenab_times/utils/app_status_handler.dart';

/// A class that represents a language.
class Language {
  final String name;
  final String code;

  Language(this.name, this.code);
}

/// A screen that allows the user to select their preferred language.
class LanguageSelectionScreen extends StatefulWidget {
  /// A flag to indicate if the screen is being used for the initial setup.
  final bool isInitialSetup;

  const LanguageSelectionScreen({super.key, this.isInitialSetup = false});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  // A list of the supported languages.
  final List<Language> _languages = [
    Language('English', 'en'),
    Language('हिंदी', 'hi'),
    Language('اردو', 'ur'),
    Language('ਪੰਜਾਬੀ', 'pa'),
    Language('ગુજરાતી', 'gu'),
    Language('मराठी', 'mr'),
    Language('বাংলা', 'bn'),
    Language('தமிழ்', 'ta'),
    Language('తెలుగు', 'te'),
    Language('ಕನ್ನಡ', 'kn'),
    Language('മലയാളം', 'ml'),
    Language('Español', 'es'),
    Language('Français', 'fr'),
    Language('Deutsch', 'de'),
  ];

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final String currentLangCode = languageService.appLocale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Language'),
        centerTitle: true,
        // Don't show the back button if this is the initial setup.
        automaticallyImplyLeading: !widget.isInitialSetup,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Choose your preferred language",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _languages.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final language = _languages[index];
                final isSelected = language.code == currentLangCode;

                return ListTile(
                  selected: isSelected,
                  title: Text(
                    language.name,
                    style: const TextStyle(fontSize: 18),
                  ),
                  trailing: isSelected ? const Icon(Icons.check_circle) : null,
                  onTap: () {
                    // Set the language and, if not in the initial setup, pop the
                    // screen and show a toast.
                    languageService.setLanguage(language.code);
                    if (!widget.isInitialSetup) {
                      AppStatusHandler.showStatusToast(
                        message: 'Language changed successfully',
                        type: StatusType.success,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            ),
          ),
          // If this is the initial setup, show a "Next" button.
          if (widget.isInitialSetup)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  );
                },
                child: const Text('Continue'),
              ),
            ),
        ],
      ),
    );
  }
}
