import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:the_chenab_times/models/article_model.dart';
import 'package:the_chenab_times/screens/article_screen.dart';
import 'package:the_chenab_times/services/language_service.dart';
import 'package:the_chenab_times/services/location_service.dart';
import 'package:the_chenab_times/services/rss_service.dart';
import 'package:the_chenab_times/utils/app_status_handler.dart';
import 'package:the_chenab_times/utils/html_helper.dart';

class ForYouTab extends StatefulWidget {
  const ForYouTab({super.key});

  @override
  State<ForYouTab> createState() => _ForYouTabState();
}

class _ForYouTabState extends State<ForYouTab> {
  static const List<String> _fallbackTopics = [
    '#RegionalNews',
    '#ForYou',
    '#IndiaUpdates',
    '#Breaking',
  ];

  final RssService _rss = RssService();
  final List<Article> _items = [];
  final ScrollController _scrollController = ScrollController();
  final PageController _heroController = PageController(viewportFraction: 0.86);

  late LanguageService _languageService;
  LocationService? _locationService;
  Timer? _heroTimer;
  Timer? _tickerTimer;
  bool _boundDependencies = false;
  String _feedLocationSignature = '';

  int _heroIndex = 0;
  int _tickerIndex = 0;
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_boundDependencies) {
      _languageService.removeListener(_onLanguageChanged);
    }
    _languageService = Provider.of<LanguageService>(context);
    _languageService.addListener(_onLanguageChanged);

    final newLocationService = Provider.of<LocationService>(context);
    if (_locationService != newLocationService) {
      _locationService?.removeListener(_onLocationChanged);
      _locationService = newLocationService;
      _locationService?.addListener(_onLocationChanged);
    }
    _boundDependencies = true;

    if (_items.isEmpty && !_loading) {
      _fetchPage(isInitial: true);
    } else if (_items.isEmpty) {
      unawaited(_fetchPage(isInitial: true));
    }
  }

  void _onLanguageChanged() {
    _refresh();
  }

  void _onLocationChanged() {
    final signature = _currentLocationSignature();
    if (signature.isEmpty || signature == _feedLocationSignature) return;

    // Auto-personalize only when the first real location arrives or when the
    // feed is still empty. Later weather refreshes should not rerun the feed.
    if (_feedLocationSignature.isEmpty || _items.isEmpty || _hasError) {
      unawaited(_refresh());
    }
  }

  Future<int?> _resolvePrimaryRegionCategoryId() async {
    final location = _locationService;
    if (location == null) return null;

    final cityTerms = <String>[
      if ((location.city ?? '').isNotEmpty) location.city!,
      if ((location.city ?? '').toLowerCase().startsWith('new '))
        location.city!.substring(4).trim(),
      if ((location.city ?? '').toLowerCase().startsWith('old '))
        location.city!.substring(4).trim(),
    ];

    final districtTerms = <String>[
      if ((location.district ?? '').isNotEmpty) location.district!,
    ];

    final stateTerms = <String>[
      if ((location.state ?? '').isNotEmpty) location.state!,
    ];

    final countryTerms = <String>[
      if ((location.country ?? '').isNotEmpty) location.country!,
    ];

    final exactTownMatch = await _rss.findExactCategoryId(cityTerms);
    if (exactTownMatch != null) return exactTownMatch;

    final exactDistrictMatch = await _rss.findExactCategoryId(districtTerms);
    if (exactDistrictMatch != null) return exactDistrictMatch;

    if ((location.country ?? '').toLowerCase() == 'india') {
      final exactStateMatch = await _rss.findExactCategoryId(stateTerms);
      if (exactStateMatch != null) return exactStateMatch;
    }

    final looseDistrictMatch = await _rss.findLooseCategoryId(districtTerms);
    if (looseDistrictMatch != null) return looseDistrictMatch;

    if ((location.country ?? '').toLowerCase() == 'india') {
      final looseStateMatch = await _rss.findLooseCategoryId(stateTerms);
      if (looseStateMatch != null) return looseStateMatch;
    }

    return _rss.findExactCategoryId(countryTerms);
  }

  Future<void> _fetchPage({bool isInitial = false}) async {
    if (mounted) setState(() => _loading = true);

    try {
      final pageItems = await _buildForYouFeed();

      if (pageItems.isEmpty) {
        if (mounted) {
          setState(() {
            _items.clear();
            _hasError = true;
            _errorMessage =
                'No recent posts were found for your region right now.';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _items.clear();
            _items.addAll(pageItems);
            _hasError = false;
          });
          _setupAutoPlay();
          AppStatusHandler.showStatusToast(
            message: 'Personalized feed loaded.',
            type: StatusType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (_items.isEmpty) {
          setState(() {
            _hasError = true;
            _errorMessage =
                'Could not build your local feed. Please check your internet connection.';
          });
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    _heroTimer?.cancel();
    _tickerTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _items.clear();
      _loading = true;
      _heroIndex = 0;
      _tickerIndex = 0;
    });
    await _fetchPage(isInitial: true);
  }

  Future<List<Article>> _buildForYouFeed() async {
    final location = _locationService;
    if (location == null) return [];
    _feedLocationSignature = _currentLocationSignature();

    final since = DateTime.now().subtract(const Duration(hours: 24));
    final languageCode = _languageService.appLocale.languageCode;
    final combined = <Article>[];
    final seenIds = <int>{};

    Future<void> appendBucket(int? categoryId, {bool recentOnly = true}) async {
      if (categoryId == null) return;
      final posts = await _rss.fetchCategoryPosts(
        categoryId: categoryId,
        perPage: 20,
        languageCode: languageCode,
        after: recentOnly ? since : null,
      );
      for (final post in posts) {
        if (post.id != null && seenIds.add(post.id!)) {
          combined.add(post);
        }
      }
    }

    final primaryCategoryId = await _resolvePrimaryRegionCategoryId();
    final stateCategoryId = await _resolveStateCategoryId();
    final countryCategoryId = await _resolveCountryCategoryId();

    if ((location.country ?? '').toLowerCase() == 'india') {
      await appendBucket(primaryCategoryId);
      if (stateCategoryId != null && stateCategoryId != primaryCategoryId) {
        await appendBucket(stateCategoryId);
      }
      if (countryCategoryId != null &&
          countryCategoryId != primaryCategoryId &&
          countryCategoryId != stateCategoryId) {
        await appendBucket(countryCategoryId);
      }
    } else {
      await appendBucket(stateCategoryId ?? primaryCategoryId);
      if (countryCategoryId != null &&
          countryCategoryId != stateCategoryId &&
          countryCategoryId != primaryCategoryId) {
        await appendBucket(countryCategoryId);
      }

      if (combined.isEmpty) {
        final internationalCategoryId = await _rss.findExactCategoryId([
          'International',
        ]);
        await appendBucket(internationalCategoryId, recentOnly: false);
      }
    }

    return combined;
  }

  Future<int?> _resolveStateCategoryId() async {
    final location = _locationService;
    if (location == null || (location.state ?? '').isEmpty) return null;
    final exact = await _rss.findExactCategoryId([location.state!]);
    if (exact != null) return exact;
    return _rss.findLooseCategoryId([location.state!]);
  }

  Future<int?> _resolveCountryCategoryId() async {
    final location = _locationService;
    if (location == null || (location.country ?? '').isEmpty) return null;
    return _rss.findExactCategoryId([location.country!]);
  }

  void _setupAutoPlay() {
    _heroTimer?.cancel();
    _tickerTimer?.cancel();

    if (_items.length > 1) {
      _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_heroController.hasClients || _items.length < 2) return;
        final nextIndex = (_heroIndex + 1) % _items.take(5).length;
        _heroController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      });

      _tickerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || _items.isEmpty) return;
        setState(() {
          _tickerIndex = (_tickerIndex + 1) % _items.take(8).length;
        });
      });
    }
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _tickerTimer?.cancel();
    _languageService.removeListener(_onLanguageChanged);
    _locationService?.removeListener(_onLocationChanged);
    _scrollController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  String _currentLocationSignature() {
    final location = _locationService;
    if (location == null) return '';

    final parts = [
      location.city?.trim() ?? '',
      location.district?.trim() ?? '',
      location.state?.trim() ?? '',
      location.country?.trim() ?? '',
    ].where((item) => item.isNotEmpty).toList();

    return parts.join('|').toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 72,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
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
              itemCount: _items.length + 1,
              itemBuilder: (context, idx) {
                if (idx == 0) {
                  return _buildTopSection(context);
                }

                final articleIndex = idx - 1;
                if (articleIndex >= _items.length) {
                  return const SizedBox.shrink();
                }

                final article = _items[articleIndex];
                return _buildArticleCard(context, article, articleIndex);
              },
            ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    final featuredItems = _items.take(5).toList();
    final tickerItems = _items.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
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
                  'FOR YOU',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final tickerArticle = tickerItems[_tickerIndex];
                    final articleIndex = _items.indexWhere(
                      (item) => item.id == tickerArticle.id,
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ArticleScreen(
                          articles: _items,
                          initialIndex: articleIndex >= 0 ? articleIndex : 0,
                        ),
                      ),
                    );
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    transitionBuilder: (child, animation) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                    child: Text(
                      HtmlHelper.stripAndUnescape(
                        tickerItems[_tickerIndex].title,
                      ),
                      key: ValueKey(
                        tickerItems[_tickerIndex].id ?? _tickerIndex,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
            children: [
              ..._fallbackTopics.map((topic) => _TopicChip(label: topic)),
            ],
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

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD4C2A9)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4A3824),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
