import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  final String termsHtml = '''
  <h1>Terms of Service - The Chenab Times App</h1>
  <p>Welcome to The Chenab Times mobile application ("App"). The App is owned and operated by The Chenab Times Foundation ("we", "us", "our").</p>
  <p>By downloading, installing, or using the App, you agree to be bound by these Terms of Service.</p>

  <h2>1. Use of the App</h2>
  <ul>
    <li>You must be at least 13 years old to use the App.</li>
    <li>You are responsible for maintaining the confidentiality of your account credentials.</li>
  </ul>

  <h2>2. Content</h2>
  <ul>
    <li>All news articles, videos, and other content are protected by copyright and are the property of The Chenab Times Foundation or its licensors.</li>
    <li>You may read, watch, and share content via built-in sharing tools. Any reproduction, redistribution, or commercial use is prohibited without prior written permission.</li>
  </ul>

  <h2>3. User Account & Saved Articles</h2>
  <ul>
    <li>Account creation is optional and used for login, saved article sync, and leaderboard participation.</li>
    <li>If you continue as a guest, saved articles stay on your device.</li>
    <li>If you log in, saved articles and synced streak information may be stored on our server and restored when you log back into your account.</li>
  </ul>

  <h2>4. Prohibited Conduct</h2>
  <p>You agree not to:</p>
  <ul>
    <li>Use the App for any unlawful purpose</li>
    <li>Interfere with or disrupt the App</li>
    <li>Attempt to gain unauthorized access to any portion of the App</li>
  </ul>

  <h2>5. Termination</h2>
  <p>We may suspend or terminate your access to the App at any time for violating these Terms.</p>

  <h2>6. Limitation of Liability</h2>
  <p>The App is provided "as is". We do not guarantee uninterrupted or error-free operation. To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, or consequential damages.</p>

  <h2>7. Governing Law</h2>
  <p>These Terms shall be governed by the laws of India. Any disputes shall be subject to the exclusive jurisdiction of courts in Doda, Jammu & Kashmir.</p>
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Html(
          data: termsHtml,
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
