import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1DB954);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF282828);
  static const Color textColor = Colors.white;
  static const Color secondaryTextColor = Color(0xFFB3B3B3);

  // Preset accent colors untuk kustomisasi
  static const List<Map<String, dynamic>> accentPresets = [
    {'name': 'Hijau Spotify', 'color': Color(0xFF1DB954)},
    {'name': 'Biru Elektrik', 'color': Color(0xFF0EA5E9)},
    {'name': 'Ungu Neon', 'color': Color(0xFFA855F7)},
    {'name': 'Merah Marun', 'color': Color(0xFFEF4444)},
    {'name': 'Oranye Sunset', 'color': Color(0xFFF97316)},
    {'name': 'Pink Flamingo', 'color': Color(0xFFEC4899)},
    {'name': 'Kuning Emas', 'color': Color(0xFFEAB308)},
    {'name': 'Tosca', 'color': Color(0xFF14B8A6)},
  ];

  static ThemeData buildDarkTheme({Color accent = primaryColor}) {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accent,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.dark(
        primary: accent,
        surface: surfaceColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: accent,
        unselectedItemColor: secondaryTextColor,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        thumbColor: accent,
        inactiveTrackColor: accent.withOpacity(0.3),
        overlayColor: accent.withOpacity(0.2),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: secondaryTextColor),
      ),
    );
  }

  static ThemeData buildLightTheme({Color accent = primaryColor}) {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: accent,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      colorScheme: ColorScheme.light(
        primary: accent,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF121212)),
        titleTextStyle: TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.bold, fontSize: 20),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: accent,
        unselectedItemColor: const Color(0xFFB3B3B3),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        thumbColor: accent,
        inactiveTrackColor: accent.withOpacity(0.3),
        overlayColor: accent.withOpacity(0.2),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF121212)),
        bodyMedium: TextStyle(color: Color(0xFF535353)),
      ),
    );
  }

  // Backward compat getters
  static ThemeData get darkTheme => buildDarkTheme();
  static ThemeData get lightTheme => buildLightTheme();
}
