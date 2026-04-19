import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/html_helper.dart';
import 'database_service.dart';

class SummarizationService {
  SummarizationService._internal();

  static final SummarizationService instance = SummarizationService._internal();

  static const _summaryEndpoint =
      'https://api.thechenabtimes.com/summarise.php';

  final DatabaseService _db = DatabaseService();

  Future<String> summarizeArticle(String text, {String? articleLink}) async {
    final rawText = text.trim();

    if (rawText.isEmpty &&
        (articleLink == null || articleLink.trim().isEmpty)) {
      return 'Summary unavailable.';
    }

    if (articleLink != null) {
      final cached = await _db.getCachedSummary(articleLink);
      if (cached != null && cached.trim().isNotEmpty) {
        return cached;
      }
    }

    String articleText = _prepareArticleText(rawText);

    if (articleText.length < 800 &&
        articleLink != null &&
        articleLink.isNotEmpty) {
      final extractedText = await _extractArticleTextFromHtml(articleLink);
      if (extractedText.isNotEmpty) {
        articleText = extractedText;
      }
    }

    debugPrint('Summarizer article length: ${articleText.length}');

    String? summary;

    try {
      final response = await http
          .post(
            Uri.parse(_summaryEndpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'text': articleText}),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('Summarizer API status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        summary = data['summary']?.toString().trim();

        if (summary != null && summary.length < 80) {
          summary = null;
        }
      }
    } catch (e) {
      debugPrint('Summarizer error: $e');
    }

    summary ??= _excerptFallback(articleText);

    if (articleLink != null && summary.isNotEmpty) {
      await _db.cacheSummary(articleLink, summary);
    }

    return summary;
  }

  Future<String> _extractArticleTextFromHtml(String articleLink) async {
    try {
      final response = await http
          .get(Uri.parse(articleLink))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return '';

      final html = utf8.decode(response.bodyBytes);
      return _prepareHtmlArticleText(html);
    } catch (_) {
      return '';
    }
  }

  String _prepareArticleText(String text) {
    final cleanText = HtmlHelper.stripAndUnescape(text)
        .replaceAll(RegExp(r'\\s+'), ' ')
        .trim();

    if (cleanText.length < 1200) return cleanText;

    return cleanText.substring(0, 4500);
  }

  String _prepareHtmlArticleText(String html) {
    final paragraphs = RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true)
        .allMatches(html)
        .map((e) => HtmlHelper.stripAndUnescape(e.group(1) ?? ''))
        .map((e) => e.replaceAll(RegExp(r'\\s+'), ' ').trim())
        .where((e) => e.length > 60)
        .toList();

    return paragraphs.join(' ');
  }

  String _excerptFallback(String text) {
    final sentences = RegExp(r'[^.!?]+[.!?]')
        .allMatches(text)
        .map((e) => e.group(0)?.trim() ?? '')
        .where((e) => e.length > 40)
        .toList();

    if (sentences.isEmpty) return 'Summary unavailable.';

    final shortSummary = sentences.take(3).join(' ');

    return shortSummary;
  }
}
