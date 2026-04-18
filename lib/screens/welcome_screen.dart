import 'package:flutter/material.dart';
import 'dart:async';
import 'package:the_chenab_times/screens/terms_and_conditions_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _headingController;
  late Animation<Offset> _headingAnimation;

  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  late AnimationController _buttonController;
  late Animation<Offset> _buttonAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Heading: Slides down from off-screen top
    _headingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _headingAnimation =
        Tween<Offset>(
          begin: const Offset(0, -1.5), // Start above the screen
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _headingController,
            curve: Curves.easeInOutSine,
          ),
        );

    // 2. Logo: Scale/Fade in at the center
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // 3. Button: Slides up from off-screen bottom
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _buttonAnimation =
        Tween<Offset>(
          begin: const Offset(0, 2.0), // Start below the screen
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _buttonController,
            curve: Curves.easeOutCubic,
          ),
        );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Start heading animation almost immediately
    await Future.delayed(const Duration(milliseconds: 100));
    _headingController.forward();

    // Wait for heading to settle, then show logo
    await Future.delayed(const Duration(milliseconds: 700));
    _logoController.forward();

    // Final flourish: bring up the button
    await Future.delayed(const Duration(milliseconds: 800));
    _buttonController.forward();
  }

  @override
  void dispose() {
    _headingController.dispose();
    _logoController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Setting a clean background
      body: SafeArea(
        top: false, // Allows heading to touch the very top if desired
        child: Stack(
          children: [
            Column(
              children: <Widget>[
                // Animated Heading - Stays at the top
                SlideTransition(
                  position: _headingAnimation,
                  child: Image.asset(
                    'assets/welcome_heading.png',
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.contain,
                  ),
                ),

                // Centered Logo Area
                Expanded(
                  child: Center(
                    child: ScaleTransition(
                      scale: _logoAnimation,
                      child: Image.asset(
                        'lib/images/applogo.png',
                        height: 180, // Slightly larger for impact
                      ),
                    ),
                  ),
                ),

                // Bottom Button Area
                SlideTransition(
                  position: _buttonAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const TermsAndConditionsScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'CONTINUE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
