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
      return _fallbackSummary('');
    }

    if (articleLink != null) {
      final cached = await _db.getCachedSummary(articleLink);
      if (cached != null && cached.trim().isNotEmpty) {
        return cached;
      }
    }

    var articleText = _prepareArticleText(rawText);
    if (articleText.length < 500 &&
        articleLink != null &&
        articleLink.isNotEmpty) {
      final extractedText = await _extractArticleTextFromHtml(articleLink);
      if (extractedText.isNotEmpty) {
        articleText = extractedText;
      }
    }

    if (articleText.isEmpty) {
      return _fallbackSummary(rawText);
    }

    debugPrint('Summarizer article text length: ${articleText.length}');

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
        final summary = data['summary']?.toString().trim() ?? '';
        if (summary.isNotEmpty) {
          final cleanedSummary = summary
              .replaceFirst(
                RegExp(
                  r'^\s*(here is a summary of the news article in 3 sentences:|here is a summary:|here is a summary|in summary[:,]?\s*|this article discusses[:,]?\s*|summary[:,]?\s*)',
                  caseSensitive: false,
                ),
                '',
              )
              .trim();
          if (cleanedSummary.isNotEmpty) {
            if (articleLink != null) {
              await _db.cacheSummary(articleLink, cleanedSummary);
            }
            return cleanedSummary;
          }
        }
      } else {
        debugPrint(
          'Summarizer failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Summarizer error for $articleLink: $e');
    }

    final fallback = _fallbackSummary(articleText);
    if (articleLink != null && fallback.isNotEmpty) {
      await _db.cacheSummary(articleLink, fallback);
    }
    return fallback;
  }

  Future<String> _extractArticleTextFromHtml(String articleLink) async {
    try {
      final response = await http
          .get(Uri.parse(articleLink))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        debugPrint('Summarizer HTML fetch status: ${response.statusCode}');
        return '';
      }

      final html = utf8.decode(response.bodyBytes);
      return _prepareHtmlArticleText(html);
    } catch (e) {
      debugPrint('Summarizer HTML extraction error for $articleLink: $e');
      return '';
    }
  }

  String _prepareArticleText(String text) {
    final cleanText = HtmlHelper.stripAndUnescape(
      text,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleanText.isEmpty) return '';

    if (cleanText.length <= 3500) {
      return cleanText;
    }

    final sentenceMatches = RegExp(
      r'[^.!?]+[.!?]?',
      multiLine: true,
    ).allMatches(cleanText);
    final buffer = StringBuffer();

    for (final match in sentenceMatches) {
      final sentence = match.group(0)?.trim() ?? '';
      if (sentence.isEmpty) continue;

      final nextLength = buffer.length + sentence.length + 1;
      if (nextLength > 4500) break;

      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      buffer.write(sentence);

      if (buffer.length >= 2500) break;
    }

    final prepared = buffer.toString().trim();
    if (prepared.length >= 1500) {
      return prepared;
    }

    return cleanText.substring(0, 3500);
  }

  String _prepareHtmlArticleText(String html) {
    var cleanedHtml = html;

    cleanedHtml = cleanedHtml.replaceAll(
      RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
      ' ',
    );
    cleanedHtml = cleanedHtml.replaceAll(
      RegExp(r'<style[\s\S]*?</style>', caseSensitive: false),
      ' ',
    );
    cleanedHtml = cleanedHtml.replaceAll(
      RegExp(r'<nav[\s\S]*?</nav>', caseSensitive: false),
      ' ',
    );
    cleanedHtml = cleanedHtml.replaceAll(
      RegExp(r'<header[\s\S]*?</header>', caseSensitive: false),
      ' ',
    );
    cleanedHtml = cleanedHtml.replaceAll(
      RegExp(r'<footer[\s\S]*?</footer>', caseSensitive: false),
      ' ',
    );
    cleanedHtml = cleanedHtml.replaceAll(
      RegExp(r'<aside[\s\S]*?</aside>', caseSensitive: false),
      ' ',
    );
    cleanedHtml = cleanedHtml.replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ');

    final paragraphMatches = RegExp(
      r'<p\b[^>]*>([\s\S]*?)</p>',
      caseSensitive: false,
    ).allMatches(cleanedHtml);

    final paragraphs = paragraphMatches
        .map((match) => HtmlHelper.stripAndUnescape(match.group(1) ?? ''))
        .map((value) => value.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((value) => value.length > 40)
        .where((value) => !_looksLikeNavigationText(value))
        .toList();

    final combinedParagraphs = paragraphs.join(' ').trim();
    if (combinedParagraphs.length >= 500) {
      return _prepareArticleText(combinedParagraphs);
    }

    final fullText = HtmlHelper.stripAndUnescape(
      cleanedHtml,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (fullText.isEmpty) return '';

    return _prepareArticleText(_removeNavigationNoise(fullText));
  }

  bool _looksLikeNavigationText(String value) {
    final normalized = value.toLowerCase();
    const blockedPhrases = [
      'home',
      'menu',
      'search',
      'breaking news',
      'latest news',
      'follow us',
      'subscribe',
      'advertisement',
      'read more',
      'share this',
      'related articles',
      'previous article',
      'next article',
    ];

    for (final phrase in blockedPhrases) {
      if (normalized == phrase || normalized.startsWith('$phrase ')) {
        return true;
      }
    }
    return false;
  }

  String _removeNavigationNoise(String text) {
    final filteredLines = text
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) => !_looksLikeNavigationText(line))
        .toList();

    return filteredLines.join(' ').trim();
  }

  String _fallbackSummary(String text) {
    final prepared = _prepareArticleText(text);
    if (prepared.isEmpty) {
      return 'Summary unavailable for this article.';
    }

    if (prepared.length <= 800) {
      return prepared;
    }

    return prepared.substring(0, 800).trim();
  }
}
