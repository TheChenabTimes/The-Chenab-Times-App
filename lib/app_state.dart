import 'package:flutter/foundation.dart';
import '../models/article_model.dart';
import '../models/news_category.dart';
import '../services/rss_service.dart';

class AppState extends ChangeNotifier {
  final RssService _rss = RssService();

  NewsCategory? _selected;
  NewsCategory? get selected => _selected;

  bool _loading = false;
  bool get loading => _loading;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  String? _error;
  String? get error => _error;

  List<Article> _articles = [];
  List<Article> get articles => _articles;

  int _page = 1;
  bool _hasMore = true;

  /// Change Category
  Future<void> select(NewsCategory category) async {
    if (_selected == category) return;
    _selected = category;
    await loadArticles(reset: true);
  }

  /// Load Articles
  Future<void> loadArticles({bool reset = false}) async {
    if (_loading) return;

    if (reset) {
      _loading = true;
      _error = null;
      _articles = [];
      _page = 1;
      _hasMore = true;
      notifyListeners();
    } else {
      _loadingMore = true;
      notifyListeners();
    }

    try {
      List<Article> fetched;

      if (_selected!.id == 0) {
        /// Latest (no category filter)
        fetched = await _rss.fetchPostsPage(page: _page, perPage: 20);
      } else {
        /// Filter by WP Category ID
        fetched = await _rss.fetchCategoryPosts(
          categoryId: _selected!.id,
          page: _page,
          perPage: 20,
        );
      }

      if (fetched.isEmpty) {
        _hasMore = false;
      } else {
        _articles.addAll(fetched);
        _page++;
      }
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    _loadingMore = false;
    notifyListeners();
  }

  /// Infinite Scroll Loader
  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    await loadArticles(reset: false);
  }

  /// Search using WP REST API search
  Future<List<Article>> search(String query) async {
    if (query.trim().isEmpty) return [];

    return await _rss.searchPosts(query.trim());
  }
}
