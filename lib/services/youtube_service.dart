import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeService {
  Future<List<dynamic>> getLatestVideos() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.thechenabtimes.com/youtube.php'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['items'];
      } else {
        throw Exception('Failed to load videos');
      }
    } catch (e) {
      throw Exception('Failed to load videos');
    }
  }

  Future<String?> getLiveStreamId() async {
    final videos = await getLatestVideos();
    for (final item in videos) {
      if (item is! Map<String, dynamic>) continue;
      final snippet = item['snippet'];
      final id = item['id'];
      if (snippet is! Map<String, dynamic> || id is! Map<String, dynamic>) {
        continue;
      }

      final liveFlag = (snippet['liveBroadcastContent'] ?? '')
          .toString()
          .toLowerCase();
      final videoId = id['videoId']?.toString();
      if (liveFlag == 'live' && videoId != null && videoId.isNotEmpty) {
        return videoId;
      }
    }
    return null;
  }
}
