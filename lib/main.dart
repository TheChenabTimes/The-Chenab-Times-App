import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'services/summarization_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:the_chenab_times/screens/article_webview_screen.dart';
import 'package:the_chenab_times/services/notification_provider.dart';
import 'package:the_chenab_times/services/rss_service.dart';
import 'package:the_chenab_times/services/saved_articles_provider.dart';
import 'package:the_chenab_times/utils/app_status_handler.dart';
import 'l10n/app_localizations.dart';
import 'models/article_model.dart';
import 'models/notification_model.dart';
import 'screens/article_screen.dart';
import 'screens/donate_screen.dart';
import 'screens/home_screen.dart';
import 'screens/more_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/saved_articles_screen.dart';
import 'screens/search_screen.dart';
import 'screens/splash_screen.dart';
import 'services/database_service.dart';
import 'services/language_service.dart';
import 'services/theme_service.dart';

// GLOBAL NAVIGATOR KEY
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final notificationProvider = NotificationProvider();
  await notificationProvider.loadNotifications();
  final notification = message.notification;
  final data = message.data;
  if (notification != null) {
    final model = NotificationModel(
      notificationId: message.messageId ?? DateTime.now().toString(),
      title: notification.title ?? "The Chenab Times",
      body: notification.body ?? "",
      imageUrl: data["image"],
      receivedAt: DateTime.now(),
      article: null,
      postId: int.tryParse(data["post_id"] ?? ""),
    );
    await notificationProvider.addNotification(model);
  }
}
void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final notificationProvider = NotificationProvider();

    try {
      await Firebase.initializeApp();
      // Create high importance notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        "high_importance_channel",
        "High Importance Notifications",
        description: "This channel is used for important notifications.",
        importance: Importance.high,
      );
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      // Initialize FCM
      final fcm = FirebaseMessaging.instance;
      await fcm.requestPermission();
      await fcm.subscribeToTopic("all");
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
      // FCM Foreground Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final notification = message.notification;
        final data = message.data;
        if (notification != null) {
          final model = NotificationModel(
            notificationId: message.messageId ?? DateTime.now().toString(),
            title: notification.title ?? "The Chenab Times",
            body: notification.body ?? "",
            imageUrl: data["image"],
            receivedAt: DateTime.now(),
            article: null,
            postId: int.tryParse(data["post_id"] ?? ""),
          );
          await notificationProvider.addNotification(model);
          // Show rich notification with image
          final imageUrl = data["image"] ?? "";
          BigPictureStyleInformation? bigPictureStyle;
          if (imageUrl.isNotEmpty) {
            final http.Response response = await http.get(Uri.parse(imageUrl));
            final Uint8List imageBytes = response.bodyBytes;
            bigPictureStyle = BigPictureStyleInformation(
              ByteArrayAndroidBitmap(imageBytes),
              largeIcon: ByteArrayAndroidBitmap(imageBytes),
            );
          }
          await flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                "high_importance_channel",
                "High Importance Notifications",
                importance: Importance.high,
                priority: Priority.high,
                styleInformation: bigPictureStyle,
              ),
            ),
          );
        }
      });
      // FCM Click Handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        final data = message.data;
        final postId = int.tryParse(data["post_id"] ?? "");
        if (postId != null) {
          Article? article = await RssService().fetchArticleById(postId);
          if (article != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => ArticleScreen(articles: [article], initialIndex: 0),
              ),
            );
            return;
          }
        }
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationScreen()),
        );
      });
      // Handle notification when app is completely closed
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        final data = initialMessage.data;
        final postId = int.tryParse(data["post_id"] ?? "");
        if (postId != null) {
          Article? article = await RssService().fetchArticleById(postId);
          if (article != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => ArticleScreen(articles: [article], initialIndex: 0),
              ),
            );
          }
        }
      }


      await ThemeService.instance.loadTheme();
      await LanguageService.instance.init();
      await notificationProvider.loadNotifications(); // Load initial notifications
      // Background pre-fetch summaries
      Future.delayed(const Duration(seconds: 3), () async {
        try {
          final articles = await RssService().fetchArticles();
          for (final article in articles.take(10)) {
            await SummarizationService.instance.summarizeArticle(
              article.content ?? article.excerpt ?? "",
              articleLink: article.link,
            );
            await Future.delayed(const Duration(seconds: 2));
          }
        } catch (e) {
          debugPrint("Prefetch error: $e");
        }
      });
    } catch (e) {
      debugPrint("Initialization error: $e");
    }

    final dbService = DatabaseService();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ThemeService.instance),
          ChangeNotifierProvider.value(value: LanguageService.instance),
          ChangeNotifierProvider(create: (_) => SavedArticlesProvider(dbService)),
          ChangeNotifierProvider.value(value: notificationProvider),
          Provider.value(value: dbService),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint("Global error: $error");
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, LanguageService>(
      builder: (context, themeService, languageService, child) {
        final buttonStyle = ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

        return MaterialApp(
          title: 'The Chenab Times',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          themeMode: themeService.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.red,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            elevatedButtonTheme: buttonStyle,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.red,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            elevatedButtonTheme: buttonStyle,
          ),
          locale: languageService.appLocale,
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('ur'),
          ],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DonateScreen(),
    const SavedArticlesScreen(),
    const MoreScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('lib/images/appheading.png', height: 40),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => const NotificationScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined), label: localizations.translate('home')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_border_outlined),
              label: localizations.translate('donate')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.bookmark_border_outlined),
              label: localizations.translate('saved')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.menu_outlined), label: localizations.translate('more')),
        ],
      ),
    );
  }
}
