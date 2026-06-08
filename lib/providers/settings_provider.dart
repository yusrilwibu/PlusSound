import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _audioQualityKey = 'audio_quality';
  static const String _storageKey = 'download_storage_location';
  static const String _normalizeVolumeKey = 'normalize_volume';
  static const String _autoPlayKey = 'auto_play';
  static const String _showLyricsKey = 'show_lyrics';
  static const String _profileImageKey = 'profile_image_path';
  static const String _accentColorKey = 'accent_color';
  static const String _regionKey = 'listening_region';
  static const String _dashboardStyleKey = 'dashboard_style';
  static const String _playerThemeKey = 'player_theme';

  ThemeMode _themeMode = ThemeMode.dark;
  String _audioQuality = 'Otomatis';
  String _storageLocation = 'internal';
  bool _normalizeVolume = true;
  bool _autoPlay = true;
  bool _showLyrics = true;
  String? _profileImagePath;
  int _accentColorValue = 0xFF1DB954; // Default: Green (Spotify)
  String _region = 'ID'; // Default: Indonesia
  int _dashboardStyle = 0; // 0: Default, 1: Compact, 2: Grid
  int _playerTheme = 0; // 0: Gradient, 1: Solid, 2: Vibrant

  ThemeMode get themeMode => _themeMode;
  String get audioQuality => _audioQuality;
  String get storageLocation => _storageLocation;
  bool get normalizeVolume => _normalizeVolume;
  bool get autoPlay => _autoPlay;
  bool get showLyrics => _showLyrics;
  String? get profileImagePath => _profileImagePath;
  Color get accentColor => Color(_accentColorValue);
  String get region => _region;
  int get dashboardStyle => _dashboardStyle;
  int get playerTheme => _playerTheme;

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
    _accentColorValue = prefs.getInt(_accentColorKey) ?? 0xFF1DB954;
    _region = prefs.getString(_regionKey) ?? 'ID';
    _dashboardStyle = prefs.getInt(_dashboardStyleKey) ?? 0;
    _playerTheme = prefs.getInt(_playerThemeKey) ?? 0;

    // Restore profile image from permanent storage
    final savedPath = prefs.getString(_profileImageKey);
    if (savedPath != null && File(savedPath).existsSync()) {
      _profileImagePath = savedPath;
    } else {
      _profileImagePath = null;
    }

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

  /// Menyimpan foto profil ke penyimpanan permanen aplikasi agar tidak hilang
  Future<void> setProfileImagePath(String? tempPath) async {
    final prefs = await SharedPreferences.getInstance();
    if (tempPath == null) {
      _profileImagePath = null;
      await prefs.remove(_profileImageKey);
      notifyListeners();
      return;
    }

    try {
      // Salin dari temporary cache ke permanent Documents dir
      final appDir = await getApplicationDocumentsDirectory();
      final permanentDir = Directory('${appDir.path}/profile');
      if (!permanentDir.existsSync()) {
        permanentDir.createSync(recursive: true);
      }
      final permanentPath = '${permanentDir.path}/avatar.jpg';
      final sourceFile = File(tempPath);
      if (sourceFile.existsSync()) {
        await sourceFile.copy(permanentPath);
        _profileImagePath = permanentPath;
        await prefs.setString(_profileImageKey, permanentPath);
      }
    } catch (e) {
      // Fallback: simpan path aslinya
      _profileImagePath = tempPath;
      await prefs.setString(_profileImageKey, tempPath);
    }
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColorValue = color.value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, _accentColorValue);
  }

  Future<void> setRegion(String region) async {
    _region = region;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionKey, region);
  }

  Future<void> setDashboardStyle(int style) async {
    _dashboardStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dashboardStyleKey, style);
  }

  Future<void> setPlayerTheme(int theme) async {
    _playerTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_playerThemeKey, theme);
  }
}
