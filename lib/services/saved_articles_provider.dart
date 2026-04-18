import 'package:flutter/material.dart';
import 'package:the_chenab_times/models/article_model.dart';
import 'package:the_chenab_times/services/database_service.dart';

class SavedArticlesProvider extends ChangeNotifier {
  final DatabaseService _dbService;
  List<Article> _savedArticles = [];
  bool _isLoading = true;

  SavedArticlesProvider(this._dbService) {
    _loadSavedArticles();
  }

  List<Article> get savedArticles => _savedArticles;
  bool get isLoading => _isLoading;

  Future<void> _loadSavedArticles() async {
    _isLoading = true;
    notifyListeners();
    _savedArticles = await _dbService.getSavedArticles();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveArticle(Article article) async {
    await _dbService.saveArticle(article);
    if (!_savedArticles.any((a) => a.link == article.link)) {
      _savedArticles.insert(0, article);
      notifyListeners();
    }
  }

  Future<void> deleteArticle(int id, String link) async {
    await _dbService.deleteSavedArticle(id);
    _savedArticles.removeWhere((a) => a.link == link);
    notifyListeners();
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
}
