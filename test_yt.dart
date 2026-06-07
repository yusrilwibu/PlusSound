import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final videoId = 'M2QKS9tte9g';
  print('Fetching manifest for $videoId...');
  try {
    final manifest = await yt.videos.streamsClient.getManifest(videoId);
    final audioStreams = manifest.audioOnly;
    if (audioStreams.isNotEmpty) {
      final audioStream = audioStreams.withHighestBitrate();
      print('Success! Stream URL:');
      print(audioStream.url);
    } else {
      print('No audio streams found.');
    }
  } catch (e) {
    print('Failed with error: $e');
  } finally {
    yt.close();
  }
}
