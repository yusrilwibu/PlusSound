import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _audioQualityKey = 'audio_quality';
  static const String _storageKey = 'download_storage_location';
  static const String _normalizeVolumeKey = 'normalize_volume';
  static const String _autoPlayKey = 'auto_play';
  static const String _showLyricsKey = 'show_lyrics';
  static const String _profileImageKey = 'profile_image_path';

  ThemeMode _themeMode = ThemeMode.dark;
  String _audioQuality = 'Otomatis';
  String _storageLocation = 'internal';
  bool _normalizeVolume = true;
  bool _autoPlay = true;
  bool _showLyrics = true;
  String? _profileImagePath;

  ThemeMode get themeMode => _themeMode;
  String get audioQuality => _audioQuality;
  String get storageLocation => _storageLocation;
  bool get normalizeVolume => _normalizeVolume;
  bool get autoPlay => _autoPlay;
  bool get showLyrics => _showLyrics;
  String? get profileImagePath => _profileImagePath;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_themeModeKey) ?? 0;
    _themeMode = ThemeMode.values[modeIndex];
    _audioQuality = prefs.getString(_audioQualityKey) ?? 'Otomatis';
    _storageLocation = prefs.getString(_storageKey) ?? 'internal';
    _normalizeVolume = prefs.getBool(_normalizeVolumeKey) ?? true;
    _autoPlay = prefs.getBool(_autoPlayKey) ?? true;
    _showLyrics = prefs.getBool(_showLyricsKey) ?? true;
    _profileImagePath = prefs.getString(_profileImageKey);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setAudioQuality(String quality) async {
    _audioQuality = quality;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_audioQualityKey, quality);
  }

  Future<void> setStorageLocation(String location) async {
    _storageLocation = location;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, location);
  }

  Future<void> setNormalizeVolume(bool val) async {
    _normalizeVolume = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_normalizeVolumeKey, val);
  }

  Future<void> setAutoPlay(bool val) async {
    _autoPlay = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoPlayKey, val);
  }

  Future<void> setShowLyrics(bool val) async {
    _showLyrics = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showLyricsKey, val);
  }

  Future<void> setProfileImagePath(String? path) async {
    _profileImagePath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_profileImageKey);
    } else {
      await prefs.setString(_profileImageKey, path);
    }
  }
}
