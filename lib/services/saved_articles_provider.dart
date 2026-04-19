import 'package:flutter/foundation.dart';
import 'package:the_chenab_times/models/article_model.dart';
import 'package:the_chenab_times/services/auth_service.dart';
import 'package:the_chenab_times/services/database_service.dart';

class SavedArticlesProvider extends ChangeNotifier {
  SavedArticlesProvider(this._dbService, this._authService) {
    _wasAuthenticated = _authService.isAuthenticated;
    _authService.addListener(_handleAuthChange);
    _loadSavedArticles();
  }

  final DatabaseService _dbService;
  final AuthService _authService;

  List<Article> _savedArticles = [];
  bool _isLoading = true;
  bool _wasAuthenticated = false;

  List<Article> get savedArticles => List.unmodifiable(_savedArticles);
  bool get isLoading => _isLoading;

  Future<void> _loadSavedArticles() async {
    _isLoading = true;
    notifyListeners();

    _savedArticles = await _dbService.getSavedArticles();
    _isLoading = false;
    notifyListeners();

    if (_authService.isAuthenticated) {
      await syncFromServer();
    }
  }

  Future<void> refresh() async {
    await _loadSavedArticles();
  }

  Future<void> syncFromServer() async {
    if (!_authService.isAuthenticated) return;

    try {
      final remoteArticles = await _authService.fetchSavedArticles();
      await _dbService.replaceSavedArticles(remoteArticles);
      _savedArticles = await _dbService.getSavedArticles();
      notifyListeners();
    } catch (e) {
      debugPrint('Saved article sync failed: $e');
    }
  }

  Future<void> saveArticle(Article article) async {
    await _dbService.saveArticle(article);
    if (!_savedArticles.any((a) => a.link == article.link)) {
      _savedArticles.insert(0, article);
      notifyListeners();
    }

    if (_authService.isAuthenticated) {
      await _authService.saveArticle(article);
    }
  }

  Future<void> deleteArticle(String link) async {
    await _dbService.deleteSavedArticleByLink(link);
    _savedArticles.removeWhere((a) => a.link == link);
    notifyListeners();

    if (_authService.isAuthenticated) {
      await _authService.removeSavedArticle(link);
    }
  }

  Future<void> clearAll() async {
    await _dbService.deleteAllSavedArticles();
    _savedArticles.clear();
    notifyListeners();
  }

  bool isArticleSaved(String? link) {
    if (link == null) return false;
    return _savedArticles.any((a) => a.link == link);
  }

  Future<void> _handleAuthChange() async {
    final isAuthenticated = _authService.isAuthenticated;
    if (isAuthenticated == _wasAuthenticated) return;

    _wasAuthenticated = isAuthenticated;
    if (isAuthenticated) {
      await syncFromServer();
    } else {
      await clearAll();
    }
  }

  @override
  void dispose() {
    _authService.removeListener(_handleAuthChange);
    super.dispose();
  }
}
