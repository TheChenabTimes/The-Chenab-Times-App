import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_chenab_times/screens/article_webview_screen.dart';
import 'package:the_chenab_times/services/saved_articles_provider.dart';
import 'package:the_chenab_times/services/summarization_service.dart';
import 'package:the_chenab_times/utils/html_helper.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/article_model.dart';

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
  late int index;
  String? summary;
  bool loading = true;
  bool _openingFullArticle = false;

  Article get article => widget.articles[index];

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      loading = true;
    });

    try {
      final result = await SummarizationService.instance.summarizeArticle(
        article.content ?? '',
        articleLink: article.link,
        excerpt: article.excerpt,
      );

      if (!mounted) return;
      setState(() {
        summary = result;
        loading = false;
      });
    } catch (_) {
      final fallbackSummary = HtmlHelper.stripAndUnescape(
        article.excerpt ?? '',
      ).trim();

      if (!mounted) return;
      setState(() {
        summary = fallbackSummary.isNotEmpty
            ? fallbackSummary
            : 'Summary not available at this moment. Please read full article.';
        loading = false;
      });
    }
  }

  Future<void> _toggleSaved() async {
    final savedProvider = context.read<SavedArticlesProvider>();
    final isSaved = savedProvider.isArticleSaved(article.link);

    if (isSaved) {
      await savedProvider.deleteArticle(article.link ?? '');
    } else {
      await savedProvider.saveArticle(article);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved ? 'Removed from saved articles' : 'Article saved',
        ),
      ),
    );
  }

  Future<void> _shareArticle() async {
    final title = HtmlHelper.stripAndUnescape(article.title ?? '').trim();
    final link = article.link?.trim() ?? '';
    final text = link.isNotEmpty ? '$title\n\n$link' : title;
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _openFullArticle() async {
    if (_openingFullArticle) return;

    final link = article.link?.trim();
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Can't open this article right now.")),
      );
      return;
    }

    setState(() => _openingFullArticle = true);

    try {
      final uri = Uri.tryParse(link);
      final host = uri?.host.toLowerCase() ?? '';
      final isChenabLink =
          host == 'thechenabtimes.com' || host.endsWith('.thechenabtimes.com');

      if (!mounted) return;

      if (isChenabLink) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ArticleWebViewScreen(url: link)),
        );
      } else if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Can't open this article right now.")),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Can't open this article right now.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _openingFullArticle = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = HtmlHelper.stripAndUnescape(article.title ?? '').trim();
    final cleanSummary = HtmlHelper.stripAndUnescape(summary ?? '').trim();
    final imageUrl = (article.imageUrl ?? article.thumbnailUrl ?? '').trim();
    final hasImage = imageUrl.isNotEmpty;
    final byline = [
      if ((article.author ?? '').trim().isNotEmpty) article.author!.trim(),
      if (article.date != null) DateFormat.yMMMMd().format(article.date!),
    ].join(' | ');
    final isSaved = context.watch<SavedArticlesProvider>().isArticleSaved(
      article.link,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F1E7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: const Color(0xFF372117),
                    ),
                    Expanded(
                      child: Image.asset(
                        'lib/images/appheading.png',
                        height: 34,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasImage)
                SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: const Color(0xFFE1D2BE)),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x10000000), Color(0xAA000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Quick summary crafted for fast reading',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 170,
                  color: const Color(0xFFE7D8C5),
                ),
              Transform.translate(
                offset: Offset(0, hasImage ? -70 : -40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF4EA),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE8D8C8)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              color: Color(0xFF7D1A17),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'READ IN SHORT',
                                style: TextStyle(
                                  color: Color(0xFF442218),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _toggleSaved,
                              splashRadius: 22,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                isSaved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: const Color(0xFF4A392E),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: _shareArticle,
                              splashRadius: 22,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.share_outlined,
                                color: Color(0xFF4A392E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (byline.isNotEmpty)
                          Text(
                            byline,
                            style: const TextStyle(
                              color: Color(0xFF6B5949),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF5A1E1A),
                            fontSize: 22,
                            height: 1.18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          Text(
                            cleanSummary.isNotEmpty
                                ? cleanSummary
                                : 'Summary not available at this moment. Please read full article.',
                            style: const TextStyle(
                              color: Color(0xFF2E241E),
                              fontSize: 17,
                              height: 1.55,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _openingFullArticle
                                ? null
                                : _openFullArticle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9E1E1B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 7,
                              shadowColor: const Color(
                                0xFF9E1E1B,
                              ).withValues(alpha: 0.35),
                            ),
                            child: Text(
                              _openingFullArticle
                                  ? 'Opening...'
                                  : 'Read Full Article',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: hasImage ? 0 : 12),
            ],
          ),
        ),
      ),
    );
  }
}
