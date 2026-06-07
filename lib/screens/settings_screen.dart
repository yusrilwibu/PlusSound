import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../api_config.dart';
import '../theme.dart';
import '../providers/settings_provider.dart';

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
  double _updateProgress = 0.0;

  Future<void> _checkForUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateProgress = 0.0;
    });

    try {
      // Dapatkan versi aplikasi saat ini
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.1"

      // Cek versi terbaru di GitHub Releases
      final dio = Dio();
      final response = await dio.get('https://api.github.com/repos/yusrilwibu/PlusSound/releases/latest');
      if (response.statusCode == 200) {
        final latestVersion = response.data['tag_name'].toString().replaceAll('v', '');
        
        if (_isNewerVersion(currentVersion, latestVersion)) {
          // Cari aset APK
          final assets = response.data['assets'] as List;
          final apkAsset = assets.firstWhere(
            (asset) => asset['name'].toString().endsWith('.apk'),
            orElse: () => null,
          );

          if (apkAsset != null) {
            final downloadUrl = apkAsset['browser_download_url'];
            await _downloadAndInstallApk(downloadUrl, latestVersion);
          } else {
            _showSnackBar("Tidak menemukan file APK pada rilis terbaru.");
          }
        } else {
          _showSnackBar("Aplikasi Anda sudah versi terbaru ($currentVersion).");
        }
      }
    } catch (e) {
      _showSnackBar("Gagal memeriksa pembaruan: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  bool _isNewerVersion(String current, String latest) {
    try {
      final curParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        final c = i < curParts.length ? curParts[i] : 0;
        final l = i < latestParts.length ? latestParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _downloadAndInstallApk(String url, String version) async {
    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/PlusSound_v$version.apk';

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _updateProgress = received / total;
            });
          }
        },
      );

      _showSnackBar("Unduhan selesai. Menginstal...");
      final result = await OpenFile.open(savePath);
      if (result.type != ResultType.done) {
        _showSnackBar("Gagal menginstal: ${result.message}");
      }
    } catch (e) {
      _showSnackBar("Gagal mengunduh pembaruan: $e");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.surfaceColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

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
                      const SizedBox(height: 16),
                      // Avatar
                      GestureDetector(
                        onTap: () => _pickImage(settings),
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: settings.profileImagePath == null
                                ? const LinearGradient(
                                    colors: [AppTheme.primaryColor, Color(0xFF191414)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            image: settings.profileImagePath != null
                                ? DecorationImage(
                                    image: FileImage(File(settings.profileImagePath!)),
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
                          child: settings.profileImagePath == null
                              ? const Center(
                                  child: Text(
                                    "Y",
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Yusril",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5)),
                        ),
                        child: const Text(
                          "✦  PlusSound Premium",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
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

                const Divider(color: Colors.white10, height: 1),

                // --- Server Status ---
                _sectionHeader("Server & Koneksi"),
                _buildServerStatusCard(),

                const Divider(color: Colors.white10, height: 1),

                // --- Pemutaran ---
                _sectionHeader("Pemutaran"),
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
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent),
                          )
                        : const Icon(Icons.system_update_rounded, color: Colors.greenAccent, size: 20),
                  ),
                  title: const Text(
                    "Periksa Pembaruan",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  subtitle: _isCheckingUpdate && _updateProgress > 0
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: _updateProgress,
                              backgroundColor: Colors.white12,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(height: 4),
                            Text("Mengunduh: ${(_updateProgress * 100).toStringAsFixed(0)}%", style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 11)),
                          ],
                        )
                      : const Text(
                          "Periksa dan unduh pembaruan otomatis",
                          style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12),
                        ),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.secondaryTextColor, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                ),
                _buildNavTile(
                  icon: Icons.code_rounded,
                  iconColor: Colors.purpleAccent,
                  title: "Developer",
                  subtitle: "@yusril · GitHub",
                  onTap: () {},
                ),

                const SizedBox(height: 100),
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
                child: const Icon(Icons.cloud_done_rounded, color: AppTheme.primaryColor, size: 22),
              ),
              title: const Text(
                "PlusSound API Server",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text(
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
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                        )
                      : const Icon(Icons.compare_arrows_rounded, size: 18),
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
      return const SizedBox(
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
        child: const Text("Belum diperiksa", style: TextStyle(color: Colors.white54, fontSize: 10)),
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
          const SizedBox(width: 4),
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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.secondaryTextColor, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }

  void _showQualitySheet(SettingsProvider settings) {
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
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Kualitas Audio",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...["Otomatis", "Rendah (24 kbps)", "Normal (96 kbps)", "Tinggi (160 kbps)", "Sangat Tinggi (320 kbps)"]
                .map((q) => ListTile(
                      title: Text(q, style: const TextStyle(color: Colors.white)),
                      trailing: settings.audioQuality == q
                          ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor)
                          : null,
                      onTap: () {
                        settings.setAudioQuality(q);
                        Navigator.pop(ctx);
                      },
                    )),
            const SizedBox(height: 8),
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
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Lokasi Penyimpanan",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text("Penyimpanan Internal", style: TextStyle(color: Colors.white)),
              trailing: settings.storageLocation == 'internal'
                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                settings.setStorageLocation('internal');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text("SD Card", style: TextStyle(color: Colors.white)),
              trailing: settings.storageLocation == 'sdcard'
                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                settings.setStorageLocation('sdcard');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.music_note_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text("PlusSound", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.hasData ? snapshot.data!.version : "1.0.1";
                return Text("Versi $version", style: const TextStyle(color: Colors.white70));
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
            child: const Text("Tutup", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
