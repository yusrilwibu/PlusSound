import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../models/song_model.dart';
import '../providers/audio_provider.dart';
import '../services/music_service.dart' as music_svc;
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final music_svc.MusicService _musicService = music_svc.MusicService();
  bool _isLoading = false;
  Map<String, List<SongModel>> _homeData = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _loadHomeData();
  }

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('home_data_cache');
      if (cachedString != null) {
        final Map<String, dynamic> decoded = jsonDecode(cachedString);
        final Map<String, List<SongModel>> parsedData = {};
        decoded.forEach((key, value) {
          final List<dynamic> list = value;
          parsedData[key] = list.map((item) => SongModel.fromMap(item)).toList();
        });
        if (mounted) {
          setState(() {
            _homeData = parsedData;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading home cache: $e');
    }
  }

  Future<void> _saveToCache(Map<String, List<SongModel>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> encoded = {};
      data.forEach((key, value) {
        encoded[key] = value.map((song) => song.toMap()).toList();
      });
      await prefs.setString('home_data_cache', jsonEncode(encoded));
    } catch (e) {
      debugPrint('Error saving home cache: $e');
    }
  }

  Future<void> _loadHomeData() async {
    if (_homeData.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await _musicService.fetchHomeData();
      if (mounted) {
        setState(() {
          if (data.isNotEmpty) {
            _homeData = data;
            _saveToCache(data); // Simpan ke cache
          }
          _isLoading = false;
          if (_homeData.isEmpty) {
            _errorMessage = "Gagal memuat lagu dari server. Periksa kembali URL API Anda.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_homeData.isEmpty) {
            _errorMessage = "Terjadi kesalahan: $e";
          }
        });
      }
    }
  }

  String _getCategoryTitle(String key) {
    return key; // Nama kategori sudah dalam bahasa yang dimengerti
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.25),
              AppTheme.backgroundColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppTheme.primaryColor,
            backgroundColor: AppTheme.surfaceColor,
            onRefresh: _loadHomeData,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "PlusSound",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.settings_outlined, color: Colors.white),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                );
                                _loadHomeData();
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),

                // Main Content
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    ),
                  )
                else if (_errorMessage != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _loadHomeData,
                              icon: const Icon(Icons.refresh),
                              label: const Text("Coba Lagi"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_homeData.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        "Tidak ada data lagu tersedia.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                else
                  // Featured banner
                  SliverToBoxAdapter(
                    child: _homeData.values.any((l) => l.isNotEmpty)
                        ? _buildFeaturedBanner(
                            _homeData.values.firstWhere((l) => l.isNotEmpty).first)
                        : const SizedBox.shrink(),
                  ),

                // Dynamic category sections - lazy rendered
                if (!_isLoading && _errorMessage == null && _homeData.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final key = _homeData.keys.elementAt(index);
                        final songs = _homeData[key] ?? [];
                        if (songs.isEmpty) return const SizedBox.shrink();
                        return RepaintBoundary(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16.0, top: 20.0, bottom: 12.0),
                                child: Text(
                                  _getCategoryTitle(key),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 185,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: songs.length,
                                  itemBuilder: (context, songIndex) {
                                    return _buildSongCard(songs[songIndex]);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: _homeData.length,
                    ),
                  ),

                // Bottom spacer for miniplayer
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildFeaturedBanner(SongModel song) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    return GestureDetector(
      onTap: () => audioProvider.playSong(song),
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.surfaceColor, // Fallback color
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
          image: DecorationImage(
            image: song.albumArtUrl.isNotEmpty
                ? CachedNetworkImageProvider(song.albumArtUrl, maxWidth: 400, maxHeight: 400)
                : const AssetImage('assets/profil.jpg') as ImageProvider,
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text("TREN SEKARANG", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSongCard(SongModel song) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    return GestureDetector(
      onTap: () {
        audioProvider.playSong(song);
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Art
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: song.albumArtUrl,
                width: 130,
                height: 120,
                memCacheWidth: 200,
                memCacheHeight: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.surfaceColor,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.surfaceColor,
                  child: const Icon(Icons.music_note, color: Colors.white30, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            // Artist
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
