import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_config.dart';

class MusicService {
  final YoutubeExplode _yt = YoutubeExplode();
  
  // In-memory cache for stream URLs to avoid re-fetching
  static final Map<String, Map<String, dynamic>> _streamCache = {};
  
  // In-memory cache for lyrics
  static final Map<String, String> _lyricsCache = {};

  /// Parse a search result item from ytmusicapi into SongModel
  SongModel? _parseSongItem(dynamic item) {
    try {
      final videoId = item['videoId'] ?? '';
      if (videoId.isEmpty) return null;

      String artistName = 'Unknown Artist';
      if (item['artists'] != null && (item['artists'] as List).isNotEmpty) {
        artistName = item['artists'][0]['name'] ?? 'Unknown Artist';
      } else if (item['artist'] != null) {
        artistName = item['artist'].toString();
      }

      String thumbnailUrl = '';
      if (item['thumbnails'] != null && (item['thumbnails'] as List).isNotEmpty) {
        thumbnailUrl = item['thumbnails'].last['url'] ?? '';
      } else if (item['thumbnail'] != null) {
        thumbnailUrl = item['thumbnail'].toString();
      }

      if (thumbnailUrl.isEmpty) return null;

      int durationSecs = item['duration_seconds'] ?? 0;

      return SongModel(
        id: videoId,
        title: item['title'] ?? 'Unknown Title',
        artist: artistName,
        albumArtUrl: thumbnailUrl,
        duration: Duration(seconds: durationSecs),
        streamUrl: '',
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<SongModel>> searchSongs(String query) async {
    // 1. Coba API Vercel dulu
    try {
      final response = await http
          .get(Uri.parse(
              '${ApiConfig.musicApiBaseUrl}/api/search?query=${Uri.encodeComponent(query)}'))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] != null) {
          final List<dynamic> dataList = body['data'];
          final songs = dataList
              .map((item) => _parseSongItem(item))
              .whereType<SongModel>()
              .toList();
          if (songs.isNotEmpty) return songs;
        }
      }
    } catch (_) {}

    // 2. Fallback ke YoutubeExplode
    try {
      final searchResults = await _yt.search.search(query);
      return searchResults
          .take(25)
          .map((video) => SongModel(
                id: video.id.value,
                title: video.title,
                artist: video.author,
                albumArtUrl: video.thumbnails.highResUrl,
                duration: video.duration ?? Duration.zero,
                streamUrl: '',
              ))
          .toList();
    } catch (e) {
      debugPrint('searchSongs error: $e');
      return [];
    }
  }

  Future<Map<String, List<SongModel>>> fetchHomeData() async {
    final Map<String, List<SongModel>> homeData = {};

    // Coba endpoint /api/home dari Vercel untuk sekali request
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.musicApiBaseUrl}/api/home'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] != null) {
          final Map<String, dynamic> dataMap = body['data'];
          dataMap.forEach((key, valueList) {
            final List<dynamic> list = valueList;
            final songs = list
                .map((item) => _parseSongItem(item))
                .whereType<SongModel>()
                .toList();
            if (songs.isNotEmpty) {
              homeData[key] = songs;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('fetchHomeData API error: $e');
    }

    // Jika gagal, fallback ke YoutubeExplode (satu request saja agar cepat)
    if (homeData.isEmpty) {
      try {
        final results = await _yt.search.search('lagu hits indonesia 2024');
        final songs = results
            .take(20)
            .map((v) => SongModel(
                  id: v.id.value,
                  title: v.title,
                  artist: v.author,
                  albumArtUrl: v.thumbnails.highResUrl,
                  duration: v.duration ?? Duration.zero,
                  streamUrl: '',
                ))
            .toList();
        if (songs.isNotEmpty) {
          homeData['Lagu Terpopuler'] = songs;
        }
      } catch (e) {
        debugPrint('fetchHomeData fallback error: $e');
      }
    }

    return homeData;
  }

  /// Try to get a stream URL for a YouTube video.
  /// Returns a Map with 'url' and 'headers' keys.
  Future<Map<String, dynamic>> getStreamUrl(String videoId) async {
    // Cek cache terlebih dahulu
    if (_streamCache.containsKey(videoId)) {
      debugPrint('[Stream] ⚡ Mengambil URL dari cache untuk $videoId');
      return _streamCache[videoId]!;
    }

    // ======= STEP 1: Try Vercel API (server-side extraction) =======
    try {
      debugPrint('[Stream] Step 1: Trying Vercel API for $videoId...');
      final response = await http
          .get(Uri.parse(
              '${ApiConfig.musicApiBaseUrl}/api/stream?video_id=$videoId'))
          .timeout(const Duration(seconds: 25));
      debugPrint('[Stream] Vercel response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' &&
            body['data'] != null &&
            body['data']['url'] != null &&
            (body['data']['url'] as String).isNotEmpty) {
          debugPrint('[Stream] ✅ Vercel API success! Client: ${body['data']['client'] ?? 'unknown'}');
          final result = {'url': body['data']['url'] as String, 'headers': <String, String>{}};
          _streamCache[videoId] = result; // Simpan ke cache
          return result;
        }
      }
      debugPrint('[Stream] Vercel API failed or no URL in response');
    } catch (e) {
      debugPrint('[Stream] Vercel API error: $e');
    }

    // ======= STEP 2: Try YoutubeExplode on-device with ALL clients =======
    // Each client has different anti-bot characteristics.
    // We try them one by one to maximize our chances.
    final clientConfigs = <String, List<YoutubeApiClient>>{
      'mediaConnect': [YoutubeApiClient.mediaConnect],
      'ios': [YoutubeApiClient.ios],
      'tv': [YoutubeApiClient.tv],
      'safari': [YoutubeApiClient.safari],
      'mweb': [YoutubeApiClient.mweb],
      'androidVr': [YoutubeApiClient.androidVr],
      'androidSdkless': [YoutubeApiClient.androidSdkless],
    };

    for (final entry in clientConfigs.entries) {
      try {
        debugPrint('[Stream] Step 2: Trying YoutubeExplode client "${entry.key}" for $videoId...');
        final manifest = await _yt.videos.streamsClient
            .getManifest(videoId, ytClients: entry.value)
            .timeout(const Duration(seconds: 15));
        
        final audioStreams = manifest.audioOnly;
        if (audioStreams.isNotEmpty) {
          final audioStream = audioStreams.withHighestBitrate();
          final url = audioStream.url.toString();
          if (url.isNotEmpty) {
            // Get the matching user-agent from the client config
            final clientPayload = entry.value.first.payload;
            final userAgent = (clientPayload['context'] as Map?)?['client']?['userAgent'] as String? ?? '';
            
            debugPrint('[Stream] ✅ YoutubeExplode "${entry.key}" success! URL length: ${url.length}');
            final result = {
              'url': url,
              'headers': userAgent.isNotEmpty 
                  ? {'User-Agent': userAgent} 
                  : <String, String>{},
            };
            _streamCache[videoId] = result; // Simpan ke cache
            return result;
          }
        }
        debugPrint('[Stream] YoutubeExplode "${entry.key}" returned no audio streams');
      } catch (e) {
        debugPrint('[Stream] YoutubeExplode "${entry.key}" failed: $e');
        // Continue to next client
      }
    }

    debugPrint('[Stream] ❌ ALL methods failed for $videoId');
    return {'url': '', 'headers': <String, String>{}};
  }

  Future<String> getLyrics(String title, String artist, {Duration? duration}) async {
    final cacheKey = '${title}_$artist';
    if (_lyricsCache.containsKey(cacheKey)) {
      debugPrint('[Lyrics] ⚡ Mengambil lirik dari cache untuk $cacheKey');
      return _lyricsCache[cacheKey]!;
    }

    try {
      String cleanTitle = title
          .replaceAll(RegExp(r'\(.*?official.*?\)', caseSensitive: false), '')
          .replaceAll(RegExp(r'\(.*?video.*?\)', caseSensitive: false), '')
          .replaceAll(RegExp(r'\(.*?audio.*?\)', caseSensitive: false), '')
          .replaceAll(RegExp(r'\(.*?lyric.*?\)', caseSensitive: false), '')
          .replaceAll(RegExp(r'\[.*?\]'), '')
          .split(RegExp(r'\(|\|'))
          .first
          .trim();

      String finalArtist = artist;
      String finalTitle = cleanTitle;
      if (cleanTitle.contains(' - ')) {
        final parts = cleanTitle.split(' - ');
        finalArtist = parts[0].trim();
        finalTitle = parts[1].trim();
      }

      // Coba endpoint langsung dulu (lebih akurat)
      if (duration != null && duration.inSeconds > 0) {
        try {
          final directUrl = Uri.parse(
            'https://lrclib.net/api/get'
            '?artist_name=${Uri.encodeComponent(finalArtist)}'
            '&track_name=${Uri.encodeComponent(finalTitle)}'
            '&duration=${duration.inSeconds}'
          );
          final directResp = await http.get(directUrl).timeout(const Duration(seconds: 8));
          if (directResp.statusCode == 200) {
            final track = jsonDecode(directResp.body);
            if (track['syncedLyrics'] != null && track['syncedLyrics'].toString().isNotEmpty) {
              debugPrint('Lyrics from lrclib GET OK (synced)');
              _lyricsCache[cacheKey] = track['syncedLyrics'];
              return track['syncedLyrics'];
            } else if (track['plainLyrics'] != null && track['plainLyrics'].toString().isNotEmpty) {
              debugPrint('Lyrics from lrclib GET OK (plain)');
              _lyricsCache[cacheKey] = track['plainLyrics'];
              return track['plainLyrics'];
            }
          }
        } catch (_) {}
      }

      // Fallback ke search
      final query = Uri.encodeComponent('$finalTitle $finalArtist');
      final url = Uri.parse('https://lrclib.net/api/search?q=$query');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // Cari yang paling cocok berdasarkan durasi jika tersedia
        dynamic bestTrack;
        if (duration != null && duration.inSeconds > 0) {
          final targetSecs = duration.inSeconds;
          int bestDiff = 999999;
          for (var track in data) {
            if (track['syncedLyrics'] != null && track['syncedLyrics'].toString().isNotEmpty) {
              final trackDur = (track['duration'] ?? 0) as num;
              final diff = (trackDur.toInt() - targetSecs).abs();
              if (diff < bestDiff) {
                bestDiff = diff;
                bestTrack = track;
              }
            }
          }
        }
        
        if (bestTrack != null) {
          _lyricsCache[cacheKey] = bestTrack['syncedLyrics'];
          return bestTrack['syncedLyrics'];
        }
        
        for (var track in data) {
          if (track['syncedLyrics'] != null && track['syncedLyrics'].toString().isNotEmpty) {
            _lyricsCache[cacheKey] = track['syncedLyrics'];
            return track['syncedLyrics'];
          }
        }
        
        for (var track in data) {
          if (track['plainLyrics'] != null && track['plainLyrics'].toString().isNotEmpty) {
            _lyricsCache[cacheKey] = track['plainLyrics'];
            return track['plainLyrics'];
          }
        }
      }
      
      // Jika sampai di sini tidak ada lirik ditemukan
      _lyricsCache[cacheKey] = '';
      return '';
    } catch (e) {
      debugPrint('getLyrics error: $e');
      return '';
    }
  }

  Future<Duration> getVideoDuration(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      return video.duration ?? Duration.zero;
    } catch (_) {
      return Duration.zero;
    }
  }
}

// helper for debugPrint
void debugPrint(String msg) {
  // ignore: avoid_print
  print(msg);
}
