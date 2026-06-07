import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import 'music_service.dart';

class DownloadService {
  static const String _downloadedKey = 'downloaded_songs';
  static const String _storageKey = 'download_storage_location';
  final Dio _dio = Dio();
  final MusicService _musicService = MusicService();

  // Lokasi penyimpanan: 'internal' atau 'sdcard'
  Future<String> getStorageLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageKey) ?? 'internal';
  }

  Future<void> setStorageLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, location);
  }

  Future<String> _getDownloadDir() async {
    final location = await getStorageLocation();
    Directory? dir;
    if (location == 'sdcard') {
      try {
        final extDirs = await getExternalStorageDirectories();
        if (extDirs != null && extDirs.length > 1) {
          dir = Directory('${extDirs[1].path}/PlusSound');
        }
      } catch (_) {}
    }
    dir ??= Directory('${(await getApplicationDocumentsDirectory()).path}/PlusSound');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<List<Map<String, dynamic>>> getDownloadedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_downloadedKey) ?? [];
    return raw.map((s) {
      try {
        return jsonDecode(s) as Map<String, dynamic>;
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((m) => m.isNotEmpty).toList();
  }

  Future<bool> isDownloaded(String songId) async {
    final list = await getDownloadedSongs();
    return list.any((m) => m['id'] == songId);
  }

  Future<String?> getLocalPath(String songId) async {
    final list = await getDownloadedSongs();
    final match = list.firstWhere(
      (m) => m['id'] == songId,
      orElse: () => <String, dynamic>{},
    );
    if (match.isEmpty) return null;
    final path = match['localPath'] as String?;
    if (path != null && await File(path).exists()) return path;
    return null;
  }

  /// Download lagu. Returns null if success, error string if fail.
  Future<String?> downloadSong(
    SongModel song, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Cek apakah sudah didownload
      if (await isDownloaded(song.id)) return null;

      // Dapatkan stream URL
      String streamUrl = song.streamUrl;
      if (streamUrl.isEmpty) {
        final data = await _musicService.getStreamUrl(song.id);
        streamUrl = (data['url'] as String?)?.trim() ?? '';
      }
      if (streamUrl.isEmpty) return 'Gagal mendapatkan URL audio';

      final dir = await _getDownloadDir();
      final fileName = '${song.id}.m4a';
      final filePath = '$dir/$fileName';

      await _dio.download(
        streamUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
          headers: {'User-Agent': 'Mozilla/5.0'},
        ),
      );

      // Simpan metadata
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_downloadedKey) ?? [];
      final meta = song.toMap();
      meta['localPath'] = filePath;
      raw.insert(0, jsonEncode(meta));
      await prefs.setStringList(_downloadedKey, raw);

      return null; // success
    } catch (e) {
      return 'Download gagal: $e';
    }
  }

  Future<void> deleteDownload(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_downloadedKey) ?? [];
    String? pathToDelete;
    final updated = raw.where((s) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        if (m['id'] == songId) {
          pathToDelete = m['localPath'] as String?;
          return false;
        }
        return true;
      } catch (_) {
        return true;
      }
    }).toList();
    await prefs.setStringList(_downloadedKey, updated);
    if (pathToDelete != null) {
      final f = File(pathToDelete!);
      if (await f.exists()) await f.delete();
    }
  }
}
