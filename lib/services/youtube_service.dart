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
}
