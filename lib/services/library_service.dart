import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

class LibraryService {
  static const String _libraryKey = 'library_songs';

  Future<List<SongModel>> getLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_libraryKey) ?? [];
    return raw.map((s) {
      try {
        return SongModel.fromMap(jsonDecode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<SongModel>().toList();
  }

  Future<void> addToLibrary(SongModel song) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_libraryKey) ?? [];
    // Avoid duplicates
    final existing = raw.map((s) {
      try {
        return SongModel.fromMap(jsonDecode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<SongModel>().toList();
    if (existing.any((s) => s.id == song.id)) return;
    raw.insert(0, jsonEncode(song.toMap()));
    await prefs.setStringList(_libraryKey, raw);
  }

  Future<void> removeFromLibrary(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_libraryKey) ?? [];
    final updated = raw.where((s) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        return map['id'] != songId;
      } catch (_) {
        return true;
      }
    }).toList();
    await prefs.setStringList(_libraryKey, updated);
  }

  Future<bool> isInLibrary(String songId) async {
    final lib = await getLibrary();
    return lib.any((s) => s.id == songId);
  }
}
