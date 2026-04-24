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
  static const _finalFallbackMessage =
      'Summary not available at this moment. Please read full article.';

  final DatabaseService _db = DatabaseService();

  Future<String> summarizeArticle(
    String text, {
    String? articleLink,
    String? excerpt,
  }) async {
    final rawText = text.trim();
    final cleanExcerpt = _excerptFallback(excerpt);

    if (rawText.isEmpty &&
        (articleLink == null || articleLink.trim().isEmpty)) {
      return _finalFallback();
    }

    if (articleLink != null) {
      final cached = await _db.getCachedSummary(articleLink);

      if (_isUsableSummary(cached, excerpt: cleanExcerpt)) {
        return _normalizeText(cached!);
      }

      debugPrint('Ignoring invalid cached summary for $articleLink');
    }

    final articleText = _prepareArticleText(rawText);

    debugPrint('Summarizer cleaned length: ${articleText.length}');

    String? summary;

    try {
      final response = await http
          .post(
            Uri.parse(_summaryEndpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'article': articleText, 'text': articleText}),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('Summarizer API status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        summary = _extractValidApiSummary(data['summary']?.toString());
      }
    } catch (e) {
      debugPrint('Summarizer error: $e');
    }

    summary ??= cleanExcerpt;
    summary ??= _finalFallback();

    if (articleLink != null &&
        _shouldCacheSummary(summary, excerpt: cleanExcerpt)) {
      await _db.cacheSummary(articleLink, summary);
    }

    return summary;
  }

  String _prepareArticleText(String text) {
    final cleanText = _normalizeText(text);

    if (cleanText.isEmpty) return cleanText;

    if (cleanText.length <= 2500) return cleanText;

    return cleanText.substring(0, 2500);
  }

  String? _excerptFallback(String? excerpt) {
    final cleanExcerpt = _polishSummary(excerpt) ?? _normalizeText(excerpt);

    if (cleanExcerpt.length < 30) return null;
    if (_looksLikeBrokenSummary(cleanExcerpt)) return null;

    return cleanExcerpt;
  }

  String _normalizeText(String? value) {
    return HtmlHelper.stripAndUnescape(
      value,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _extractValidApiSummary(String? value) {
    final normalized = _polishSummary(value);
    if (normalized == null || normalized.isEmpty) return null;
    if (_looksLikeBrokenSummary(normalized)) return null;

    final sentenceCount = _sentenceCount(normalized);
    final wordCount = _wordCount(normalized);

    if (sentenceCount < 2 || sentenceCount > 4) {
      return null;
    }

    if (wordCount < 25 || wordCount > 140) {
      return null;
    }

    return normalized;
  }

  String? _polishSummary(String? value) {
    final normalized = _normalizeText(value);
    if (normalized.isEmpty) return null;

    var polished = normalized
        .replaceAll(
          RegExp(r'^\s*(summary|ai summary)\s*:\s*', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(
            r'\b(this|the) article (discusses|highlights|explores)\b',
            caseSensitive: false,
          ),
          'The report highlights',
        )
        .replaceAll(RegExp(r'\bin conclusion[, ]*', caseSensitive: false), '')
        .trim();

    final sentenceMatches = RegExp(r'[^.!?]+[.!?]+').allMatches(polished);
    final completeSentences = sentenceMatches
        .map((match) => match.group(0)!.trim())
        .where(
          (sentence) =>
              _wordCount(sentence) >= 4 && !_hasDanglingEnding(sentence),
        )
        .take(3)
        .toList();

    if (completeSentences.isNotEmpty) {
      polished = completeSentences.join(' ');
    }

    if (!_endsLikeSentence(polished) || _hasDanglingEnding(polished)) {
      return null;
    }

    return polished;
  }

  bool _isUsableSummary(String? value, {String? excerpt}) {
    if (value == null) return false;
    final normalized = _normalizeText(value);
    if (normalized.isEmpty || normalized == _finalFallbackMessage) {
      return false;
    }

    if (_extractValidApiSummary(normalized) != null) {
      return true;
    }

    if (excerpt != null && normalized == excerpt) {
      return true;
    }

    return false;
  }

  bool _shouldCacheSummary(String value, {String? excerpt}) {
    final normalized = _normalizeText(value);
    if (normalized.isEmpty || normalized == _finalFallbackMessage) {
      return false;
    }

    if (_extractValidApiSummary(normalized) != null) {
      return true;
    }

    return excerpt != null && normalized == excerpt;
  }

  bool _looksLikeBrokenSummary(String value) {
    final normalized = _normalizeText(value);
    if (normalized.isEmpty) return true;

    final wordCount = _wordCount(normalized);
    if (wordCount > 150 || normalized.length > 900) {
      return true;
    }

    if (_sentenceCount(normalized) <= 1 &&
        wordCount > 45 &&
        !_endsLikeSentence(normalized)) {
      return true;
    }

    if (_hasDanglingEnding(normalized)) {
      return true;
    }

    return false;
  }

  int _wordCount(String value) {
    if (value.trim().isEmpty) return 0;
    return value.trim().split(RegExp(r'\s+')).length;
  }

  int _sentenceCount(String value) {
    final matches = RegExp(r'[.!?]+').allMatches(value);
    return matches.length;
  }

  bool _endsLikeSentence(String value) {
    final trimmed = value.trimRight();
    if (trimmed.isEmpty) return false;

    const closingChars = ['"', "'", ')', ']'];
    var index = trimmed.length - 1;

    while (index >= 0 && closingChars.contains(trimmed[index])) {
      index--;
    }

    if (index < 0) return false;

    final lastChar = trimmed[index];
    return lastChar == '.' || lastChar == '!' || lastChar == '?';
  }

  bool _hasDanglingEnding(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return true;

    final lastSentenceMatch = RegExp(
      r'''([^.!?]+)[.!?]["')\]]*\s*$''',
    ).firstMatch(trimmed);
    final sentenceBody =
        lastSentenceMatch?.group(1)?.trim() ??
        trimmed.replaceAll(RegExp(r'''[.!?]["')\]]*\s*$'''), '').trim();

    if (sentenceBody.isEmpty) return true;

    final tokens = sentenceBody
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().isNotEmpty)
        .toList();
    if (tokens.isEmpty) return true;

    final lastWord = tokens.last
        .replaceAll(RegExp(r'[^a-zA-Z-]'), '')
        .toLowerCase();

    const danglingEndings = {
      'and',
      'or',
      'but',
      'so',
      'because',
      'if',
      'than',
      'that',
      'which',
      'who',
      'whom',
      'whose',
      'when',
      'where',
      'while',
      'after',
      'before',
      'during',
      'for',
      'from',
      'into',
      'onto',
      'over',
      'under',
      'through',
      'toward',
      'towards',
      'with',
      'without',
      'within',
      'about',
      'around',
      'between',
      'among',
      'against',
      'across',
      'despite',
      'via',
      'per',
      'to',
    };

    return lastWord.isEmpty || danglingEndings.contains(lastWord);
  }

  String _finalFallback() {
    return _finalFallbackMessage;
  }
}
