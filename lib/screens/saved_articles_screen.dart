import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_chenab_times/models/article_model.dart';
import 'package:the_chenab_times/services/saved_articles_provider.dart';
import 'package:the_chenab_times/widgets/article_list_item.dart';

class SavedArticlesScreen extends StatelessWidget {
  const SavedArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SavedArticlesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.savedArticles.isEmpty) {
            return Center(
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
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.savedArticles.length,
            itemBuilder: (context, index) {
              final article = provider.savedArticles[index];
              return Dismissible(
                key: ValueKey(article.id), // Unique key for each item
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  // This is called after the item has been swiped away.
                  provider.deleteArticle(article.id!, article.link!);

                  // Optionally, show a snackbar to confirm deletion
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Article removed from saved'),
                      // You could add an "Undo" button here if desired
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
          );
        },
      ),
    );
  }
}
