import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/article_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'the_chenab_times.db');
    return await openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL
      )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE saved_articles ADD COLUMN thumbnailUrl TEXT',
      );
      await db.execute('ALTER TABLE saved_articles ADD COLUMN author TEXT');
      await db.execute('ALTER TABLE saved_articles ADD COLUMN date INTEGER');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN dob TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN gender TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN address TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN profile_picture TEXT');
    }
    if (oldVersion < 5) {
      await _createNotificationsTable(db);
    }
    if (oldVersion < 6) {
      await db.execute(
        'CREATE TABLE IF NOT EXISTS summary_cache(id INTEGER PRIMARY KEY AUTOINCREMENT, article_link TEXT NOT NULL UNIQUE, summary TEXT NOT NULL, cached_at INTEGER NOT NULL)',
      );
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE notifications ADD COLUMN post_id INTEGER');
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE notifications ADD COLUMN post_url TEXT');
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
    CREATE TABLE saved_articles(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      excerpt TEXT,
      content TEXT,
      imageUrl TEXT,
      thumbnailUrl TEXT,
      author TEXT,
      date INTEGER,
      link TEXT NOT NULL UNIQUE
    )
    ''');
    await db.execute('''
    CREATE TABLE users(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      email TEXT,
      dob TEXT,
      gender TEXT,
      address TEXT,
      profile_picture TEXT
    )
    ''');
    await _createNotificationsTable(db);
    await db.execute(
      'CREATE TABLE IF NOT EXISTS summary_cache(id INTEGER PRIMARY KEY AUTOINCREMENT, article_link TEXT NOT NULL UNIQUE, summary TEXT NOT NULL, cached_at INTEGER NOT NULL)',
    );
  }

  Future<void> _createNotificationsTable(Database db) async {
    await db.execute('''
    CREATE TABLE notifications(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      notification_id TEXT NOT NULL UNIQUE,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      image_url TEXT,
      received_at TEXT NOT NULL,
        article_data TEXT,
        post_id INTEGER,
        post_url TEXT
      )
      ''');
  }

  // User Methods
  Future<int> createUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', {
      'id': user.id,
      'username': user.name,
      'password_hash': '',
      'email': user.email,
      'profile_picture': user.photo,
    }, conflictAlgorithm: ConflictAlgorithm.fail);
  }

  Future<UserModel?> getUser(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap({
        'id': maps.first['id'],
        'name': maps.first['username'],
        'email': maps.first['email'],
        'photo': maps.first['profile_picture'],
        'login_type': 'email',
      });
    }
    return null;
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update(
      'users',
      {
        'username': user.name,
        'email': user.email,
        'profile_picture': user.photo,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Article Methods
  Future<void> saveArticle(Article article) async {
    final db = await database;
    await db.insert(
      'saved_articles',
      article.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSavedArticle(int id) async {
    final db = await database;
    await db.delete('saved_articles', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteSavedArticleByLink(String link) async {
    final db = await database;
    await db.delete('saved_articles', where: 'link = ?', whereArgs: [link]);
  }

  Future<void> deleteAllSavedArticles() async {
    final db = await database;
    await db.delete('saved_articles');
  }

  Future<List<Article>> getSavedArticles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'saved_articles',
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => Article.fromMap(maps[i]));
  }

  Future<void> replaceSavedArticles(List<Article> articles) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('saved_articles');
      for (final article in articles) {
        await txn.insert(
          'saved_articles',
          article.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<bool> isArticleSaved(String? link) async {
    if (link == null) return false;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'saved_articles',
      where: 'link = ?',
      whereArgs: [link],
    );
    return maps.isNotEmpty;
  }

  // Notification Methods
  Future<void> saveNotification(NotificationModel notification) async {
    final db = await database;
    await db.insert(
      'notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NotificationModel>> getNotifications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      orderBy: 'received_at DESC',
    );
    return List.generate(
      maps.length,
      (i) => NotificationModel.fromMap(maps[i]),
    );
  }

  Future<void> deleteAllNotifications() async {
    final db = await database;
    await db.delete('notifications');
  }

  Future<void> deleteNotification(int id) async {
    final db = await database;
    await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  // Summary Cache Methods
  Future<String?> getCachedSummary(String articleLink) async {
    final db = await database;
    final maps = await db.query(
      "summary_cache",
      where: "article_link = ?",
      whereArgs: [articleLink],
    );
    if (maps.isNotEmpty) return maps.first["summary"] as String?;
    return null;
  }

  Future<void> cacheSummary(String articleLink, String summary) async {
    final db = await database;
    await db.insert("summary_cache", {
      "article_link": articleLink,
      "summary": summary,
      "cached_at": DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearOldSummaryCache() async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    await db.delete(
      "summary_cache",
      where: "cached_at < ?",
      whereArgs: [cutoff],
    );
  }
}
