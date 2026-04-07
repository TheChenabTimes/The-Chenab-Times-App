import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
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
    final isSaved = provider.isArticleSaved(_currentArticle.link);
    if (!isSaved) {
      await provider.saveArticle(_currentArticle);
      AppStatusHandler.showStatusToast(message: 'Article saved', type: StatusType.success);
    } else {
      await provider.deleteArticle(_currentArticle.id!, _currentArticle.link!);
      AppStatusHandler.showStatusToast(message: 'Removed from saved articles', type: StatusType.info);
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

          // Updated to use the non-deprecated SharePlus pattern
          await Share.shareXFiles(
            [XFile(path)],
            text: 'Check out this article from The Chenab Times!',
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
            title: Image.asset('lib/images/app_heading.png', height: 30),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border_outlined),
                onPressed: () => _toggleSave(savedArticlesProvider),
              ),
              IconButton(icon: const Icon(Icons.share_outlined), onPressed: _shareArticle),
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
    final theme = Theme.of(context);
    final imageUrl = widget.article.imageUrl ?? widget.article.thumbnailUrl;

    return RefreshIndicator(
      onRefresh: _generateSummary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(HtmlHelper.stripAndUnescape(widget.article.title), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (c, u, e) => const Icon(Icons.broken_image),
                ),
              ),
            const SizedBox(height: 24),
            _buildSummarySection(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (widget.article.link != null) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ArticleWebViewScreen(url: widget.article.link!),
                  ));
                }
              },
              child: const Text('Read Full Article'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    if (_isLoadingSummary) return const Center(child: CircularProgressIndicator());
    if (_summaryError) return const Text('Error loading summary.');
    return Text(_summary, style: const TextStyle(fontSize: 16, height: 1.5), textAlign: TextAlign.justify);
  }
}

class ScreenshotWidget extends StatelessWidget {
  final Article article;
  final String summary;
  final Uint8List? imageBytes;

  const ScreenshotWidget({super.key, required this.article, required this.summary, this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('lib/images/app_heading.png', height: 30),
          const SizedBox(height: 16),
          Text(HtmlHelper.stripAndUnescape(article.title), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 16),
          if (imageBytes != null) ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(imageBytes!)),
          const SizedBox(height: 16),
          Text(summary, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}