import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy Policy")),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Privacy Policy – The Chenab Times App",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 16),

            Text(
              "The Chenab Times Foundation (“we”, “us”, “our”) respects your privacy. "
              "This Privacy Policy explains how the official The Chenab Times mobile app "
              "handles (or does not handle) your information.",
              style: TextStyle(fontSize: 16, height: 1.4),
            ),

            SizedBox(height: 20),

            // Section 1
            Text(
              "1. Information We Do NOT Collect",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "• We do NOT collect, store, or transmit your saved articles, reading history, "
              "or any personal reading preferences.\n"
              "• All saved articles and bookmarks are stored only on your device. We have zero "
              "access to this data.\n"
              "• We do NOT use analytics tools that track individual users.",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),

            SizedBox(height: 20),

            // Section 2
            Text(
              "2. Information We Collect (Only When You Create an Account)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "When you create an optional account for backup/restore of saved articles:\n\n"
              "• Email address (used only for account creation and password reset)\n"
              "• Encrypted backup of your saved articles list (stored only for restore/transfer; "
              "we cannot decrypt or read it)",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),

            SizedBox(height: 20),

            // Section 3
            Text(
              "3. How We Use the Limited Data",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "• Email: only to send password reset links (if requested)\n"
              "• Encrypted backup: only to restore your saved list when you log in on the same "
              "or a new device",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),

            SizedBox(height: 20),

            // Section 4
            Text(
              "4. Data Storage & Security",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "• Your saved articles never leave your phone unless you explicitly choose to back "
              "them up.\n"
              "• Backup data is end-to-end encrypted. Even our team cannot access it.",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),

            SizedBox(height: 20),

            // Section 5
            Text(
              "5. No Sharing with Third Parties",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "We do not sell, rent, or share any personal information with third parties.",
              style: TextStyle(fontSize: 16, height: 1.4),
            ),

            SizedBox(height: 20),

            // Section 6
            Text(
              "6. Push Notifications (Optional)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "If you enable notifications, we send only news alerts. No personal data is attached.",
              style: TextStyle(fontSize: 16, height: 1.4),
            ),

            SizedBox(height: 20),

            // Section 7
            Text(
              "7. Children’s Privacy",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "The App is not directed at children under 13. We do not knowingly collect data "
              "from children.",
              style: TextStyle(fontSize: 16, height: 1.4),
            ),

            SizedBox(height: 20),

            // Section 8
            Text(
              "8. Changes to This Policy",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "We may update this Privacy Policy. Changes will be posted in the App and on our website.",
              style: TextStyle(fontSize: 16, height: 1.4),
            ),

            SizedBox(height: 20),

            Text(
              "Contact Us\ncontact+privacy@thechenabtimes.com",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
