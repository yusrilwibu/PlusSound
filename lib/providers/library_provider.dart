import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/library_service.dart';

class LibraryProvider with ChangeNotifier {
  final LibraryService _service = LibraryService();
  List<SongModel> _songs = [];
  bool _loaded = false;

  List<SongModel> get songs => _songs;
  bool get loaded => _loaded;

  LibraryProvider() {
    load();
  }

  Future<void> load() async {
    _songs = await _service.getLibrary();
    _loaded = true;
    notifyListeners();
  }

  bool isInLibrary(String songId) {
    return _songs.any((s) => s.id == songId);
  }

  Future<void> addSong(SongModel song) async {
    if (isInLibrary(song.id)) return;
    await _service.addToLibrary(song);
    _songs.insert(0, song);
    notifyListeners();
  }

  Future<void> removeSong(String songId) async {
    await _service.removeFromLibrary(songId);
    _songs.removeWhere((s) => s.id == songId);
    notifyListeners();
  }

  Future<void> toggle(SongModel song) async {
    if (isInLibrary(song.id)) {
      await removeSong(song.id);
    } else {
      await addSong(song);
    }
  }
}
