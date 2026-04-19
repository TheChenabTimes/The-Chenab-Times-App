import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'database_service.dart';
import '../utils/html_helper.dart';

class SummarizationService {
  SummarizationService._internal();
  static final SummarizationService instance = SummarizationService._internal();
  final DatabaseService _db = DatabaseService();

  Future<String> summarizeArticle(String text, {String? articleLink}) async {
    if (text.trim().isEmpty) {
      return "No content available to summarize.";
    }

    // Check cache first
    if (articleLink != null) {
      final cached = await _db.getCachedSummary(articleLink);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    final truncatedText = _prepareArticleText(text);
    if (truncatedText.isEmpty) {
      return "Summary unavailable for this article.";
    }

    try {
      final response = await http
          .post(
            Uri.parse('https://api.thechenabtimes.com/summarise.php'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "article":
                  "Summarize this news article in 3 concise sentences. "
                  "Return only summary text. "
                  "Do not include intro phrases, headings, or labels.\n\n"
                  "$truncatedText",
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final summary = data["summary"];
        if (summary != null && summary.toString().isNotEmpty) {
          final cleanedSummary = summary
              .toString()
              .replaceFirst(
                RegExp(
                  r'^\s*(here is a summary of the news article in 3 sentences:|here is a summary:|here is a summary|in summary[:,]?\s*|this article discusses[:,]?\s*|summary[:,]?\s*)',
                  caseSensitive: false,
                ),
                '',
              )
              .trim();
          if (articleLink != null) {
            await _db.cacheSummary(articleLink, cleanedSummary);
          }
          return cleanedSummary;
        }
      }
    } catch (_) {}

    return "Summary unavailable for this article.";
  }

  String _prepareArticleText(String text) {
    final cleanText = HtmlHelper.stripAndUnescape(
      text,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleanText.isEmpty) return '';

    final sentenceMatches = RegExp(
      r'[^.!?]+[.!?]?',
      multiLine: true,
    ).allMatches(cleanText);
    final buffer = StringBuffer();

    for (final match in sentenceMatches) {
      final sentence = match.group(0)?.trim() ?? '';
      if (sentence.isEmpty) continue;
      final nextLength = buffer.length + sentence.length + 1;
      if (nextLength > 3500) break;
      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      buffer.write(sentence);
      if (buffer.length >= 2200) break;
    }

    final prepared = buffer.toString().trim();
    if (prepared.isNotEmpty) {
      return prepared;
    }

    return cleanText.length > 2200 ? cleanText.substring(0, 2200) : cleanText;
  }
}
