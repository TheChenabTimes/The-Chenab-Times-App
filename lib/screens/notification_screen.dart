import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_chenab_times/models/article_model.dart';
import 'package:the_chenab_times/models/notification_model.dart';
import 'package:the_chenab_times/services/language_service.dart';
import 'package:the_chenab_times/services/notification_provider.dart';
import 'package:the_chenab_times/services/rss_service.dart';
import 'package:the_chenab_times/screens/article_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<NotificationProvider>();
      await provider.loadNotifications();
      final languageCode = context.read<LanguageService>().appLocale.languageCode;
      await provider.syncLatestPosts(languageCode: languageCode, seedIfEmpty: false);
      if (mounted) {
        await provider.loadNotifications();
      }
    });
  }

  /// This handles what happens when you click a notification row in the list
  Future<void> _handleNotificationClick(BuildContext context, NotificationModel notification) async {
    // 1. If we already have the full article data saved, open it.
    if (notification.article != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArticleScreen(
            articles: [notification.article!],
            initialIndex: 0,
          ),
        ),
      );
      return;
    }

    // 2. If we don't have the article, but we have the Post ID, fetch it now.
    if (notification.postId != null) {
      // Show a loading spinner dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      // Fetch from API
      Article? fetchedArticle = await RssService().fetchArticleById(notification.postId!);

      // Hide loading spinner
      if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
      }

      if (fetchedArticle != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleScreen(
              articles: [fetchedArticle],
              initialIndex: 0,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load article. Check internet.')),
        );
      }
    } else {
      // 3. If no ID and no Article data, it's just a text notification.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is a text-only notification')),
      );
    }
  }

  Future<void> _refreshNotifications(BuildContext context) async {
    final provider = context.read<NotificationProvider>();
    final languageCode = context.read<LanguageService>().appLocale.languageCode;
    await provider.syncLatestPosts(languageCode: languageCode, seedIfEmpty: false);
    await provider.loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: provider.notifications.isEmpty ? null : () => provider.clearAllNotifications(),
                tooltip: 'Delete all',
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => _refreshNotifications(context),
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('No notifications yet. Pull down to check for new posts.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refreshNotifications(context),
            child: ListView.builder(
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return ListTile(
                  leading: notification.imageUrl != null
                      ? Image.network(notification.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.notifications),
                  title: Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _handleNotificationClick(context, notification),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
