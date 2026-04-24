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
  late final PageController _pageController;
  late int index;
  final Map<int, String> _summaryCache = {};
  final Map<int, bool> _summaryLoading = {};
  final Map<int, bool> _openingFullArticle = {};

  Article get article => widget.articles[index];

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadSummaryForIndex(index);
    _prefetchNearbySummaries(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSummaryForIndex(int articleIndex) async {
    if (_summaryLoading[articleIndex] == true) return;
    if ((_summaryCache[articleIndex] ?? '').trim().isNotEmpty) return;

    final currentArticle = widget.articles[articleIndex];

    setState(() {
      _summaryLoading[articleIndex] = true;
    });

    try {
      final result = await SummarizationService.instance.summarizeArticle(
        currentArticle.content ?? '',
        articleLink: currentArticle.link,
        excerpt: currentArticle.excerpt,
      );

      if (!mounted) return;
      setState(() {
        _summaryCache[articleIndex] = result;
        _summaryLoading[articleIndex] = false;
      });
    } catch (_) {
      final fallbackSummary = HtmlHelper.stripAndUnescape(
        currentArticle.excerpt ?? '',
      ).trim();

      if (!mounted) return;
      setState(() {
        _summaryCache[articleIndex] = fallbackSummary.isNotEmpty
            ? fallbackSummary
            : 'Summary not available at this moment. Please read full article.';
        _summaryLoading[articleIndex] = false;
      });
    }
  }

  void _prefetchNearbySummaries(int currentIndex) {
    if (currentIndex > 0) {
      _loadSummaryForIndex(currentIndex - 1);
    }
    if (currentIndex < widget.articles.length - 1) {
      _loadSummaryForIndex(currentIndex + 1);
    }
  }

  Future<void> _toggleSaved(Article currentArticle) async {
    final savedProvider = context.read<SavedArticlesProvider>();
    final isSaved = savedProvider.isArticleSaved(currentArticle.link);

    if (isSaved) {
      await savedProvider.deleteArticle(currentArticle.link ?? '');
    } else {
      await savedProvider.saveArticle(currentArticle);
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

  Future<void> _shareArticle(Article currentArticle) async {
    final title = HtmlHelper.stripAndUnescape(
      currentArticle.title ?? '',
    ).trim();
    final link = currentArticle.link?.trim() ?? '';
    final text = link.isNotEmpty ? '$title\n\n$link' : title;
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _openFullArticle(
    Article currentArticle,
    int articleIndex,
  ) async {
    if (_openingFullArticle[articleIndex] == true) return;

    final link = currentArticle.link?.trim();
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Can't open this article right now.")),
      );
      return;
    }

    setState(() => _openingFullArticle[articleIndex] = true);

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
        setState(() => _openingFullArticle[articleIndex] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F1E7),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.articles.length,
              onPageChanged: (newIndex) {
                setState(() => index = newIndex);
                _loadSummaryForIndex(newIndex);
                _prefetchNearbySummaries(newIndex);
              },
              itemBuilder: (context, pageIndex) {
                final currentArticle = widget.articles[pageIndex];
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    var delta = 0.0;
                    if (_pageController.hasClients &&
                        _pageController.position.hasContentDimensions) {
                      delta =
                          pageIndex -
                          (_pageController.page ?? index.toDouble());
                    } else {
                      delta = pageIndex - index.toDouble();
                    }

                    final clamped = delta.clamp(-1.0, 1.0);
                    final progress = clamped.abs();
                    final isIncomingFromRight = clamped > 0;
                    final rotation = clamped * 0.32;
                    final scale = 1 - (progress * 0.08);
                    final translateX = clamped * 54;
                    final lift = progress * 8;
                    final paperShadowOpacity = (0.26 * progress).clamp(
                      0.0,
                      0.26,
                    );
                    final edgeHighlightOpacity = (0.18 * progress).clamp(
                      0.0,
                      0.18,
                    );

                    return Transform(
                      alignment: clamped >= 0
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0016)
                        ..translateByDouble(translateX, -lift, 0, 1)
                        ..rotateY(rotation)
                        ..scaleByDouble(scale, 1.0, 1.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2D120D,
                              ).withValues(alpha: paperShadowOpacity),
                              blurRadius: 22 + (progress * 10),
                              offset: Offset(
                                isIncomingFromRight ? -10 : 10,
                                12,
                              ),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned.fill(child: child!),
                              IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: isIncomingFromRight
                                          ? Alignment.centerLeft
                                          : Alignment.centerRight,
                                      end: isIncomingFromRight
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      colors: [
                                        const Color(0xFFF7E6CC).withValues(
                                          alpha: edgeHighlightOpacity,
                                        ),
                                        const Color(
                                          0xFF8C1D18,
                                        ).withValues(alpha: 0),
                                        const Color(0xFF1D100B).withValues(
                                          alpha: (progress * 0.12).clamp(
                                            0.0,
                                            0.12,
                                          ),
                                        ),
                                      ],
                                      stops: const [0.0, 0.45, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              if (progress > 0.02)
                                IgnorePointer(
                                  child: Align(
                                    alignment: isIncomingFromRight
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    child: Container(
                                      width: 10 + (progress * 12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: isIncomingFromRight
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                          end: isIncomingFromRight
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          colors: [
                                            const Color(0xFFFFF8ED).withValues(
                                              alpha: (progress * 0.8).clamp(
                                                0.0,
                                                0.8,
                                              ),
                                            ),
                                            const Color(
                                              0xFFBA9A73,
                                            ).withValues(alpha: 0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: _ArticlePage(
                    article: currentArticle,
                    summary: _summaryCache[pageIndex],
                    loading: _summaryLoading[pageIndex] ?? false,
                    openingFullArticle: _openingFullArticle[pageIndex] ?? false,
                    isSaved: context
                        .watch<SavedArticlesProvider>()
                        .isArticleSaved(currentArticle.link),
                    hasPrevious: pageIndex > 0,
                    hasNext: pageIndex < widget.articles.length - 1,
                    onBack: () => Navigator.of(context).pop(),
                    onToggleSaved: () => _toggleSaved(currentArticle),
                    onShare: () => _shareArticle(currentArticle),
                    onOpenFullArticle: () =>
                        _openFullArticle(currentArticle, pageIndex),
                  ),
                );
              },
            ),
            Positioned(
              left: 0,
              top: 110,
              bottom: 40,
              child: IgnorePointer(
                child: _PageEdgeGlow(
                  alignment: Alignment.centerLeft,
                  visible: index > 0,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 110,
              bottom: 40,
              child: IgnorePointer(
                child: _PageEdgeGlow(
                  alignment: Alignment.centerRight,
                  visible: index < widget.articles.length - 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticlePage extends StatelessWidget {
  const _ArticlePage({
    required this.article,
    required this.summary,
    required this.loading,
    required this.openingFullArticle,
    required this.isSaved,
    required this.hasPrevious,
    required this.hasNext,
    required this.onBack,
    required this.onToggleSaved,
    required this.onShare,
    required this.onOpenFullArticle,
  });

  final Article article;
  final String? summary;
  final bool loading;
  final bool openingFullArticle;
  final bool isSaved;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onBack;
  final VoidCallback onToggleSaved;
  final VoidCallback onShare;
  final VoidCallback onOpenFullArticle;

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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
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
                    child: Row(
                      children: [
                        Expanded(
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
                          onPressed: onToggleSaved,
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
                          onPressed: onShare,
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
                    Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFF8E8D1), Color(0xFFF4D6B0)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A9E1E1B),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasPrevious
                                ? Icons.swipe_right_alt_rounded
                                : Icons.menu_book_rounded,
                            color: const Color(0xFF8B1F1B),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              hasPrevious || hasNext
                                  ? 'Swipe left or right anywhere to flip through stories like a magazine.'
                                  : 'This story is ready for a focused quick read.',
                              style: const TextStyle(
                                color: Color(0xFF6B4B38),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        onPressed: openingFullArticle
                            ? null
                            : onOpenFullArticle,
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
                          openingFullArticle
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
    );
  }
}

class _PageEdgeGlow extends StatelessWidget {
  const _PageEdgeGlow({required this.alignment, required this.visible});

  final Alignment alignment;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 220),
      child: Container(
        width: 18,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: alignment == Alignment.centerLeft
                ? Alignment.centerLeft
                : Alignment.centerRight,
            end: alignment == Alignment.centerLeft
                ? Alignment.centerRight
                : Alignment.centerLeft,
            colors: const [Color(0x44B55C2C), Color(0x00B55C2C)],
          ),
        ),
      ),
    );
  }
}
