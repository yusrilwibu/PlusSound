import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

class YoutubeStreamAudioSource extends StreamAudioSource {
  final String streamUrl;
  final String contentType;
  
  YoutubeStreamAudioSource({
    required this.streamUrl,
    this.contentType = 'audio/mp4',
  });

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(streamUrl));
    
    request.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    
    if (start != null || end != null) {
      request.headers['Range'] = 'bytes=${start ?? 0}-${end ?? ''}';
    }

    final response = await client.send(request);
    
    return StreamAudioResponse(
      sourceLength: response.contentLength,
      contentLength: response.contentLength,
      offset: start ?? 0,
      stream: response.stream,
      contentType: contentType,
    );
  }
}
