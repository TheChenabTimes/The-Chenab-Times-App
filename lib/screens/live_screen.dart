import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:the_chenab_times/services/youtube_service.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final YouTubeService _youTubeService = YouTubeService();
  late Future<List<dynamic>> _videos;
  Future<String?>? _liveStreamId;

  @override
  void initState() {
    super.initState();
    _videos = _youTubeService.getLatestVideos();
    _liveStreamId = _youTubeService.getLiveStreamId();
  }

  Future<void> _refresh() async {
    setState(() {
      _videos = _youTubeService.getLatestVideos();
      _liveStreamId = _youTubeService.getLiveStreamId();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live & Videos')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          child: Column(
            children: [
              FutureBuilder<String?>(
                future: _liveStreamId,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    return Column(
                      children: [
                        YoutubePlayer(
                          controller: YoutubePlayerController(
                            initialVideoId: snapshot.data!,
                            flags: const YoutubePlayerFlags(isLive: true),
                          ),
                          showVideoProgressIndicator: true,
                        ),
                        const Divider(),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              FutureBuilder<List<dynamic>>(
                future: _videos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No videos found.'));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final video = snapshot.data![index];
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerScreen(
                                  videoId: video['id']['videoId'],
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.network(
                                video['snippet']['thumbnails']['high']['url'],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  video['snippet']['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatelessWidget {
  final String videoId;

  const VideoPlayerScreen({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: YoutubePlayer(
          controller: YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(autoPlay: true),
          ),
          showVideoProgressIndicator: true,
        ),
      ),
    );
  }
}
