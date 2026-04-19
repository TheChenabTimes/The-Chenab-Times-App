import 'dart:async';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'services/summarization_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:the_chenab_times/services/notification_provider.dart';
import 'package:the_chenab_times/services/auth_service.dart';
import 'package:the_chenab_times/services/rss_service.dart';
import 'package:the_chenab_times/services/saved_articles_provider.dart';
import 'l10n/app_localizations.dart';
import 'models/article_model.dart';
import 'models/notification_model.dart';
import 'screens/article_screen.dart';
import 'screens/article_webview_screen.dart';
import 'screens/donate_screen.dart';
import 'screens/games_screen.dart';
import 'screens/home_screen.dart';
import 'screens/more_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/saved_articles_screen.dart';
import 'screens/search_screen.dart';
import 'screens/splash_screen.dart';
import 'services/database_service.dart';
import 'services/language_service.dart';
import 'services/location_service.dart';
import 'services/theme_service.dart';

// GLOBAL NAVIGATOR KEY
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
const MethodChannel _deepLinkChannel = MethodChannel(
  'thechenabtimes/deep_links',
);

void _openChenabLinkInApp(String? link) {
  unawaited(_openChenabLinkInAppAsync(link));
}

Future<void> _openChenabLinkInAppAsync(String? link) async {
  final url = link?.trim();
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  final host = uri?.host.toLowerCase();
  final isChenabLink =
      host == 'thechenabtimes.com' || host == 'www.thechenabtimes.com';
  if (!isChenabLink) return;

  final context = navigatorKey.currentContext;
  if (context == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openChenabLinkInApp(url);
    });
    return;
  }

  final languageCode = LanguageService.instance.appLocale.languageCode;
  final article = await RssService().fetchArticleByUrl(
    url,
    languageCode: languageCode,
  );

  if (article != null) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ArticleScreen(articles: [article], initialIndex: 0),
      ),
    );
    return;
  }

  navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => ArticleWebViewScreen(url: url)),
  );
}

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
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      _deepLinkChannel.setMethodCallHandler((call) async {
        if (call.method == 'openLink') {
          _openChenabLinkInApp(call.arguments as String?);
        }
      });
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
        final flutterLocalNotificationsPlugin =
            FlutterLocalNotificationsPlugin();
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
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
              final http.Response response = await http.get(
                Uri.parse(imageUrl),
              );
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
        FirebaseMessaging.onMessageOpenedApp.listen((
          RemoteMessage message,
        ) async {
          final data = message.data;
          final postId = int.tryParse(data["post_id"] ?? "");
          if (postId != null) {
            Article? article = await RssService().fetchArticleById(postId);
            if (article != null) {
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (_) =>
                      ArticleScreen(articles: [article], initialIndex: 0),
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
        RemoteMessage? initialMessage = await FirebaseMessaging.instance
            .getInitialMessage();
        if (initialMessage != null) {
          final data = initialMessage.data;
          final postId = int.tryParse(data["post_id"] ?? "");
          if (postId != null) {
            Article? article = await RssService().fetchArticleById(postId);
            if (article != null) {
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (_) =>
                      ArticleScreen(articles: [article], initialIndex: 0),
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint("Initialization error: $e");
      }

      await ThemeService.instance.loadTheme();
      await LanguageService.instance.init();
      await AuthService.instance.init();
      await notificationProvider.loadNotifications();
      await notificationProvider.syncLatestPosts(
        languageCode: LanguageService.instance.appLocale.languageCode,
      );
      await notificationProvider.loadNotifications();
      // Background pre-fetch summaries
      Future.delayed(const Duration(seconds: 3), () async {
        try {
          final articles = await RssService().fetchPostsPage(perPage: 10);
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

      final initialDeepLink = await _deepLinkChannel.invokeMethod<String>(
        'getInitialLink',
      );
      if (initialDeepLink != null && initialDeepLink.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openChenabLinkInApp(initialDeepLink);
        });
      }

      final dbService = DatabaseService();

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: ThemeService.instance),
            ChangeNotifierProvider.value(value: LanguageService.instance),
            ChangeNotifierProvider.value(value: AuthService.instance),
            ChangeNotifierProvider(create: (_) => LocationService()..init()),
            ChangeNotifierProvider(
              create: (_) =>
                  SavedArticlesProvider(dbService, AuthService.instance),
            ),
            ChangeNotifierProvider.value(value: notificationProvider),
            Provider.value(value: dbService),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint("Global error: $error");
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, LanguageService>(
      builder: (context, themeService, languageService, child) {
        final lightColorScheme =
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF8C1D18),
              brightness: Brightness.light,
            ).copyWith(
              surface: const Color(0xFFFFFBF5),
              surfaceContainerHighest: const Color(0xFFF2E2CA),
            );
        final darkColorScheme = const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFB22D1F),
          onPrimary: Colors.white,
          secondary: Color(0xFFE3C08F),
          onSecondary: Color(0xFF0D0D0D),
          error: Color(0xFFFF6B6B),
          onError: Colors.white,
          surface: Color(0xFF1A1A1A),
          onSurface: Colors.white,
          tertiary: Color(0xFF7A6247),
          onTertiary: Colors.white,
          outline: Color(0xFF2A2A2A),
          shadow: Colors.black,
          scrim: Colors.black,
          inverseSurface: Color(0xFFF8F3EA),
          onInverseSurface: Color(0xFF0D0D0D),
          inversePrimary: Color(0xFF8C1D18),
          surfaceTint: Color(0xFFB22D1F),
        );
        final buttonStyle = ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8C1D18),
            foregroundColor: Colors.white,
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
            colorScheme: lightColorScheme,
            useMaterial3: true,
            elevatedButtonTheme: buttonStyle,
            scaffoldBackgroundColor: const Color(0xFFF8F3EA),
            cardColor: const Color(0xFFFFFCF7),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF8F3EA),
              foregroundColor: Color(0xFF1F1811),
              surfaceTintColor: Colors.transparent,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
            elevatedButtonTheme: buttonStyle,
            scaffoldBackgroundColor: const Color(0xFF0D0D0D),
            canvasColor: const Color(0xFF0D0D0D),
            cardColor: const Color(0xFF1A1A1A),
            dividerColor: const Color(0xFF2A2A2A),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0D0D0D),
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1A1A1A),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFF1A1A1A),
              border: OutlineInputBorder(),
            ),
            listTileTheme: const ListTileThemeData(
              iconColor: Colors.white,
              textColor: Colors.white,
            ),
          ),
          locale: languageService.appLocale,
          supportedLocales: const [Locale('en'), Locale('hi'), Locale('ur')],
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
  Timer? _notificationRefreshTimer;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DonateScreen(),
    const SavedArticlesScreen(),
    const GamesScreen(),
    const MoreScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _notificationRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!mounted) return;
      final provider = context.read<NotificationProvider>();
      final languageCode = context
          .read<LanguageService>()
          .appLocale
          .languageCode;
      unawaited(
        provider.syncLatestPosts(
          languageCode: languageCode,
          seedIfEmpty: false,
        ),
      );
    });
  }

  @override
  void dispose() {
    _notificationRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navItems = <_PremiumNavItemData>[
      _PremiumNavItemData(
        label: localizations.translate('home'),
        icon: Icons.home_rounded,
      ),
      _PremiumNavItemData(
        label: localizations.translate('donate'),
        icon: Icons.favorite_rounded,
      ),
      _PremiumNavItemData(
        label: localizations.translate('saved'),
        icon: Icons.bookmark_rounded,
      ),
      const _PremiumNavItemData(label: 'Games', icon: Icons.extension_rounded),
      _PremiumNavItemData(
        label: localizations.translate('more'),
        icon: Icons.dashboard_rounded,
      ),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? null
          : AppBar(
              backgroundColor: isDark
                  ? const Color(0xFF0D0D0D)
                  : const Color(0xFFF6E8D5),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              scrolledUnderElevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF0D0D0D), Color(0xFF1A1A1A)]
                        : const [Color(0xFFFFFBF5), Color(0xFFF1DDC1)],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFE1CCAF),
                      width: 1,
                    ),
                  ),
                ),
              ),
              title: Image.asset('lib/images/appheading.png', height: 52),
              centerTitle: true,
              actions: [
                _PremiumAppBarActionButton(
                  icon: Icons.notifications_none_rounded,
                  semanticLabel: 'Notifications',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _PremiumAppBarActionButton(
                  icon: Icons.search_rounded,
                  semanticLabel: 'Search',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _PremiumBottomNavigationBar(
        currentIndex: _selectedIndex,
        items: navItems,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _PremiumNavItemData {
  const _PremiumNavItemData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _PremiumAppBarActionButton extends StatefulWidget {
  const _PremiumAppBarActionButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  State<_PremiumAppBarActionButton> createState() =>
      _PremiumAppBarActionButtonState();
}

class _PremiumAppBarActionButtonState
    extends State<_PremiumAppBarActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color(0x338C1D18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF171717), Color(0xFF232323)]
                      : const [Color(0xFFFFF6E8), Color(0xFFF0D9B9)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFE3C08F),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color(0x22000000)
                        : const Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFB22D1F), Color(0xFF7C1714)],
                    ),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 17),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumBottomNavigationBar extends StatelessWidget {
  const _PremiumBottomNavigationBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  final int currentIndex;
  final List<_PremiumNavItemData> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF151515), Color(0xFF1E1E1E)]
                : const [Color(0xFFFFFCF6), Color(0xFFF3E4CF)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE3CCAC),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x26000000) : const Color(0x19000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            return Expanded(
              child: _PremiumBottomNavigationItem(
                data: item,
                selected: index == currentIndex,
                onTap: () => onTap(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _PremiumBottomNavigationItem extends StatefulWidget {
  const _PremiumBottomNavigationItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _PremiumNavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PremiumBottomNavigationItem> createState() =>
      _PremiumBottomNavigationItemState();
}

class _PremiumBottomNavigationItemState
    extends State<_PremiumBottomNavigationItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = widget.selected;
    final highlightColor = selected
        ? const Color(0xFF8C1D18)
        : (isDark ? const Color(0xFFB5B5B5) : const Color(0xFF7A6A58));
    final labelColor = selected
        ? const Color(0xFF5C120F)
        : (isDark ? const Color(0xFFD0D0D0) : const Color(0xFF6E6254));

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            splashColor: const Color(0x338C1D18),
            highlightColor: Colors.transparent,
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFF4E2), Color(0xFFF3D1A7)],
                      )
                    : null,
                color: selected
                    ? null
                    : (isDark ? const Color(0xFF111111) : Colors.transparent),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFE3C08F)
                      : (isDark ? const Color(0xFF202020) : Colors.transparent),
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x1F8C1D18),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    width: selected ? 44 : 38,
                    height: selected ? 44 : 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: selected
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFB22D1F), Color(0xFF7C1714)],
                            )
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? const [Color(0xFF1D1D1D), Color(0xFF2A2A2A)]
                                  : const [
                                      Color(0xFFF8EFE4),
                                      Color(0xFFEADBC7),
                                    ],
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: selected
                              ? const Color(0x308C1D18)
                              : const Color(0x12000000),
                          blurRadius: selected ? 12 : 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        widget.data.icon,
                        key: ValueKey('${widget.data.label}-$selected'),
                        color: selected ? Colors.white : highlightColor,
                        size: selected ? 24 : 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontSize: selected ? 13.5 : 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: labelColor,
                      letterSpacing: selected ? 0.1 : 0,
                    ),
                    child: Text(
                      widget.data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
