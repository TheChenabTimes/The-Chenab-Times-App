import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  final String policyHtml = '''
    <h1>Privacy Policy - The Chenab Times App</h1>
    <p>The Chenab Times Foundation ("we", "us", "our") respects your privacy. This Privacy Policy explains how the official The Chenab Times mobile app handles your information.</p>

    <h2>1. Information We Do NOT Collect</h2>
    <ul>
        <li>We do NOT sell your personal data or use invasive analytics to track your individual reading behavior.</li>
        <li>If you use the app without logging in, your saved articles remain on your device only.</li>
        <li>We do NOT use analytics tools that track individual users.</li>
    </ul>

    <h2>2. Information We Collect (Only When You Create an Account)</h2>
    <p>When you create an optional account to sync app features:</p>
    <ul>
        <li>Name</li>
        <li>Email address</li>
        <li>Password, handled securely by our authentication system and never shown back to you in plain text</li>
        <li>Saved articles linked to your account</li>
        <li>Game streak totals that you choose to sync for leaderboard display</li>
    </ul>

    <h2>3. How We Use the Limited Data</h2>
    <ul>
        <li>To create and maintain your optional account</li>
        <li>To restore your saved articles when you log in</li>
        <li>To sync your game streak to the in-app leaderboard</li>
        <li>To keep your session active on your device until you log out or your token expires</li>
    </ul>

    <h2>4. Data Storage & Security</h2>
    <ul>
        <li>Guest saved articles remain on your device.</li>
        <li>If you log in, your saved articles and synced streak information are stored on our server so they can be restored to your account.</li>
        <li>Authentication tokens are stored securely on your device.</li>
        <li>We take reasonable steps to protect account-related data in transit and at rest.</li>
    </ul>

    <h2>5. No Sharing with Third Parties</h2>
    <p>We do not sell, rent, or share personal information with third parties for advertising.</p>

    <h2>6. Push Notifications (Optional)</h2>
    <p>If you enable notifications, we send only news alerts. No personal profile data is attached to those notifications.</p>

    <h2>7. Children's Privacy</h2>
    <p>The App is not directed at children under 13. We do not knowingly collect data from children.</p>

    <h2>8. Changes to This Policy</h2>
    <p>We may update this Privacy Policy. Changes will be posted in the app and on our website.</p>

    <h2>Contact Us</h2>
    <p>If you have any questions, you can contact us at contact@thechenabtimes.com.</p>
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Html(
          data: policyHtml,
          style: {
            'h1': Style(fontSize: FontSize.xxLarge),
            'h2': Style(
              fontSize: FontSize.xLarge,
              fontWeight: FontWeight.bold,
              margin: Margins.only(top: 16),
            ),
            'p': Style(
              fontSize: FontSize.large,
              lineHeight: LineHeight.em(1.5),
            ),
            'li': Style(
              fontSize: FontSize.large,
              lineHeight: LineHeight.em(1.5),
            ),
          },
        ),
      ),
    );
  }
}
