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
              "Privacy Policy - The Chenab Times App",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              "The Chenab Times Foundation (\"we\", \"us\", \"our\") respects your privacy. "
              "This Privacy Policy explains how the official The Chenab Times mobile app handles your information.",
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
            SizedBox(height: 20),
            Text(
              "1. Information We Do NOT Collect",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "• We do NOT sell your personal data or use invasive analytics to track your individual reading behavior.\n"
              "• If you use the app without logging in, your saved articles remain on your device only.\n"
              "• We do NOT use analytics tools that track individual users.",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 20),
            Text(
              "2. Information We Collect (Only When You Create an Account)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "When you create an optional account to sync app features:\n\n"
              "• Name\n"
              "• Email address\n"
              "• Password, handled securely by our authentication system and never shown back to you in plain text\n"
              "• Saved articles linked to your account\n"
              "• Game streak totals that you choose to sync for leaderboard display",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 20),
            Text(
              "3. How We Use the Limited Data",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "• To create and maintain your optional account\n"
              "• To restore your saved articles when you log in\n"
              "• To sync your game streak to the in-app leaderboard\n"
              "• To keep your session active on your device until you log out or your token expires",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 20),
            Text(
              "4. Data Storage & Security",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "• Guest saved articles remain on your device.\n"
              "• If you log in, your saved articles and synced streak information are stored on our server so they can be restored to your account.\n"
              "• Authentication tokens are stored securely on your device.\n"
              "• We take reasonable steps to protect account-related data in transit and at rest.",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 20),
            Text(
              "5. No Sharing with Third Parties",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "We do not sell, rent, or share personal information with third parties for advertising.",
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
            SizedBox(height: 20),
            Text(
              "6. Push Notifications (Optional)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "If you enable notifications, we send only news alerts. No personal profile data is attached to those notifications.",
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
            SizedBox(height: 20),
            Text(
              "7. Children's Privacy",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "The App is not directed at children under 13. We do not knowingly collect data from children.",
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
            SizedBox(height: 20),
            Text(
              "8. Changes to This Policy",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "We may update this Privacy Policy. Changes will be posted in the app and on our website.",
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
