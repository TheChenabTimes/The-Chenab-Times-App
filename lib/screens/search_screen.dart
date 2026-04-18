import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:the_chenab_times/utils/app_status_handler.dart';
import '../services/language_service.dart';
import '../services/rss_service.dart';
import '../models/article_model.dart';
import 'article_screen.dart';
import '../utils/html_helper.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final RssService _rss = RssService();
  List<Article> _results = [];
  bool _loading = false;
  bool _hasSearched = false;

  Future<void> _doSearch() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _loading = true;
      _hasSearched = true;
      _results = [];
    });

    final languageCode = Provider.of<LanguageService>(
      context,
      listen: false,
    ).appLocale.languageCode;

    try {
      final res = await _rss.searchPosts(
        q,
        page: 1,
        perPage: 50,
        languageCode: languageCode,
      );
      if (mounted) {
        setState(() => _results = res);
        if (res.isNotEmpty) {
          AppStatusHandler.showStatusToast(
            message: "Found ${res.length} articles.",
            type: StatusType.success,
          );
        } else {
          AppStatusHandler.showStatusToast(
            message: "No articles found for your search.",
            type: StatusType.warning,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppStatusHandler.showStatusToast(
          message: 'Search failed. Please check your internet connection.',
          type: StatusType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Search Articles')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type to search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              onSubmitted: (_) => _doSearch(),
            ),
          ),
          Expanded(child: _buildResultsList(theme)),
        ],
      ),
    );
  }

  Widget _buildResultsList(ThemeData theme) {
    if (_loading) {
      return _buildSkeletonLoader();
    }

    if (!_hasSearched) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search for articles...',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No articles found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, idx) {
        final article = _results[idx];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ArticleScreen(articles: _results, initialIndex: idx),
            ),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (article.imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Image.network(
                      article.imageUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: Lottie.asset(
                            'assets/loading.json',
                            width: 50,
                            height: 50,
                          ),
                        );
                      },
                      errorBuilder: (c, e, s) => Container(
                        width: 100,
                        height: 100,
                        color: theme.scaffoldBackgroundColor,
                        child: const Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          HtmlHelper.stripAndUnescape(article.title ?? ''),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          HtmlHelper.stripAndUnescape(article.excerpt ?? ''),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return Center(
      child: Lottie.asset('assets/loading.json', width: 150, height: 150),
    );
  }
}
