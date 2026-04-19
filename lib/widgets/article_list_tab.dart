import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:the_chenab_times/utils/app_status_handler.dart';
import '../models/article_model.dart';
import '../services/language_service.dart';
import '../services/rss_service.dart';
import '../screens/article_screen.dart';
import '../utils/html_helper.dart';

class ArticleListTab extends StatefulWidget {
  const ArticleListTab({super.key});

  @override
  State<ArticleListTab> createState() => _ArticleListTabState();
}

class _ArticleListTabState extends State<ArticleListTab> {
  final RssService _rss = RssService();
  final List<Article> _items = [];
  static const List<String> _trendingTopics = [
    '#J&KDev',
    '#GlobalAffairs',
    '#ValleyWatch',
    '#PoliticalVoices',
    '#ChenabTimes',
  ];
  int _page = 1;
  bool _loading = true;
  bool _hasMore = true;
  bool _hasError = false;
  String _errorMessage = '';
  final ScrollController _scrollController = ScrollController();
  final PageController _heroController = PageController(viewportFraction: 0.86);
  late LanguageService _languageService;
  int _heroIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
              _scrollController.position.maxScrollExtent - 300 &&
          !_loading &&
          _hasMore &&
          !_hasError) {
        _fetchPage();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _languageService = Provider.of<LanguageService>(context);
    _languageService.addListener(_onLanguageChange);
    _fetchPage(isInitial: true);
  }

  void _onLanguageChange() {
    _refresh();
  }

  Future<void> _fetchPage({bool isInitial = false}) async {
    if (mounted) setState(() => _loading = true);
    try {
      final pageItems = await _rss.fetchPostsPage(
        page: _page,
        perPage: 15,
        languageCode: _languageService.appLocale.languageCode,
      );
      if (pageItems.isEmpty) {
        if (mounted) setState(() => _hasMore = false);
      } else {
        if (mounted) {
          setState(() {
            if (isInitial) _items.clear();
            _items.addAll(pageItems);
            _page++;
            _hasError = false; // Reset error on success
          });
          if (_page == 2) {
            // Show success toast only after first successful load
            AppStatusHandler.showStatusToast(
              message: "News feed loaded successfully.",
              type: StatusType.success,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        if (_items.isEmpty) {
          setState(() {
            _hasError = true;
            _errorMessage =
                'Could not connect to the server. Please check your internet connection.';
          });
          AppStatusHandler.showStatusToast(
            message: _errorMessage,
            type: StatusType.error,
          );
        } else {
          AppStatusHandler.showStatusToast(
            message: 'Could not load more articles. Pull down to retry.',
            type: StatusType.warning,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _hasError = false;
      _items.clear();
      _page = 1;
      _hasMore = true;
      _loading = true;
    });
    await _fetchPage();
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChange);
    _scrollController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && _items.isEmpty) {
      // Full screen error for initial load failure
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: (_loading && _items.isEmpty)
          ? _buildSkeletonLoader()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              controller: _scrollController,
              itemCount: _items.length + (_hasMore ? 1 : 0) + 1,
              itemBuilder: (context, idx) {
                if (idx == 0) {
                  return _buildTopSection(context);
                }

                final articleIndex = idx - 1;
                if (articleIndex >= _items.length) {
                  return _hasMore
                      ? Center(
                          child: Lottie.asset(
                            'assets/loading.json',
                            width: 150,
                            height: 150,
                          ),
                        )
                      : const SizedBox.shrink();
                }
                final a = _items[articleIndex];
                return _buildArticleCard(context, a, articleIndex);
              },
            ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    final featuredItems = _items.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _heroController,
            itemCount: featuredItems.length,
            onPageChanged: (index) {
              setState(() {
                _heroIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final article = featuredItems[index];
              final imageUrl = article.imageUrl ?? article.thumbnailUrl;
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ArticleScreen(articles: _items, initialIndex: index),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x25000000),
                        blurRadius: 14,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl != null)
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: const Color(0xFFE2D8C5)),
                            errorWidget: (context, url, error) =>
                                Container(color: const Color(0xFFD9CBB1)),
                          )
                        else
                          Container(color: const Color(0xFFD9CBB1)),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x11000000), Color(0xD9000000)],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFEEE1C7,
                                  ).withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Text(
                                  'Featured News',
                                  style: TextStyle(
                                    color: Color(0xFF3B2B18),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                HtmlHelper.stripAndUnescape(article.title),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 31,
                                  height: 1.05,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${article.author ?? 'News Desk'} | ${article.date != null ? DateFormat.yMMMd().format(article.date!) : ''}',
                                style: const TextStyle(
                                  color: Color(0xFFF2E7D5),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            featuredItems.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: _heroIndex == index ? 18 : 9,
              height: 9,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _heroIndex == index
                    ? const Color(0xFF2F6C52)
                    : const Color(0xFFD0B89A),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(12, 14, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7F1422), Color(0xFFB33B27)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'LATEST',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  HtmlHelper.stripAndUnescape(_items.first.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
          child: Text(
            'Trending Topics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF251C12),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _trendingTopics
                .map(
                  (topic) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F3EA),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFD4C2A9)),
                    ),
                    child: Text(
                      topic,
                      style: const TextStyle(
                        color: Color(0xFF4A3824),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildArticleCard(
    BuildContext context,
    Article article,
    int articleIndex,
  ) {
    final imageUrl = article.thumbnailUrl ?? article.imageUrl;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ArticleScreen(articles: _items, initialIndex: articleIndex),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 108,
                    height: 108,
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: const Color(0xFFE4D7C2)),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFFE4D7C2),
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                              ),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFE4D7C2),
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        HtmlHelper.stripAndUnescape(article.title),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F1811),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        HtmlHelper.stripAndUnescape(article.excerpt),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.25,
                          color: Color(0xFF5A4B3D),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'By ${article.author ?? 'News Desk'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF34271B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            article.date != null
                                ? DateFormat.yMMMd().format(article.date!)
                                : '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6F604E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Center(
      child: Lottie.asset('assets/loading.json', width: 150, height: 150),
    );
  }
}
