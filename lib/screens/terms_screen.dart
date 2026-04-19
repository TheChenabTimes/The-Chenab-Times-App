import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_chenab_times/main.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _isAgeConfirmed = false;
  bool _areTermsAccepted = false;

  void _onNext() async {
    if (_isAgeConfirmed && _areTermsAccepted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('terms_accepted', true);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _isAgeConfirmed && _areTermsAccepted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Terms of Service - The Chenab Times App",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Welcome to The Chenab Times mobile application (\"App\"). The App is owned "
                      "and operated by The Chenab Times Foundation (\"we\", \"us\", \"our\").\n\n"
                      "By downloading, installing, or using the App, you agree to be bound by "
                      "these Terms of Service.",
                      style: TextStyle(fontSize: 16, height: 1.4),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "1. Use of the App",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "• You must be at least 13 years old to use the App.\n"
                      "• You are responsible for maintaining the confidentiality of your account credentials.",
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "2. Content",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "• All news articles, videos, and other content are protected by copyright and are "
                      "the property of The Chenab Times Foundation or its licensors.\n"
                      "• You may read, watch, and share content via built-in sharing tools. Any reproduction, "
                      "redistribution, or commercial use is prohibited without prior written permission.",
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "3. User Account & Saved Articles",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "• Account creation is optional and used for login, saved article sync, and leaderboard participation.\n"
                      "• If you continue as a guest, saved articles stay on your device.\n"
                      "• If you log in, saved articles and synced streak information may be stored on our server and restored when you log back into your account.",
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "4. Prohibited Conduct",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "You agree not to:\n"
                      "• Use the App for any unlawful purpose\n"
                      "• Interfere with or disrupt the App\n"
                      "• Attempt to gain unauthorized access to any portion of the App",
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "5. Termination",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "We may suspend or terminate your access to the App at any time for violating these Terms.",
                      style: TextStyle(fontSize: 16, height: 1.4),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "6. Limitation of Liability",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "The App is provided \"as is\". We do not guarantee uninterrupted or error-free operation. "
                      "To the maximum extent permitted by law, we shall not be liable for any indirect, "
                      "incidental, or consequential damages.",
                      style: TextStyle(fontSize: 16, height: 1.4),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "7. Governing Law",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "These Terms shall be governed by the laws of India. Any disputes shall be subject to the "
                      "exclusive jurisdiction of courts in Doda, Jammu & Kashmir.",
                      style: TextStyle(fontSize: 16, height: 1.4),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "8. Changes to Terms",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "We may update these Terms from time to time. Continued use of the App after changes "
                      "constitutes acceptance of the new Terms.",
                      style: TextStyle(fontSize: 16, height: 1.4),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Contact: contact+legal@thechenabtimes.com",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: _isAgeConfirmed,
                  onChanged: (value) {
                    setState(() {
                      _isAgeConfirmed = value ?? false;
                    });
                  },
                ),
                const Expanded(child: Text('I am 13 years old or above.')),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: _areTermsAccepted,
                  onChanged: (value) {
                    setState(() {
                      _areTermsAccepted = value ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    'I have read and agree to the Terms and Conditions.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (canProceed)
              ElevatedButton(
                onPressed: _onNext,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Next'),
              )
            else
              const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
