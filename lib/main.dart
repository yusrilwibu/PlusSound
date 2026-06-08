import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme.dart';
import 'screens/main_screen.dart';
import 'services/audio_handler.dart';
import 'providers/audio_provider.dart';
import 'providers/library_provider.dart';
import 'providers/download_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart' as app_auth;

late MyAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Inisialisasi Firebase (akan error jika google-services.json belum ada)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.yusril.plussound.channel.audio',
      androidNotificationChannelName: 'PlusSound',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      notificationColor: Color(0xFF1DB954),
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider(audioHandler)),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'PlusSound',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: const MainScreen(),
    );
  }
}
