import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_chenab_times/screens/language_selection_screen.dart';
import 'package:the_chenab_times/main.dart'; // For MainScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // 1. Wait for logo display
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool onboardingComplete =
          prefs.getBool('onboarding_complete') ?? false;

      if (!mounted) return;

      if (onboardingComplete) {
        // User has already set up app -> Go to Main
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        // First time user -> Go to Language Selection
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const LanguageSelectionScreen(isInitialSetup: true),
          ),
        );
      }
    } catch (e) {
      debugPrint("Splash Error: $e");
      // Fallback -> Go to Language Selection
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const LanguageSelectionScreen(isInitialSetup: true),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('lib/images/appIco.png', height: 150, width: 150),
          ],
        ),
      ),
    );
  }
}
