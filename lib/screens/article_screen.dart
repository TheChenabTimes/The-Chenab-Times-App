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

  String? summary;
  bool loading = true;

  Article get article => widget.articles[index];

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    loadSummary();
  }

  Future<void> loadSummary() async {
    try {
      final result =
          await SummarizationService.instance.summarizeArticle(
        article.content ?? '',
        articleLink: article.link,
        excerpt: article.excerpt,
      );

      setState(() {
        summary = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        summary = article.excerpt;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        HtmlHelper.stripAndUnescape(article.title ?? '');

    final imageUrl =
        article.featuredImage ??
        article.imageUrl ??
        '';

    return Scaffold(
      backgroundColor: const Color(0xfff6f1eb),

      appBar: AppBar(
        backgroundColor: const Color(0xfff6f1eb),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "THE CHENAB TIMES",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// IMAGE
            if (imageUrl.isNotEmpty)
              Stack(
                children: [
                  Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      color: Colors.grey.shade300,
                    ),
                  ),

                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Quick summary crafted for fast reading",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            /// CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xfff8f3ed),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xffe6d7c9),
                  ),
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    /// LABEL
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff9f1d1d),
                        borderRadius:
                            BorderRadius.circular(40),
                      ),
                      child: const Text(
                        "READ IN SHORT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// TITLE
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// SUMMARY BOX
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 20),
                        child: Center(
                          child:
                              CircularProgressIndicator(),
                        ),
                      )
                    else if (summary != null &&
                        summary!.trim().isNotEmpty)
                      Text(
                        HtmlHelper.stripAndUnescape(
                            summary!),
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      )
                    else
                      const Text(
                        "Summary not available at this moment. Please read full article.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),

                    const SizedBox(height: 22),

                    /// READ FULL BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xff9f1d1d),
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 14),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Read Full Article",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
