import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<void> main() async {
  final yt = YoutubeExplode();
  final videoId = 'YykjpeuMNEk';
  
  try {
    final manifest = await yt.videos.streamsClient.getManifest(
      videoId, 
      ytClients: [YoutubeApiClient.tv, YoutubeApiClient.android, YoutubeApiClient.ios]
    );
    final audioStream = manifest.audioOnly.withHighestBitrate();
    print('SUCCESS: \${audioStream.url.toString().substring(0, 100)}...');
  } catch (e) {
    print('FAILED: \$e');
  } finally {
    yt.close();
  }
}
