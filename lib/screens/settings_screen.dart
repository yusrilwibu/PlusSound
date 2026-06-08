import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../api_config.dart';
import '../theme.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import 'login_screen.dart';
import 'premium_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isTestingConnection = false;
  bool? _connectionStatus;

  Future<void> _testServerConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });
    final ok = await ApiConfig.testConnection();
    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        _connectionStatus = ok;
      });
    }
  }

  Future<void> _pickImage(SettingsProvider settings) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      settings.setProfileImagePath(pickedFile.path);
    }
  }

  bool _isCheckingUpdate = false;

  Future<void> _checkForUpdate() async {
    setState(() => _isCheckingUpdate = true);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.4"

      final dio = Dio();
      final response = await dio.get(
        'https://api.github.com/repos/yusrilwibu/PlusSound/releases/latest',
        options: Options(headers: {'Accept': 'application/vnd.github+json'}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final tagName = response.data['tag_name']?.toString() ?? '';
        final latestVersion = tagName.replaceAll('v', '');
        final releaseNotes = response.data['body']?.toString() ?? 'Tidak ada catatan rilis.';

        // Cari aset APK arm64 (paling umum)
        final assets = response.data['assets'] as List? ?? [];
        final apkAsset = assets.firstWhere(
          (a) => a['name'].toString().contains('arm64'),
          orElse: () => assets.firstWhere(
            (a) => a['name'].toString().endsWith('.apk'),
            orElse: () => null,
          ),
        );

        if (!mounted) return;

        if (_isNewerVersion(currentVersion, latestVersion) && apkAsset != null) {
          // Tampilkan dialog update tersedia
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.system_update_rounded, color: AppTheme.primaryColor, size: 24),
                  SizedBox(width: 10),
                  Text("Update v$latestVersion Tersedia!", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 17)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Versi saat ini: v$currentVersion", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12)),
                    SizedBox(height: 12),
                    Text("📝 Catatan Rilis:", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).textTheme.bodyLarge?.color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(releaseNotes, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Nanti", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.download_rounded, size: 18),
                  label: Text("Update Sekarang"),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _downloadAndInstallApk(
                      apkAsset['browser_download_url'],
                      latestVersion,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          );
        } else if (apkAsset == null && _isNewerVersion(currentVersion, latestVersion)) {
          _showSnackBar("Update tersedia (v$latestVersion) tapi file APK tidak ditemukan di release.");
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 24),
                  SizedBox(width: 10),
                  Text("Sudah Versi Terbaru", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 17)),
                ],
              ),
              content: Text(
                "Aplikasi Anda (v$currentVersion) sudah merupakan versi paling baru. Tidak ada pembaruan.",
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                  child: Text("Oke"),
                ),
              ],
            ),
          );
        }
      }
    } on DioException catch (e) {
      _showSnackBar("Gagal cek pembaruan: ${e.message ?? 'Cek koneksi internet Anda'}");
    } catch (e) {
      _showSnackBar("Gagal memeriksa pembaruan: $e");
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  bool _isNewerVersion(String current, String latest) {
    try {
      final cur = current.split('.').map(int.parse).toList();
      final lat = latest.split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        final c = i < cur.length ? cur[i] : 0;
        final l = i < lat.length ? lat[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _downloadAndInstallApk(String url, String version) async {
    // Dialog progress download
    double progress = 0;
    bool downloadDone = false;
    String statusText = 'Mempersiapkan unduhan...';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.download_rounded, color: AppTheme.primaryColor),
                SizedBox(width: 10),
                Text("Mengunduh v$version", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 8),
                Text(statusText, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)),
                SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: downloadDone ? 1.0 : (progress > 0 ? progress : null),
                    minHeight: 10,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  downloadDone ? '✅ Selesai! Memulai instalasi...' : '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: downloadDone ? Colors.greenAccent : Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/PlusSound_update_v$version.apk';

      final dio = Dio();
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            progress = received / total;
            statusText = 'Mengunduh... ${(received / 1024 / 1024).toStringAsFixed(1)} MB / ${(total / 1024 / 1024).toStringAsFixed(1)} MB';
          }
        },
      );

      downloadDone = true;
      statusText = 'Unduhan selesai! Memulai instalasi...';
      await Future.delayed(const Duration(milliseconds: 800));

      // Install APK
      // Request install packages permission first for Android 8+
      if (Platform.isAndroid) {
        var status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
           _showSnackBar("Izin instalasi ditolak. Silakan izinkan di pengaturan perangkat.");
           return;
        }
      }

      final result = await OpenFile.open(savePath, type: "application/vnd.android.package-archive");
      if (result.type != ResultType.done) {
        _showSnackBar("Gagal membuka installer: ${result.message}");
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar("Gagal mengunduh: $e");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.surfaceColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final auth = Provider.of<app_auth.AuthProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Spotify-style SliverAppBar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.6),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 16),
                      // Avatar (pakai foto dari Firebase jika login)
                      GestureDetector(
                        onTap: () {
                          if (auth.isLoggedIn) {
                            _pickImage(settings);
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                          }
                        },
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: (auth.photoUrl == null && settings.profileImagePath == null)
                                ? const LinearGradient(
                                    colors: [AppTheme.primaryColor, Color(0xFF191414)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            image: (settings.profileImagePath != null)
                                ? DecorationImage(
                                    image: FileImage(File(settings.profileImagePath!)),
                                    fit: BoxFit.cover,
                                  )
                                : (auth.photoUrl != null)
                                    ? DecorationImage(
                                        image: NetworkImage(auth.photoUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: (auth.photoUrl == null && settings.profileImagePath == null)
                              ? Center(
                                  child: Text(
                                    auth.isLoggedIn ? (auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U') : 'G',
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            auth.isLoggedIn ? auth.displayName : 'Tamu',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                          if (auth.isLoggedIn)
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16, color: Colors.white54),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showEditNameDialog(auth),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      if (auth.isLoggedIn && auth.email != null)
                        Text(auth.email!, style: const TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color)),
                      SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: auth.isPremium
                              ? const Color(0xFFFFD700).withOpacity(0.2)
                              : AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: auth.isPremium
                                ? const Color(0xFFFFD700).withOpacity(0.6)
                                : AppTheme.primaryColor.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          auth.isPremium ? '⭐ PlusSound Premium' : '♪ PlusSound Free',
                          style: TextStyle(
                            fontSize: 12,
                            color: auth.isPremium ? const Color(0xFFFFD700) : AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: null,
              centerTitle: true,
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // --- Akun ---
                _sectionHeader("Akun"),
                if (!auth.isLoggedIn)
                  _buildActionTile(
                    icon: Icons.login_rounded,
                    iconColor: AppTheme.primaryColor,
                    title: 'Masuk ke Akun',
                    subtitle: 'Simpan favorit & playlist di cloud',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  ),
                if (auth.isLoggedIn)
                  _buildActionTile(
                    icon: Icons.logout_rounded,
                    iconColor: Colors.redAccent,
                    title: 'Keluar dari Akun',
                    subtitle: auth.email ?? '',
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppTheme.surfaceColor,
                          title: Text('Keluar?', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                          content: Text('Anda yakin ingin keluar dari akun?', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Batal')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              child: Text('Keluar', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) auth.logout();
                    },
                  ),
                if (!auth.isPremium)
                  _buildActionTile(
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFFFD700),
                    title: 'Upgrade ke Premium',
                    subtitle: 'Mulai dari Rp 10.000/bulan',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
                  ),
                if (auth.isPremium)
                  _buildActionTile(
                    icon: Icons.verified_rounded,
                    iconColor: const Color(0xFFFFD700),
                    title: 'Akun Premium Aktif ⭐',
                    subtitle: 'Semua fitur Premium sudah terbuka',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
                  ),

                // --- Tampilan ---
                _sectionHeader("Tampilan"),
                _buildSwitchTile(
                  icon: settings.themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  iconColor: Colors.deepPurpleAccent,
                  title: settings.themeMode == ThemeMode.dark ? "Mode Gelap" : "Mode Terang",
                  subtitle: settings.themeMode == ThemeMode.dark ? "Tema gelap sedang aktif" : "Tema terang sedang aktif",
                  value: settings.themeMode == ThemeMode.dark,
                  onChanged: (v) => settings.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                ),

                // Warna Aksen
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: settings.accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.palette_rounded, color: settings.accentColor, size: 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Warna Aksen", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w500, fontSize: 14)),
                                const Text("Pilih warna tema aplikasi", style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: AppTheme.accentPresets.map((preset) {
                          final color = preset['color'] as Color;
                          final isSelected = settings.accentColor.value == color.value;
                          return GestureDetector(
                            onTap: () => settings.setAccentColor(color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)] : [],
                              ),
                              child: isSelected
                                  ? Icon(Icons.check_rounded, color: Theme.of(context).textTheme.bodyLarge?.color, size: 20)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white10, height: 1),

                // --- Server Status ---
                _sectionHeader("Server & Koneksi"),
                _buildServerStatusCard(),

                const Divider(color: Colors.white10, height: 1),

                // --- Pemutaran ---
                _sectionHeader("Pemutaran"),
                _buildNavTile(
                  icon: Icons.language_rounded,
                  iconColor: Colors.amberAccent,
                  title: "Wilayah Pendengaran",
                  subtitle: settings.region == 'ID' ? 'Indonesia' : (settings.region == 'US' ? 'Global (US)' : settings.region),
                  onTap: () => _showRegionSheet(settings),
                ),
                _buildNavTile(
                  icon: Icons.dashboard_customize_rounded,
                  iconColor: Colors.deepPurpleAccent,
                  title: "Gaya Beranda",
                  subtitle: settings.dashboardStyle == 0 ? "Default" : (settings.dashboardStyle == 1 ? "Kompak" : "Grid"),
                  onTap: () => _showDashboardStyleSheet(settings),
                ),
                _buildNavTile(
                  icon: Icons.palette_rounded,
                  iconColor: Colors.pinkAccent,
                  title: "Tema Player",
                  subtitle: settings.playerTheme == 0 ? "Gradien Transparan" : (settings.playerTheme == 1 ? "Solid (Warna Latar)" : "Vibrant (Full Warna Aksen)"),
                  onTap: () => _showPlayerThemeSheet(settings),
                ),
                _buildSwitchTile(
                  icon: Icons.graphic_eq_rounded,
                  iconColor: AppTheme.primaryColor,
                  title: "Normalisasi Volume",
                  subtitle: "Seimbangkan volume semua lagu secara otomatis",
                  value: settings.normalizeVolume,
                  onChanged: (v) => settings.setNormalizeVolume(v),
                ),
                _buildSwitchTile(
                  icon: Icons.skip_next_rounded,
                  iconColor: Colors.blueAccent,
                  title: "Putar Otomatis",
                  subtitle: "Lanjutkan pemutaran lagu berikutnya secara otomatis",
                  value: settings.autoPlay,
                  onChanged: (v) => settings.setAutoPlay(v),
                ),
                _buildSwitchTile(
                  icon: Icons.lyrics_outlined,
                  iconColor: Colors.purpleAccent,
                  title: "Tampilkan Lirik",
                  subtitle: "Tampilkan lirik lagu saat diputar",
                  value: settings.showLyrics,
                  onChanged: (v) => settings.setShowLyrics(v),
                ),

                const Divider(color: Colors.white10, height: 1),

                // --- Kualitas Audio ---
                _sectionHeader("Kualitas Audio & Penyimpanan"),
                _buildNavTile(
                  icon: Icons.high_quality_rounded,
                  iconColor: Colors.tealAccent,
                  title: "Kualitas Audio",
                  subtitle: settings.audioQuality,
                  onTap: () => _showQualitySheet(settings),
                ),
                _buildNavTile(
                  icon: Icons.sd_storage_rounded,
                  iconColor: Colors.orangeAccent,
                  title: "Lokasi Penyimpanan Unduhan",
                  subtitle: settings.storageLocation == 'sdcard' ? 'SD Card' : 'Penyimpanan Internal',
                  onTap: () => _showStorageSheet(settings),
                ),

                const Divider(color: Colors.white10, height: 1),

                // --- Privasi ---
                _sectionHeader("Privasi & Sosial"),
                _buildNavTile(
                  icon: Icons.history_rounded,
                  iconColor: Colors.white70,
                  title: "Riwayat Pendengaran",
                  subtitle: "Kelola riwayat lagu yang sudah didengar",
                  onTap: () {},
                ),

                const Divider(color: Colors.white10, height: 1),

                // --- Tentang ---
                _sectionHeader("Tentang"),
                _buildNavTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.lightBlueAccent,
                  title: "Tentang PlusSound",
                  subtitle: "Versi saat ini",
                  onTap: _showAboutDialog,
                ),
                ListTile(
                  onTap: _isCheckingUpdate ? null : _checkForUpdate,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isCheckingUpdate
                        ? Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent),
                          )
                        : Icon(Icons.system_update_rounded, color: Colors.greenAccent, size: 20),
                  ),
                  title: Text(
                    "Periksa Pembaruan",
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  subtitle: _isCheckingUpdate 
                      ? Text('Memeriksa versi...', style: TextStyle(color: AppTheme.primaryColor))
                      : Text('Periksa dan unduh pembaruan otomatis', style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12)),
                  trailing: Icon(Icons.chevron_right, color: AppTheme.secondaryTextColor, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                ),
                _buildNavTile(
                  icon: Icons.code_rounded,
                  iconColor: Colors.purpleAccent,
                  title: "Developer",
                  subtitle: "@yusril · GitHub",
                  onTap: () {},
                ),

                SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppTheme.surfaceColor,
          border: Border.all(
            color: _connectionStatus == null
                ? Colors.white12
                : _connectionStatus!
                    ? AppTheme.primaryColor.withOpacity(0.5)
                    : Colors.redAccent.withOpacity(0.5),
          ),
        ),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_done_rounded, color: AppTheme.primaryColor, size: 22),
              ),
              title: Text(
                "PlusSound API Server",
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                "api-yusril-whenyh",
                style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 11),
              ),
              trailing: _buildConnectionBadge(),
            ),
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: _isTestingConnection ? null : _testServerConnection,
                  icon: _isTestingConnection
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                        )
                      : Icon(Icons.compare_arrows_rounded, size: 18),
                  label: Text(
                    _isTestingConnection ? "Memeriksa..." : "Uji Koneksi Server",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionBadge() {
    if (_isTestingConnection) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
      );
    }
    if (_connectionStatus == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text("Belum diperiksa", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 10)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _connectionStatus!
            ? AppTheme.primaryColor.withOpacity(0.2)
            : Colors.redAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _connectionStatus! ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 12,
            color: _connectionStatus! ? AppTheme.primaryColor : Colors.redAccent,
          ),
          SizedBox(width: 4),
          Text(
            _connectionStatus! ? "Online" : "Offline",
            style: TextStyle(
              fontSize: 10,
              color: _connectionStatus! ? AppTheme.primaryColor : Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.secondaryTextColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: AppTheme.secondaryTextColor),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SwitchListTile.adaptive(
        activeThumbColor: AppTheme.primaryColor,
        activeTrackColor: AppTheme.primaryColor.withAlpha(128),
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, color: AppTheme.secondaryTextColor, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }

  void _showQualitySheet(SettingsProvider settings) {
    final auth = Provider.of<app_auth.AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Kualitas Audio",
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            ...["Otomatis", "Rendah (24 kbps)", "Normal (96 kbps)", "Tinggi (160 kbps)", "Sangat Tinggi (320 kbps)"]
                .map((q) {
              final isPremiumOption = q.contains("Tinggi") || q.contains("Sangat");
              final isLocked = isPremiumOption && !auth.isPremium;

              return ListTile(
                title: Row(
                  children: [
                    Text(q, style: TextStyle(color: isLocked ? Colors.white54 : Colors.white)),
                    if (isPremiumOption) ...[
                      SizedBox(width: 8),
                      Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 14),
                    ]
                  ],
                ),
                trailing: settings.audioQuality == q
                    ? Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor)
                    : (isLocked ? Icon(Icons.lock_outline, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20) : null),
                onTap: () {
                  if (isLocked) {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
                    return;
                  }
                  settings.setAudioQuality(q);
                  Navigator.pop(ctx);
                },
              );
            }),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showStorageSheet(SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Lokasi Penyimpanan",
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            ListTile(
              title: Text("Penyimpanan Internal", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
              trailing: settings.storageLocation == 'internal'
                  ? Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                settings.setStorageLocation('internal');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text("SD Card", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
              trailing: settings.storageLocation == 'sdcard'
                  ? Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                settings.setStorageLocation('sdcard');
                Navigator.pop(ctx);
              },
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRegionSheet(SettingsProvider settings) {
    final Map<String, String> regions = {
      'ID': 'Indonesia',
      'US': 'Global (Amerika Serikat)',
      'JP': 'Jepang',
      'KR': 'Korea Selatan',
      'GB': 'Inggris (UK)',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Wilayah Pendengaran', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...regions.entries.map((e) => ListTile(
                title: Text(e.value, style: const TextStyle(color: Colors.white)),
                trailing: settings.region == e.key ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  settings.setRegion(e.key);
                  Navigator.pop(ctx);
                  _showSnackBar("Wilayah diubah ke ${e.value}. Muat ulang beranda untuk melihat perubahan.");
                },
              )),
            ],
          ),
        );
      },
    );
  }

  void _showDashboardStyleSheet(SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Gaya Beranda', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: const Text('Default', style: TextStyle(color: Colors.white)),
                trailing: settings.dashboardStyle == 0 ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  settings.setDashboardStyle(0);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Kompak', style: TextStyle(color: Colors.white)),
                trailing: settings.dashboardStyle == 1 ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  settings.setDashboardStyle(1);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Grid', style: TextStyle(color: Colors.white)),
                trailing: settings.dashboardStyle == 2 ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  settings.setDashboardStyle(2);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlayerThemeSheet(SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Tema Player', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: const Text('Gradien Transparan (Default)', style: TextStyle(color: Colors.white)),
                trailing: settings.playerTheme == 0 ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  settings.setPlayerTheme(0);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Solid (Warna Latar)', style: TextStyle(color: Colors.white)),
                trailing: settings.playerTheme == 1 ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  settings.setPlayerTheme(1);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Vibrant (Full Warna Aksen)', style: TextStyle(color: Colors.white)),
                trailing: settings.playerTheme == 2 ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  settings.setPlayerTheme(2);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.music_note_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text("PlusSound", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.hasData ? snapshot.data!.version : "1.0.1";
                return Text("Versi $version", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color));
              }
            ),
            SizedBox(height: 8),
            Text(
              "Aplikasi streaming musik berbasis Flutter dengan integrasi YouTube Music dan Vercel API.",
              style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 13, height: 1.5),
            ),
            SizedBox(height: 12),
            Text("Developer: @yusril", style: TextStyle(color: AppTheme.primaryColor, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Tutup", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
