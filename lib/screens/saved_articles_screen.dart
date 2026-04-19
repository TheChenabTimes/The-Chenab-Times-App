import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_chenab_times/screens/login_screen.dart';
import 'package:the_chenab_times/services/auth_service.dart';
import 'package:the_chenab_times/services/saved_articles_provider.dart';
import 'package:the_chenab_times/widgets/article_list_item.dart';

class SavedArticlesScreen extends StatelessWidget {
  const SavedArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SavedArticlesProvider>(
        builder: (context, provider, child) {
          final authService = context.watch<AuthService>();

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.savedArticles.isEmpty && !authService.isAuthenticated) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.bookmark_border,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'You haven\'t saved any articles yet.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Log in to sync bookmarks across your account.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Log In'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.savedArticles.isEmpty) {
            return RefreshIndicator(
              onRefresh: provider.refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: Text(
                      'You haven\'t saved any articles yet.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView.builder(
              itemCount: provider.savedArticles.length,
              itemBuilder: (context, index) {
                final article = provider.savedArticles[index];
                return Dismissible(
                  key: ValueKey(article.link ?? article.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    final link = article.link;
                    if (link == null || link.isEmpty) return;
                    provider.deleteArticle(link);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Article removed from saved'),
                      ),
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  child: ArticleListItem(article: article),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
