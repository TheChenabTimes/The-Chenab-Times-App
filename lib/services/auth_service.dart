import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_chenab_times/models/article_model.dart';
import 'package:the_chenab_times/models/user_model.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class LeaderboardEntry {
  final String name;
  final int bestStreak;

  const LeaderboardEntry({required this.name, required this.bestStreak});

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      name: '${map['name'] ?? 'User'}',
      bestStreak: map['best_streak'] is int
          ? map['best_streak'] as int
          : int.tryParse('${map['best_streak'] ?? 0}') ?? 0,
    );
  }
}

class AuthService extends ChangeNotifier {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  static const String _baseUrl = 'https://api.thechenabtimes.com';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _bestSyncedStreakKey = 'games_best_synced_streak';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final http.Client _client = http.Client();

  String? _token;
  UserModel? _currentUser;
  bool _initialized = false;
  bool _busy = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isBusy => _busy;
  bool get isReady => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    try {
      _token = await _secureStorage.read(key: _tokenKey);
      final userJson = await _secureStorage.read(key: _userKey);
      if (userJson != null && userJson.isNotEmpty) {
        _currentUser = UserModel.fromJson(userJson);
      }
    } catch (_) {
      _token = null;
      _currentUser = null;
    }

    _initialized = true;
    notifyListeners();
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    _token = await _secureStorage.read(key: _tokenKey);
    return _token;
  }

  Future<bool> isLoggedIn() async {
    return (await getToken()) != null && _currentUser != null;
  }

  Future<UserModel> login(String email, String password) async {
    _setBusy(true);
    try {
      final response = await _post(
        '/auth/login.php',
        body: {'email': email.trim(), 'password': password},
      );
      final payload = _decodeMap(response.body);
      final token = payload['token']?.toString();
      final userMap = payload['user'];

      if (token == null || userMap is! Map<String, dynamic>) {
        throw const AuthException('Login response was incomplete.');
      }

      final user = UserModel.fromMap(userMap);
      await _persistSession(token: token, user: user);
      await syncLocalBestStreak();
      return user;
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Unable to log in right now. Please check your connection and try again.',
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<UserModel> register(String name, String email, String password) async {
    _setBusy(true);
    try {
      final response = await _post(
        '/auth/register.php',
        body: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      final payload = _tryDecodeMap(response.body);
      if (payload != null &&
          payload['token'] != null &&
          payload['user'] is Map<String, dynamic>) {
        final user = UserModel.fromMap(payload['user'] as Map<String, dynamic>);
        await _persistSession(token: '${payload['token']}', user: user);
        await syncLocalBestStreak();
        return user;
      }

      return await login(email, password);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Unable to create your account right now. Please try again in a moment.',
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
    notifyListeners();
  }

  Future<List<Article>> fetchSavedArticles() async {
    final response = await _authorizedGet('/articles/list.php');
    final payload = jsonDecode(response.body);
    if (payload is! List) {
      throw const AuthException('Could not load saved articles.');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => Article(
            title: item['title']?.toString(),
            imageUrl: item['image_url']?.toString(),
            thumbnailUrl: item['image_url']?.toString(),
            link: item['post_url']?.toString(),
          ),
        )
        .where((article) => article.link != null && article.link!.isNotEmpty)
        .toList();
  }

  Future<void> saveArticle(Article article) async {
    final link = article.link;
    if (link == null || link.isEmpty) {
      throw const AuthException('This article cannot be saved right now.');
    }

    await _authorizedPost(
      '/articles/save.php',
      body: {
        'url': link,
        'title': article.title ?? 'The Chenab Times',
        'image': article.imageUrl ?? article.thumbnailUrl ?? '',
      },
    );
  }

  Future<void> removeSavedArticle(String url) async {
    await _authorizedPost('/articles/remove.php', body: {'url': url});
  }

  Future<void> syncStreak(int streak) async {
    if (!isAuthenticated || streak <= 0) return;

    await _authorizedPost('/streak/update.php', body: {'streak': streak});

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bestSyncedStreakKey, streak);
  }

  Future<void> syncLocalBestStreak() async {
    if (!isAuthenticated) return;

    final prefs = await SharedPreferences.getInstance();
    final localStreak = prefs.getInt('games_scramble_streak') ?? 0;
    final bestSynced = prefs.getInt(_bestSyncedStreakKey) ?? 0;
    final streakToSync = localStreak > bestSynced ? localStreak : 0;
    if (streakToSync > 0) {
      await syncStreak(streakToSync);
    }
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard() async {
    final response = await _get('/streak/leaderboard.php');
    final payload = jsonDecode(response.body);
    if (payload is! List) {
      throw const AuthException('Could not load leaderboard right now.');
    }

    final entries = payload
        .whereType<Map<String, dynamic>>()
        .map(LeaderboardEntry.fromMap)
        .toList()
      ..sort((a, b) => b.bestStreak.compareTo(a.bestStreak));

    return entries.take(10).toList();
  }

  Map<String, String> _headers({bool authenticated = false}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<http.Response> _get(String path) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl$path'), headers: _headers())
          .timeout(const Duration(seconds: 20));
      return _validateResponse(response);
    } on TimeoutException {
      throw const AuthException('Server took too long to respond.');
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Network error. Please try again.');
    }
  }

  Future<http.Response> _post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      return _validateResponse(response);
    } on TimeoutException {
      throw const AuthException('Server took too long to respond.');
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Network error. Please try again.');
    }
  }

  Future<http.Response> _authorizedGet(String path) async {
    if (!isAuthenticated) {
      throw const AuthException('Please log in to continue.');
    }

    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl$path'), headers: _headers(authenticated: true))
          .timeout(const Duration(seconds: 20));
      return await _validateAuthorizedResponse(response);
    } on TimeoutException {
      throw const AuthException('Server took too long to respond.');
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Network error. Please try again.');
    }
  }

  Future<http.Response> _authorizedPost(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    if (!isAuthenticated) {
      throw const AuthException('Please log in to continue.');
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: _headers(authenticated: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      return await _validateAuthorizedResponse(response);
    } on TimeoutException {
      throw const AuthException('Server took too long to respond.');
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Network error. Please try again.');
    }
  }

  Future<void> _persistSession({
    required String token,
    required UserModel user,
  }) async {
    _token = token;
    _currentUser = user;
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _userKey, value: user.toJson());
    notifyListeners();
  }

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AuthException('Unexpected server response.');
    }
    return decoded;
  }

  Map<String, dynamic>? _tryDecodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  http.Response _validateResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    final payload = _tryDecodeMap(response.body);
    final message =
        payload?['message']?.toString() ??
        payload?['error']?.toString() ??
        'Request failed (${response.statusCode}).';
    throw AuthException(message);
  }

  Future<http.Response> _validateAuthorizedResponse(http.Response response) async {
    if (response.statusCode == 401) {
      await logout();
      throw const AuthException('Your session expired. Please log in again.');
    }

    return _validateResponse(response);
  }

  void _setBusy(bool value) {
    if (_busy == value) return;
    _busy = value;
    notifyListeners();
  }
}
