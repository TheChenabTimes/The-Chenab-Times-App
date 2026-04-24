import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_chenab_times/models/article_model.dart';
import 'package:the_chenab_times/models/user_model.dart';

class LeaderboardSocialAccount {
  final String label;
  final String url;

  const LeaderboardSocialAccount({required this.label, required this.url});

  factory LeaderboardSocialAccount.fromMap(Map<String, dynamic> map) {
    return LeaderboardSocialAccount(
      label: '${map['label'] ?? map['service'] ?? 'Profile'}',
      url: '${map['url'] ?? map['link'] ?? ''}',
    );
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class LeaderboardEntry {
  final String name;
  final String? profilePhoto;
  final int bestStreak;
  final int totalPoints;
  final String? profileUrl;
  final String? bio;
  final String? company;
  final String? jobTitle;
  final String? location;
  final List<LeaderboardSocialAccount> socialAccounts;

  const LeaderboardEntry({
    required this.name,
    this.profilePhoto,
    required this.bestStreak,
    required this.totalPoints,
    this.profileUrl,
    this.bio,
    this.company,
    this.jobTitle,
    this.location,
    this.socialAccounts = const [],
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    final rawAccounts = map['social_accounts'];
    return LeaderboardEntry(
      name: '${map['name'] ?? 'User'}',
      profilePhoto: map['profile_photo']?.toString(),
      bestStreak: map['best_streak'] is int
          ? map['best_streak'] as int
          : int.tryParse('${map['best_streak'] ?? 0}') ?? 0,
      totalPoints: map['total_points'] is int
          ? map['total_points'] as int
          : int.tryParse('${map['total_points'] ?? 0}') ?? 0,
      profileUrl: map['profile_url']?.toString(),
      bio: map['bio']?.toString(),
      company: map['company']?.toString(),
      jobTitle: map['job_title']?.toString(),
      location: map['location']?.toString(),
      socialAccounts: rawAccounts is List
          ? rawAccounts
                .whereType<Map>()
                .map(
                  (account) =>
                      account.map((key, value) => MapEntry('$key', value)),
                )
                .map(LeaderboardSocialAccount.fromMap)
                .where((account) => account.url.trim().isNotEmpty)
                .toList()
          : const [],
    );
  }

  bool get hasProfileShoutout =>
      (bio?.trim().isNotEmpty ?? false) ||
      (company?.trim().isNotEmpty ?? false) ||
      (jobTitle?.trim().isNotEmpty ?? false) ||
      (location?.trim().isNotEmpty ?? false) ||
      (profileUrl?.trim().isNotEmpty ?? false) ||
      socialAccounts.isNotEmpty;
}

class AuthService extends ChangeNotifier {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  static const String _baseUrl = 'https://api.thechenabtimes.com';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _bestSyncedStreakKey = 'games_best_synced_streak';
  static const String _bestLocalStreakKey = 'games_best_local_scramble_streak';
  static const String _syncedTotalPointsKey = 'games_synced_total_points';
  static const String _localPointsSnapshotKey = 'games_local_points_snapshot';
  static const String _scrambleStreakKey = 'games_scramble_streak';
  static const String _vocabScoreKey = 'games_vocab_score';
  static const String _sentenceScoreKey = 'games_sentence_score';
  static const String _spellingScoreKey = 'games_spelling_score';
  static const String _crosswordScoreKey = 'games_crossword_score';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final http.Client _client = http.Client();

  String? _token;
  UserModel? _currentUser;
  bool _initialized = false;
  bool _busy = false;
  int _streakSyncVersion = 0;
  int _serverBestStreakHint = 0;
  int _serverTotalPointsHint = 0;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isBusy => _busy;
  bool get isReady => _initialized;
  int get streakSyncVersion => _streakSyncVersion;

  Future<void> init() async {
    if (_initialized) return;

    try {
      _token = await _secureStorage.read(key: _tokenKey);
      final userJson = await _secureStorage.read(key: _userKey);
      if (userJson != null && userJson.isNotEmpty) {
        _currentUser = UserModel.fromJson(userJson);
        _serverBestStreakHint = _currentUser?.bestStreak ?? 0;
        _serverTotalPointsHint = _currentUser?.totalPoints ?? 0;
      }
    } catch (_) {
      _token = null;
      _currentUser = null;
      _serverBestStreakHint = 0;
      _serverTotalPointsHint = 0;
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
      try {
        await syncLocalGameProgress();
      } catch (_) {}
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
        try {
          await syncLocalGameProgress();
        } catch (_) {}
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
    _serverBestStreakHint = 0;
    _serverTotalPointsHint = 0;
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bestSyncedStreakKey);
    await prefs.remove(_syncedTotalPointsKey);
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
    final prefs = await SharedPreferences.getInstance();
    await syncGameProgress(
      bestStreak: streak,
      totalPoints: _readLocalTotalPoints(prefs),
    );
  }

  Future<void> syncGameProgress({
    required int bestStreak,
    required int totalPoints,
  }) async {
    if (!isAuthenticated || (bestStreak <= 0 && totalPoints <= 0)) return;

    final prefs = await SharedPreferences.getInstance();
    final localStreak = prefs.getInt(_scrambleStreakKey) ?? 0;
    final bestLocalStreak = prefs.getInt(_bestLocalStreakKey) ?? 0;
    final bestSyncedStreak = prefs.getInt(_bestSyncedStreakKey) ?? 0;
    final syncedTotalPoints = prefs.getInt(_syncedTotalPointsKey) ?? 0;
    final localTotalPoints = math.max(
      _readLocalTotalPoints(prefs),
      totalPoints,
    );
    final localPointsSnapshot = prefs.getInt(_localPointsSnapshotKey) ?? 0;
    final unsyncedLocalPoints = math.max(
      0,
      localTotalPoints - localPointsSnapshot,
    );
    final knownServerStreak = math.max(
      _serverBestStreakHint,
      _currentUser?.bestStreak ?? 0,
    );
    final knownServerTotalPoints = math.max(
      _serverTotalPointsHint,
      _currentUser?.totalPoints ?? 0,
    );
    final mergedStreak = [
      bestStreak,
      localStreak,
      bestLocalStreak,
      bestSyncedStreak,
      knownServerStreak,
    ].reduce(math.max);
    final mergedTotalPoints = math.max(
      math.max(syncedTotalPoints, knownServerTotalPoints) + unsyncedLocalPoints,
      math.max(totalPoints, knownServerTotalPoints),
    );

    await _persistMergedGameProgress(
      prefs,
      mergedStreak: mergedStreak,
      mergedTotalPoints: mergedTotalPoints,
      localPointsSnapshot: localTotalPoints,
    );
    await _authorizedPost(
      '/streak/update.php',
      body: {'streak': mergedStreak, 'total_points': mergedTotalPoints},
    );
    await prefs.setInt(_bestSyncedStreakKey, mergedStreak);
    await prefs.setInt(_syncedTotalPointsKey, mergedTotalPoints);
    _serverBestStreakHint = math.max(_serverBestStreakHint, mergedStreak);
    _serverTotalPointsHint = math.max(
      _serverTotalPointsHint,
      mergedTotalPoints,
    );
    await _updatePersistedUserGameStats(
      bestStreak: mergedStreak,
      totalPoints: mergedTotalPoints,
    );
    _streakSyncVersion++;
    notifyListeners();
  }

  Future<void> syncLocalGameProgress() async {
    if (!isAuthenticated) return;

    final prefs = await SharedPreferences.getInstance();
    final localStreak = prefs.getInt(_scrambleStreakKey) ?? 0;
    final bestLocalStreak = prefs.getInt(_bestLocalStreakKey) ?? 0;
    final localTotalPoints = _readLocalTotalPoints(prefs);
    final syncedTotalPoints = prefs.getInt(_syncedTotalPointsKey) ?? 0;
    final localPointsSnapshot = prefs.getInt(_localPointsSnapshotKey) ?? 0;
    final serverBestStreak = math.max(
      _serverBestStreakHint,
      _currentUser?.bestStreak ?? 0,
    );
    final serverTotalPoints = math.max(
      _serverTotalPointsHint,
      _currentUser?.totalPoints ?? 0,
    );
    final mergedStreak = math.max(
      math.max(localStreak, bestLocalStreak),
      serverBestStreak,
    );
    final unsyncedLocalPoints = math.max(
      0,
      localTotalPoints - localPointsSnapshot,
    );
    final mergedTotalPoints = math.max(
      serverTotalPoints + unsyncedLocalPoints,
      syncedTotalPoints,
    );

    await _persistMergedGameProgress(
      prefs,
      mergedStreak: mergedStreak,
      mergedTotalPoints: mergedTotalPoints,
      localPointsSnapshot: localTotalPoints,
    );

    if (mergedStreak > 0 || mergedTotalPoints > 0) {
      await syncGameProgress(
        bestStreak: mergedStreak,
        totalPoints: localTotalPoints,
      );
    } else {
      _streakSyncVersion++;
      notifyListeners();
    }
  }

  Future<void> syncLocalBestStreak() async {
    await syncLocalGameProgress();
  }

  Future<int> fetchServerBestStreak() async {
    return math.max(_serverBestStreakHint, _currentUser?.bestStreak ?? 0);
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard() async {
    final response = await _get('/streak/leaderboard.php');
    final payload = jsonDecode(response.body);
    if (payload is! List) {
      throw const AuthException('Could not load leaderboard right now.');
    }

    final entries =
        payload
            .whereType<Map<String, dynamic>>()
            .map(LeaderboardEntry.fromMap)
            .toList()
          ..sort((a, b) {
            final pointCompare = b.totalPoints.compareTo(a.totalPoints);
            if (pointCompare != 0) return pointCompare;
            return b.bestStreak.compareTo(a.bestStreak);
          });

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
          .get(
            Uri.parse('$_baseUrl$path'),
            headers: _headers(authenticated: true),
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
    _serverBestStreakHint = user.bestStreak;
    _serverTotalPointsHint = user.totalPoints;
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _userKey, value: user.toJson());
    notifyListeners();
  }

  Future<void> _persistMergedGameProgress(
    SharedPreferences prefs, {
    required int mergedStreak,
    required int mergedTotalPoints,
    required int localPointsSnapshot,
  }) async {
    await prefs.setInt(_scrambleStreakKey, mergedStreak);
    await prefs.setInt(_bestLocalStreakKey, mergedStreak);
    await prefs.setInt(_bestSyncedStreakKey, mergedStreak);
    await prefs.setInt(_syncedTotalPointsKey, mergedTotalPoints);
    await prefs.setInt(_localPointsSnapshotKey, localPointsSnapshot);
  }

  int _readLocalTotalPoints(SharedPreferences prefs) {
    return (prefs.getInt(_scrambleStreakKey) ?? 0) +
        (prefs.getInt(_vocabScoreKey) ?? 0) +
        (prefs.getInt(_sentenceScoreKey) ?? 0) +
        (prefs.getInt(_spellingScoreKey) ?? 0) +
        (prefs.getInt(_crosswordScoreKey) ?? 0);
  }

  Future<void> _updatePersistedUserGameStats({
    required int bestStreak,
    required int totalPoints,
  }) async {
    if (_currentUser == null) return;

    if (bestStreak <= _currentUser!.bestStreak &&
        totalPoints <= _currentUser!.totalPoints) {
      return;
    }

    _currentUser = UserModel(
      id: _currentUser!.id,
      name: _currentUser!.name,
      email: _currentUser!.email,
      photo: _currentUser!.photo,
      loginType: _currentUser!.loginType,
      bestStreak: math.max(_currentUser!.bestStreak, bestStreak),
      totalPoints: math.max(_currentUser!.totalPoints, totalPoints),
    );
    await _secureStorage.write(key: _userKey, value: _currentUser!.toJson());
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

  Future<http.Response> _validateAuthorizedResponse(
    http.Response response,
  ) async {
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
