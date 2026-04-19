import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_chenab_times/screens/about_us_screen.dart';
import 'package:the_chenab_times/screens/leaderboard_screen.dart';
import 'package:the_chenab_times/screens/login_screen.dart';
import 'package:the_chenab_times/screens/privacy_policy_screen.dart';
import 'package:the_chenab_times/screens/register_screen.dart';
import 'package:the_chenab_times/screens/settings_screen.dart';
import 'package:the_chenab_times/screens/terms_of_service_screen.dart';
import 'package:the_chenab_times/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// A screen that displays a list of additional options and links.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              authService.isAuthenticated
                  ? Icons.verified_user_outlined
                  : Icons.login_rounded,
            ),
            title: Text(
              authService.isAuthenticated
                  ? (authService.currentUser?.name ?? 'My Account')
                  : 'Log In',
            ),
            subtitle: Text(
              authService.isAuthenticated
                  ? (authService.currentUser?.email ?? '')
                  : 'Sync saved articles and streaks',
            ),
            onTap: authService.isAuthenticated
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
          ),
          if (!authService.isAuthenticated)
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('Create Account'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                );
              },
            ),
          if (authService.isAuthenticated)
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Log Out'),
              onTap: () async {
                await context.read<AuthService>().logout();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully.')),
                );
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Leaderboard'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaderboardScreen(),
                ),
              );
            },
          ),
          const Divider(),
          // A list tile for the "About Us" screen.
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Us'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutUsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const Divider(),
          // A list tile for the "Privacy Policy" screen.
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          const Divider(),
          // A list tile for the "Terms of Use" screen.
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Share App'),
            onTap: () {
              // TODO: Replace with your app's link
              SharePlus.instance.share(
                ShareParams(
                  text:
                      'Check out The Chenab Times app: https://play.google.com/store/apps/details?id=com.thechenabtimes.app',
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Rate Us'),
            onTap: () {
              // TODO: Replace with your app's link
              _launchUrl(
                'https://play.google.com/store/apps/details?id=com.thechenabtimes.app',
              );
            },
          ),
        ],
      ),
    );
  }

  /// Launches the given URL.
  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }
}
