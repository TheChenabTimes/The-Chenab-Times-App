import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_chenab_times/main.dart';
import 'package:the_chenab_times/l10n/app_localizations.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _agreedToTerms = false;
  bool _isAgeConfirmed = false;

  bool get _canProceed => _agreedToTerms && _isAgeConfirmed;

  Future<void> _onProceed() async {
    if (_canProceed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.translate('terms_title'))),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Terms of Service – The Chenab Times App",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Welcome to The Chenab Times mobile application (“App”). The App is owned "
                    "and operated by The Chenab Times Foundation (“we”, “us”, “our”).\n\n"
                    "By downloading, installing, or using the App, you agree to be bound by "
                    "these Terms of Service.",
                    style: TextStyle(fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "1. Use of the App",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "• You must be at least 13 years old to use the App.\n"
                    "• You are responsible for maintaining the confidentiality of your account credentials.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "2. Content",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "• All news articles, videos, and other content are protected by copyright and are "
                    "the property of The Chenab Times Foundation or its licensors.\n"
                    "• You may read, watch, and share content via built-in sharing tools. Any reproduction, "
                    "redistribution, or commercial use is prohibited without prior written permission.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  CheckboxListTile(
                    title: Text(localizations.translate('terms_agreement')),
                    value: _agreedToTerms,
                    onChanged: (bool? value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: Text(localizations.translate('age_agreement')),
                    value: _isAgeConfirmed,
                    onChanged: (bool? value) {
                      setState(() {
                        _isAgeConfirmed = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
          if (_canProceed)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _onProceed,
                child: Text(localizations.translate('proceed')),
              ),
            ),
        ],
      ),
    );
  }
}
