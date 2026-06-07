import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/download_service.dart';

class DownloadProvider with ChangeNotifier {
  final DownloadService _service = DownloadService();

  // songId -> progress (0.0 - 1.0), null means not downloading
  final Map<String, double?> _progresses = {};
  // songId -> downloaded or not
  final Map<String, bool> _downloaded = {};
  // songId -> error message
  final Map<String, String> _errors = {};

  List<Map<String, dynamic>> _downloadedSongs = [];
  List<Map<String, dynamic>> get downloadedSongs => _downloadedSongs;

  DownloadProvider() {
    _loadDownloaded();
  }

  Future<void> _loadDownloaded() async {
    _downloadedSongs = await _service.getDownloadedSongs();
    for (final m in _downloadedSongs) {
      final id = m['id'] as String?;
      if (id != null) _downloaded[id] = true;
    }
    notifyListeners();
  }

  bool isDownloaded(String songId) => _downloaded[songId] ?? false;
  bool isDownloading(String songId) => _progresses.containsKey(songId);
  double? getProgress(String songId) => _progresses[songId];
  String? getError(String songId) => _errors[songId];

  Future<void> download(SongModel song) async {
    if (isDownloaded(song.id) || isDownloading(song.id)) return;
    _progresses[song.id] = 0.0;
    _errors.remove(song.id);
    notifyListeners();

    final error = await _service.downloadSong(
      song,
      onProgress: (p) {
        _progresses[song.id] = p;
        notifyListeners();
      },
    );

    _progresses.remove(song.id);
    if (error == null) {
      _downloaded[song.id] = true;
      await _loadDownloaded();
    } else {
      _errors[song.id] = error;
    }
    notifyListeners();
  }

  Future<void> deleteDownload(String songId) async {
    await _service.deleteDownload(songId);
    _downloaded.remove(songId);
    _downloadedSongs.removeWhere((m) => m['id'] == songId);
    notifyListeners();
  }

  Future<String?> getLocalPath(String songId) => _service.getLocalPath(songId);
}
