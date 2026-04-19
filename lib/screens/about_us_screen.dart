import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  final String aboutUsHtml = '''
    <h1>About Us - The Chenab Times App</h1>
    <h2>Born in the mountains, built for the nation.</h2>
    <p>The Chenab Times began in July 2017 as a small social media page run single-handedly by journalist Anzer Ayoob from a remote corner of Thathri in the Chenab Valley, Jammu & Kashmir. At a time when the region had little or no voice in mainstream media, we started telling the stories that mattered - stories of forgotten roads, endangered languages, unheard voices, and the raw beauty of the Himalayas.</p>
    <p>From that one page, we grew into Jammu & Kashmir's most trusted independent digital news platform and the strongest voice of the Chenab Valley (Doda, Kishtwar, Ramban). Today, we bring you not just hyper-local stories, but credible national and international news - fast, fair, and fearless.</p>

    <h2>Why this app?</h2>
    <p>In an age of information overload, we believe news should respect your time. Every article in this app is deliberately short (100-150 words) so you can stay informed in seconds, not minutes.</p>

    <h2>What we stand for</h2>
    <ul>
        <li>Quick, truthful, and unbiased reporting</li>
        <li>Protection of privacy - guest saved articles stay on your phone, and account-based sync happens only when you log in</li>
        <li>Giving voice to the voiceless, from mountain villages to metropolitan cities</li>
    </ul>

    <h2>Our promise</h2>
    <p>No paywalls. No data mining. No selling your information. Just honest journalism, delivered straight to your pocket.</p>

    <h2>The Team</h2>
    <p>Led by Founder & Editor-in-Chief Anzer Ayoob, supported by a passionate team of reporters, video journalists, translators, and tech enthusiasts who work from the ground - because real stories do not come from newsrooms, they come from the streets.</p>
    <p>From the banks of the Chenab River to every corner of India and beyond - thank you for trusting The Chenab Times.</p>
    <p>We are small, but we are fearless. We are local, but we are everywhere.</p>

    <p><b>Team The Chenab Times | contact@thechenabtimes.com</b></p>
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Html(
          data: aboutUsHtml,
          style: {
            'h1': Style(
              fontSize: FontSize.xxLarge,
              fontWeight: FontWeight.normal,
            ),
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
            'b': Style(fontWeight: FontWeight.bold),
          },
        ),
      ),
    );
  }
}
