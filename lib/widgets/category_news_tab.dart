import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:the_chenab_times/utils/app_status_handler.dart';
import '../models/article_model.dart';
import '../services/language_service.dart';
import '../services/rss_service.dart';
import '../screens/article_screen.dart';
import '../utils/html_helper.dart';

class CategoryNewsTab extends StatefulWidget {
  final int categoryId;
  const CategoryNewsTab({super.key, required this.categoryId});

  @override
  State<CategoryNewsTab> createState() => _CategoryNewsTabState();
}

class _CategoryNewsTabState extends State<CategoryNewsTab>
    with AutomaticKeepAliveClientMixin {
  final RssService _rss = RssService();
  final List<Article> _items = [];
  int _page = 1;
  bool _loading = true;
  bool _hasMore = true;
  bool _hasError = false;
  String _errorMessage = '';
  final ScrollController _scrollController = ScrollController();
  late LanguageService _languageService;

  @override
  bool get wantKeepAlive => true;

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
      final pageItems = await _rss.fetchCategoryPosts(
        categoryId: widget.categoryId,
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
            AppStatusHandler.showStatusToast(
              message: "Category feed loaded successfully.",
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_hasError && _items.isEmpty) {
      // Full screen error for initial load failure
      return RefreshIndicator(
        color: const Color(0xFF8C1D18),
        backgroundColor: const Color(0xFFFFFBF5),
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height -
                200, // Approximate available height
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 94,
                    height: 94,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFFBF5), Color(0xFFF2E2CA)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE3CCAC)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x16000000),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      color: Color(0xFF8C1D18),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6C1715),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pull down to refresh',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF7A6247),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF8C1D18),
      backgroundColor: const Color(0xFFFFFBF5),
      onRefresh: _refresh,
      child: (_loading && _items.isEmpty)
          ? _buildSkeletonLoader()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              controller: _scrollController,
              itemCount: _items.length + (_hasMore ? 2 : 1),
              itemBuilder: (context, idx) {
                if (idx == 0) {
                  return _buildSectionHeader(context);
                }

                final articleIndex = idx - 1;
                if (articleIndex >= _items.length) {
                  return _hasMore
                      ? const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 18),
                          child: Center(child: _CategoryFeedLoadingFooter()),
                        )
                      : const SizedBox.shrink();
                }
                final a = _items[articleIndex];
                final imageUrl = a.thumbnailUrl ?? a.imageUrl;
                return _buildPremiumArticleCard(
                  context,
                  a,
                  articleIndex,
                  imageUrl,
                );
              },
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFBF5), Color(0xFFF2E2CA)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE4CEB2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFB22D1F), Color(0xFF7C1714)],
                ),
              ),
              child: const Icon(
                Icons.newspaper_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Top Stories',
                    style: TextStyle(
                      color: Color(0xFF4A2017),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Latest verified news from this category',
                    style: TextStyle(
                      color: Color(0xFF7A6247),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  Widget _buildPremiumArticleCard(
    BuildContext context,
    Article article,
    int articleIndex,
    String? imageUrl,
  ) {
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
                        HtmlHelper.stripAndUnescape(article.title ?? ''),
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
                        HtmlHelper.stripAndUnescape(article.excerpt ?? ''),
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
    return Container(
      color: const Color(0xFFF8F3EA),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: const [
          _CategoryFeedLoadingHero(),
          SizedBox(height: 14),
          _CategoryFeedLoadingCard(),
          SizedBox(height: 14),
          _CategoryFeedLoadingCard(),
          SizedBox(height: 14),
          _CategoryFeedLoadingCard(),
        ],
      ),
    );
  }
}

class _CategoryFeedLoadingHero extends StatelessWidget {
  const _CategoryFeedLoadingHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF5), Color(0xFFF2E2CA)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4CEB2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: const [
          _LoadingBlock(width: 42, height: 42, radius: 21),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LoadingBlock(width: double.infinity, height: 16, radius: 8),
                SizedBox(height: 8),
                _LoadingBlock(width: 180, height: 12, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFeedLoadingCard extends StatelessWidget {
  const _CategoryFeedLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _LoadingBlock(width: 108, height: 108, radius: 16),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LoadingBlock(width: double.infinity, height: 16, radius: 8),
                SizedBox(height: 8),
                _LoadingBlock(width: double.infinity, height: 16, radius: 8),
                SizedBox(height: 8),
                _LoadingBlock(width: 160, height: 14, radius: 7),
                SizedBox(height: 12),
                _LoadingBlock(width: double.infinity, height: 12, radius: 6),
                SizedBox(height: 6),
                _LoadingBlock(width: 140, height: 12, radius: 6),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _LoadingBlock(
                        width: double.infinity,
                        height: 12,
                        radius: 6,
                      ),
                    ),
                    SizedBox(width: 10),
                    _LoadingBlock(width: 70, height: 12, radius: 6),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFeedLoadingFooter extends StatelessWidget {
  const _CategoryFeedLoadingFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF5), Color(0xFFF2E2CA)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3CCAC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF8C1D18)),
              backgroundColor: const Color(0xFFE7D5BE),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Loading more stories...',
            style: TextStyle(
              color: Color(0xFF6C1715),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3E4CF), Color(0xFFE7D3B8)],
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
