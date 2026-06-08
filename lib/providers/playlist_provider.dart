import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';

class PlaylistProvider with ChangeNotifier {
  static const String _playlistsKey = 'user_playlists';
  List<PlaylistModel> _playlists = [];

  List<PlaylistModel> get playlists => _playlists;

  PlaylistProvider() {
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_playlistsKey);
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        _playlists = decoded.map((e) => PlaylistModel.fromMap(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    }
  }

  Future<void> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_playlists.map((e) => e.toMap()).toList());
      await prefs.setString(_playlistsKey, encoded);
    } catch (e) {
      debugPrint('Error saving playlists: $e');
    }
  }

  Future<void> createPlaylist(String name) async {
    final newPlaylist = PlaylistModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songs: [],
      createdAt: DateTime.now(),
    );
    _playlists.add(newPlaylist);
    notifyListeners();
    await _savePlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
    notifyListeners();
    await _savePlaylists();
  }

  Future<void> addSongToPlaylist(String playlistId, SongModel song) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = _playlists[index];
      // Check if song already exists
      if (!playlist.songs.any((s) => s.id == song.id)) {
        final updatedSongs = List<SongModel>.from(playlist.songs)..add(song);
        _playlists[index] = playlist.copyWith(
          songs: updatedSongs,
          coverUrl: playlist.coverUrl ?? song.albumArtUrl, // Use first song's art as cover if null
        );
        notifyListeners();
        await _savePlaylists();
      }
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = _playlists[index];
      final updatedSongs = List<SongModel>.from(playlist.songs)..removeWhere((s) => s.id == songId);
      
      // Update cover if the removed song was the cover
      String? newCoverUrl = playlist.coverUrl;
      if (updatedSongs.isEmpty) {
        newCoverUrl = null;
      } else if (playlist.songs.firstWhere((s) => s.id == songId, orElse: () => playlist.songs.first).albumArtUrl == playlist.coverUrl) {
         newCoverUrl = updatedSongs.first.albumArtUrl;
      }

      _playlists[index] = playlist.copyWith(
        songs: updatedSongs,
        coverUrl: newCoverUrl,
      );
      notifyListeners();
      await _savePlaylists();
    }
  }
}
