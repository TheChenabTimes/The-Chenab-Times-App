import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../services/summarization_service.dart';
import '../utils/html_helper.dart';

class ArticleScreen extends StatefulWidget {
  final List<Article> articles;
  final int initialIndex;

  const ArticleScreen({
    super.key,
    required this.articles,
    required this.initialIndex,
  });

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late int index;
  String summary = '';
  bool loading = true;

  Article get article => widget.articles[index];

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    loadSummary();
  }

  Future<void> loadSummary() async {
    final result = await SummarizationService.instance.summarizeArticle(
      article.content ?? '',
      articleLink: article.link,
      excerpt: article.excerpt,
    );

    setState(() {
      summary = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(HtmlHelper.stripAndUnescape(article.title)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Read In Short",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 12),

            if (loading)
              const CircularProgressIndicator()
            else
              Text(summary),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back"),
            )
          ],
        ),
      ),
    );
  }
}
