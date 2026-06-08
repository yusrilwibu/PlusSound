import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final videoId = 'M2QKS9tte9g';
  print('Fetching manifest for $videoId...');
  try {
    final manifest = await yt.videos.streamsClient.getManifest(videoId, ytClients: [YoutubeApiClient.ios]);
    final streams = manifest.muxed;
    if (streams.isNotEmpty) {
      final stream = streams.withHighestBitrate();
      print('Success! Stream URL:');
      print(stream.url);
    } else {
      print('No muxed streams found.');
    }
  } catch (e) {
    print('Failed with error: $e');
  } finally {
    yt.close();
  }
}
