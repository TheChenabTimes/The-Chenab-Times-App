import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  final String policyHtml = '''
    <h1>Privacy Policy – The Chenab Times App</h1>
    <p>The Chenab Times Foundation (“we”, “us”, “our”) respects your privacy. This Privacy Policy explains how the official The Chenab Times mobile app handles (or does not handle) your information.</p>

    <h2>1. Information We Do NOT Collect</h2>
    <ul>
        <li>We do NOT collect, store, or transmit your saved articles, reading history, or any personal reading preferences.</li>
        <li>All saved articles and bookmarks are stored only on your device. We have zero access to this data.</li>
        <li>We do NOT use analytics tools that track individual users.</li>
    </ul>

    <h2>2. Information We Collect (Only When You Create an Account)</h2>
    <p>When you create an optional account for backup/restore of saved articles:</p>
    <ul>
        <li>Email address (used only for account creation and password reset)</li>
        <li>Encrypted backup of your saved articles list (stored only for restore/transfer; we cannot decrypt or read it)</li>
    </ul>

    <h2>3. How We Use the Limited Data</h2>
    <ul>
        <li>Email: only to send password reset links (if requested)</li>
        <li>Encrypted backup: only to restore your saved list when you log in on the same or a new device</li>
    </ul>

    <h2>4. Data Storage & Security</h2>
    <ul>
        <li>Your saved articles never leave your phone unless you explicitly choose to back them up.</li>
        <li>Backup data is end-to-end encrypted. Even our team cannot access it.</li>
    </ul>

    <h2>5. No Sharing with Third Parties</h2>
    <p>We do not sell, rent, or share any personal information with third parties.</p>

    <h2>6. Push Notifications (Optional)</h2>
    <p>If you enable notifications, we send only news alerts. No personal data is attached.</p>

    <h2>7. Children’s Privacy</h2>
    <p>The App is not directed at children under 13. We do not knowingly collect data from children.</p>

    <h2>8. Changes to This Policy</h2>
    <p>We may update this Privacy Policy. Changes will be posted in the App and on our website.</p>

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
