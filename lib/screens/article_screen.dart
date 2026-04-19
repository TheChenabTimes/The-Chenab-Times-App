import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:the_chenab_times/services/saved_articles_provider.dart';
import 'package:the_chenab_times/utils/app_status_handler.dart';
import '../models/article_model.dart';
import '../services/summarization_service.dart';
import 'article_webview_screen.dart';
import '../utils/html_helper.dart';

final ThemeData lightTheme = ThemeData(
  primarySwatch: Colors.red,
  brightness: Brightness.light,
  useMaterial3: true,
);

class ArticleScreen extends StatefulWidget {
  final List<Article> articles;
  final int initialIndex;

  const ArticleScreen({
    super.key,
    required this.articles,
    required this.initialIndex,
  });

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  static const _logoAsset = 'lib/images/appheading.png';
  late PageController _pageController;
  late int _currentIndex;
  final _screenshotController = ScreenshotController();

  Article get _currentArticle => widget.articles[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _toggleSave(SavedArticlesProvider provider) async {
    try {
      final isSaved = provider.isArticleSaved(_currentArticle.link);
      if (!isSaved) {
        await provider.saveArticle(_currentArticle);
        AppStatusHandler.showStatusToast(message: 'Article saved', type: StatusType.success);
      } else {
        await provider.deleteArticle(_currentArticle.link!);
        AppStatusHandler.showStatusToast(message: 'Removed from saved articles', type: StatusType.info);
      }
    } catch (e) {
      AppStatusHandler.showStatusToast(
        message: '$e',
        type: StatusType.error,
      );
    }
  }

  Future<void> _shareArticle() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Lottie.asset('assets/loading.json', width: 150, height: 150),
      ),
    );

    try {
      final summary = await SummarizationService.instance.summarizeArticle(_currentArticle.content ?? _currentArticle.excerpt ?? '', articleLink: _currentArticle.link);
      Uint8List? imageBytes;
      if (_currentArticle.imageUrl != null) {
        try {
          final response = await http.get(Uri.parse(_currentArticle.imageUrl!));
          if (response.statusCode == 200) {
            imageBytes = response.bodyBytes;
          }
        } catch (e) {
          log('Could not fetch image: $e');
        }
      }

      final Uint8List image = await _screenshotController.captureFromWidget(
        Theme(
          data: lightTheme,
          child: ScreenshotWidget(article: _currentArticle, summary: summary, imageBytes: imageBytes),
        ),
        delay: const Duration(milliseconds: 2000),
      );

      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Share Screenshot'),
            content: Image.memory(image),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Share')),
            ],
          ),
        );

        if (confirmed == true) {
          final directory = await getTemporaryDirectory();
          final path = '${directory.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
          final imageFile = File(path);
          await imageFile.writeAsBytes(image);
          final cleanTitle = HtmlHelper.stripAndUnescape(_currentArticle.title).trim();
          final articleUrl = _currentArticle.link ?? '';

          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(path)],
              text: '$cleanTitle\n\nRead more:\n\n$articleUrl',
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      AppStatusHandler.showStatusToast(message: 'Failed to create screenshot: $e', type: StatusType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedArticlesProvider>(
      builder: (context, savedArticlesProvider, child) {
        final isSaved = savedArticlesProvider.isArticleSaved(_currentArticle.link);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Image.asset(_logoAsset, height: 38),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Save article',
                icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border_outlined),
                onPressed: () => _toggleSave(savedArticlesProvider),
              ),
              IconButton(
                tooltip: 'Share article',
                icon: const Icon(Icons.share_outlined),
                onPressed: _shareArticle,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: PageView.builder(
            controller: _pageController,
            itemCount: widget.articles.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) => _ArticlePage(key: ValueKey(widget.articles[index].link), article: widget.articles[index]),
          ),
        );
      },
    );
  }
}

class _ArticlePage extends StatefulWidget {
  final Article article;
  const _ArticlePage({super.key, required this.article});

  @override
  __ArticlePageState createState() => __ArticlePageState();
}

class __ArticlePageState extends State<_ArticlePage> {
  String _summary = '';
  bool _isLoadingSummary = true;
  bool _summaryError = false;

  @override
  void initState() {
    super.initState();
    _generateSummary();
  }

  Future<void> _generateSummary() async {
    if (!mounted) return;
    setState(() { _isLoadingSummary = true; _summaryError = false; });
    try {
      final text = widget.article.content ?? widget.article.excerpt ?? '';
      final summary = await SummarizationService.instance.summarizeArticle(text, articleLink: widget.article.link);
      if (mounted) setState(() { _summary = summary; _isLoadingSummary = false; });
    } catch (e) {
      if (mounted) setState(() { _summaryError = true; _isLoadingSummary = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.article.imageUrl ?? widget.article.thumbnailUrl;
    final articleTitle = HtmlHelper.stripAndUnescape(widget.article.title);
    final articleDate = widget.article.date != null
        ? DateFormat.yMMMMd().format(widget.article.date!)
        : 'Latest update';
    final author = widget.article.author ?? 'News Desk CT';

    return RefreshIndicator(
      onRefresh: _generateSummary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFFBF5), Color(0xFFF1E1C8)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE4CFB1)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8C1D18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'READ IN SHORT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    articleTitle,
                    style: const TextStyle(
                      fontSize: 28,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F1811),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetaBadge(icon: Icons.person_rounded, label: author),
                      _MetaBadge(
                        icon: Icons.calendar_today_rounded,
                        label: articleDate,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(28.0),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(
                            height: 250,
                            color: const Color(0xFFE8D7BF),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      errorWidget: (c, u, e) => Container(
                        height: 250,
                        color: const Color(0xFFE8D7BF),
                        child: const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.48),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Quick summary crafted for fast reading',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            _buildSummarySection(),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE7D6C0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (widget.article.link != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ArticleWebViewScreen(url: widget.article.link!),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8C1D18),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.chrome_reader_mode_rounded),
                      label: const Text(
                        'Read Full Article',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    if (_isLoadingSummary) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE7D6C0)),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'Preparing your short summary...',
              style: TextStyle(
                color: Color(0xFF6C5846),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (_summaryError) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE7D6C0)),
        ),
        child: const Text(
          'We could not load the short summary right now. Pull down to retry.',
          style: TextStyle(
            color: Color(0xFF8C1D18),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE7D6C0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                color: Color(0xFF8C1D18),
              ),
              SizedBox(width: 8),
              Text(
                'Read In Short',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF241B13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _summary,
            style: const TextStyle(
              fontSize: 17,
              height: 1.7,
              color: Color(0xFF3E3024),
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2CCAE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF8C1D18)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5E4733),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ScreenshotWidget extends StatelessWidget {
  static const _logoAsset = 'lib/images/appheading.png';
  final Article article;
  final String summary;
  final Uint8List? imageBytes;

  const ScreenshotWidget({super.key, required this.article, required this.summary, this.imageBytes});

  @override
  Widget build(BuildContext context) {
    final cleanTitle = HtmlHelper.stripAndUnescape(article.title);
    final articleUrl = article.link ?? '';

    return Material(
      color: const Color(0xFFF8F3EA),
      child: Center(
        child: Container(
          width: 720,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Image.asset(_logoAsset, height: 42)),
              const SizedBox(height: 18),
              Text(
                cleanTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F1811),
                ),
              ),
              if (imageBytes != null) ...[
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.memory(
                    imageBytes!,
                    height: 320,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF7),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE7D6C0)),
                ),
                child: Text(
                  summary,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.65,
                    color: Color(0xFF3E3024),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F3EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$cleanTitle\n\nRead more:\n\n$articleUrl',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF4A2017),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
