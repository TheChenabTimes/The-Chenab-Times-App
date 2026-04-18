import 'package:flutter/material.dart';
import 'package:the_chenab_times/screens/article_screen.dart';
import 'package:the_chenab_times/services/rss_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ArticleWebViewScreen extends StatefulWidget {
  final String url;

  const ArticleWebViewScreen({super.key, required this.url});

  @override
  State<ArticleWebViewScreen> createState() => _ArticleWebViewScreenState();
}

class _ArticleWebViewScreenState extends State<ArticleWebViewScreen> {
  final RssService _rssService = RssService();
  late final WebViewController _controller;
  int _loadingPercentage = 0;
  String _currentUrl = '';
  bool _openingSummary = false;

  bool _isChenabTimesLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host == 'thechenabtimes.com' || host.endsWith('.thechenabtimes.com');
  }

  bool _isPostUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !_isChenabTimesLink(url)) return false;
    return RegExp(r'^/\d{4}/\d{2}/\d{2}/[^/]+/?$').hasMatch(uri.path);
  }

  Future<void> _openInShort() async {
    if (_openingSummary || !_isPostUrl(_currentUrl)) return;
    setState(() => _openingSummary = true);

    try {
      final article = await _rssService.fetchArticleByUrl(_currentUrl);
      if (!mounted) return;

      if (article == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This post could not be opened in short form.'),
          ),
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ArticleScreen(articles: [article], initialIndex: 0),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open the short version right now.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _openingSummary = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingPercentage = progress;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _loadingPercentage = 100;
              _currentUrl = url;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _loadingPercentage = 0;
              _currentUrl = url;
            });
          },
          onNavigationRequest: (request) async {
            if (_isChenabTimesLink(request.url)) {
              return NavigationDecision.navigate;
            }
            final uri = Uri.tryParse(request.url);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Full Article')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            if (_isPostUrl(_currentUrl)) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _openingSummary ? null : _openInShort,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8C1D18),
                    side: const BorderSide(
                      color: Color(0xFF8C1D18),
                      width: 1.6,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    backgroundColor: const Color(0xFFFFF7EC),
                  ),
                  child: Text(
                    _openingSummary ? 'Opening...' : 'Read in Short',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8C1D18),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Back to App Home',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loadingPercentage < 100)
            LinearProgressIndicator(value: _loadingPercentage / 100.0),
        ],
      ),
    );
  }
}
