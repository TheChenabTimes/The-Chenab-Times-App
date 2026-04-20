import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';

class RssService {
  final String postsBaseUrl = 'https://thechenabtimes.com/wp-json/wp/v2/posts';
  final String pagesBaseUrl = 'https://thechenabtimes.com/wp-json/wp/v2/pages';
  final String categoriesBaseUrl =
      'https://thechenabtimes.com/wp-json/wp/v2/categories';
  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
        '(KHTML, like Gecko) TheChenabTimesApp/1.0 Mobile Safari/537.36',
  };

  /// [NEW] Fetch a single article by its ID.
  /// This is used when a notification comes with a specific Post ID.
  Future<Article?> fetchArticleById(int id, {String? languageCode}) async {
    var url = '$postsBaseUrl/$id?_embed=true';
    if (languageCode != null && languageCode != 'en') {
      url += '&lang=$languageCode';
    }
    final uri = Uri.parse(url);
    try {
      final resp = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        return Article.fromJson(data);
      } else {
        log('Failed to fetch article $id: Status ${resp.statusCode}');
        return null;
      }
    } catch (e) {
      log('Error fetching article by ID: $e');
      return null;
    }
  }

  Future<Article?> fetchArticleByUrl(String url, {String? languageCode}) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.isEmpty) return null;

    final slug = segments.last;
    var requestUrl =
        '$postsBaseUrl?slug=${Uri.encodeQueryComponent(slug)}&_embed=true&per_page=1';
    if (languageCode != null && languageCode != 'en') {
      requestUrl += '&lang=$languageCode';
    }

    try {
      final resp = await http
          .get(Uri.parse(requestUrl), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;

      final List<dynamic> data = json.decode(resp.body) as List<dynamic>;
      if (data.isEmpty) return null;
      return Article.fromJson(data.first as Map<String, dynamic>);
    } catch (e) {
      log('Error fetching article by URL: $e');
      return null;
    }
  }

  /// Fetch list of posts for the home screen
  Future<List<Article>> fetchPostsPage({
    int page = 1,
    int perPage = 15,
    String? languageCode,
    DateTime? after,
  }) async {
    var url = '$postsBaseUrl?page=$page&per_page=$perPage&_embed=true';
    if (languageCode != null && languageCode != 'en') {
      url += '&lang=$languageCode';
    }
    if (after != null) {
      url +=
          '&after=${Uri.encodeQueryComponent(after.toUtc().toIso8601String())}';
    }
    final uri = Uri.parse(url);
    try {
      final resp = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        return data
            .map((e) => Article.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (resp.statusCode == 400) {
        return [];
      } else {
        throw Exception('Failed to load posts (status ${resp.statusCode})');
      }
    } catch (e) {
      log("Error fetching posts: $e");
      return [];
    }
  }

  /// Fetch posts for a specific category
  Future<List<Article>> fetchCategoryPosts({
    required int categoryId,
    int page = 1,
    int perPage = 15,
    String? languageCode,
    DateTime? after,
  }) async {
    var url =
        '$postsBaseUrl?categories=$categoryId&page=$page&per_page=$perPage&_embed=true';
    if (languageCode != null && languageCode != 'en') {
      url += '&lang=$languageCode';
    }
    if (after != null) {
      url +=
          '&after=${Uri.encodeQueryComponent(after.toUtc().toIso8601String())}';
    }
    final uri = Uri.parse(url);
    try {
      final resp = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        return data
            .map((e) => Article.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (resp.statusCode == 400) {
        return [];
      } else {
        throw Exception('Failed to load posts (status ${resp.statusCode})');
      }
    } catch (e) {
      log("Error fetching category posts: $e");
      return [];
    }
  }

  /// Fetch a specific page (like About Us)
  Future<Article?> fetchPage(String searchTerm) async {
    final uri = Uri.parse(
      '$pagesBaseUrl?search=${Uri.encodeQueryComponent(searchTerm)}&_embed=true',
    );
    try {
      final resp = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        if (data.isNotEmpty) {
          return Article.fromJson(data.first as Map<String, dynamic>);
        }
      }
    } catch (e) {
      log("Error fetching page: $e");
    }
    return null;
  }

  /// Search for posts
  Future<List<Article>> searchPosts(
    String query, {
    int page = 1,
    int perPage = 30,
    String? languageCode,
  }) async {
    var url =
        '$postsBaseUrl?search=${Uri.encodeQueryComponent(query)}&page=$page&per_page=$perPage&_embed=true';
    if (languageCode != null && languageCode != 'en') {
      url += '&lang=$languageCode';
    }
    final uri = Uri.parse(url);
    try {
      final resp = await http.get(uri, headers: _headers);
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        return data
            .map((e) => Article.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      log("Error searching posts: $e");
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> searchCategories(
    String query, {
    int perPage = 20,
  }) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      '$categoriesBaseUrl?search=${Uri.encodeQueryComponent(query)}&per_page=$perPage',
    );
    try {
      final resp = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      log('Error searching categories: $e');
    }
    return [];
  }

  Future<int?> findExactCategoryId(List<String> queries) async {
    for (final query in queries) {
      final categories = await searchCategories(query);
      if (categories.isEmpty) continue;

      final normalizedQuery = _normalizeCategoryName(query);
      for (final category in categories) {
        final name = _normalizeCategoryName(category['name']?.toString() ?? '');
        final slug = _normalizeCategoryName(category['slug']?.toString() ?? '');
        if (name == normalizedQuery || slug == normalizedQuery) {
          return category['id'] as int?;
        }
      }
    }
    return null;
  }

  Future<int?> findLooseCategoryId(List<String> queries) async {
    for (final query in queries) {
      final categories = await searchCategories(query);
      if (categories.isEmpty) continue;

      final normalizedQuery = _normalizeCategoryName(query);
      for (final category in categories) {
        final name = _normalizeCategoryName(category['name']?.toString() ?? '');
        final slug = _normalizeCategoryName(category['slug']?.toString() ?? '');
        if (name.contains(normalizedQuery) || slug.contains(normalizedQuery)) {
          return category['id'] as int?;
        }
      }
    }
    return null;
  }

  String _normalizeCategoryName(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }
}
