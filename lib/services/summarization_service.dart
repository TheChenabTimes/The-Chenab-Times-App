import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'database_service.dart';

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

    // Try up to 3 times with delay
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await http.post(
          Uri.parse('https://api.thechenabtimes.com/summarise.php'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"article": text}),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final summary = data["summary"];
          if (summary != null && summary.toString().isNotEmpty) {
            // Save to cache
            if (articleLink != null) {
              await _db.cacheSummary(articleLink, summary);
            }
            return summary;
          }
        }

        if (attempt < 3) await Future.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        if (attempt < 3) await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    return "Summary unavailable. Tap to read full article.";
  }
}
