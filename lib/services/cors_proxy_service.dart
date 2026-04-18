import 'package:http/http.dart' as http;

/// Alternative CORS proxy service that uses public CORS proxies
/// This is a fallback when local proxy is not available
class CorsProxyService {
  static const List<String> _publicProxies = [
    'https://api.allorigins.win/raw?url=',
    'https://corsproxy.io/?',
    'https://cors-anywhere.herokuapp.com/',
  ];

  static int _currentProxyIndex = 0;

  /// Try to fetch content using public CORS proxies
  static Future<String?> fetchWithProxy(String targetUrl) async {
    // Try each proxy in rotation
    for (int i = 0; i < _publicProxies.length; i++) {
      final proxyIndex = (_currentProxyIndex + i) % _publicProxies.length;
      final proxyUrl =
          '${_publicProxies[proxyIndex]}${Uri.encodeComponent(targetUrl)}';

      try {
        final response = await http
            .get(
              Uri.parse(proxyUrl),
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Accept': 'application/rss+xml, application/xml, text/xml, */*',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          _currentProxyIndex = proxyIndex; // Remember successful proxy
          return response.body;
        }
      } catch (e) {
        // Try next proxy
        continue;
      }
    }

    return null; // All proxies failed
  }

  /// Check if local proxy is available
  static Future<bool> isLocalProxyAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:8089/raw?url=test'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode !=
          404; // 404 means proxy is running but URL is invalid
    } catch (e) {
      return false;
    }
  }
}
