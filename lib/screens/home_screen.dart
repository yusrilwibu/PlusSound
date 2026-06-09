import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import '../models/song_model.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../providers/download_provider.dart';
import '../services/music_service.dart';
import 'settings_screen.dart';
import '../widgets/song_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MusicService _musicService = MusicService();
  bool _isLoading = false;
  Map<String, List<SongModel>> _homeData = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _musicService.fetchHomeData();
      if (mounted) {
        setState(() {
          _homeData = data;
          _isLoading = false;
          if (data.isEmpty) _errorMessage = 'Gagal memuat lagu dari server.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan: $e';
        });
      }
    }
  }

  String _getCategoryTitle(String key) {
    const titles = {
      'recent': 'Lagu Hits Terpopuler',
      'anyar': 'Rilis Anyar',
      'gembira': 'Pembangkit Mood',
      'charts': 'Top 50 Indonesia',
      'galau': 'Teman Galau',
      'baru': 'Lagu Viral 2026',
      'tiktok': 'FYP TikTok Hits',
      'artists': 'Penyanyi Paling Hits',
    };
    return titles[key.toLowerCase()] ?? (key[0].toUpperCase() + key.substring(1));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final bgColor = isDark ? AppTheme.backgroundColor : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
              bgColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppTheme.primaryColor,
            backgroundColor: isDark ? AppTheme.surfaceColor : Colors.white,
            onRefresh: _loadHomeData,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ClipOval(
                              child: Image.asset('profil.jpg', width: 36, height: 36, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'PlusSound',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.settings_outlined, color: textColor),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            );
                            _loadHomeData();
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Content ──
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                  )
                else if (_errorMessage != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                            const SizedBox(height: 16),
                            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _loadHomeData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
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
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final key = _homeData.keys.elementAt(i);
                        final songs = _homeData[key] ?? [];
                        if (songs.isEmpty) return const SizedBox.shrink();
                        return _CategorySection(
                          title: _getCategoryTitle(key),
                          songs: songs,
                        );
                      },
                      childCount: _homeData.keys.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List<SongModel> songs;

  const _CategorySection({required this.title, required this.songs});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 20, bottom: 10, right: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF121212),
            ),
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: songs.length,
            itemBuilder: (context, index) => _SongCard(song: songs[index], queue: songs, queueIndex: index),
          ),
        ),
      ],
    );
  }
}

class _SongCard extends StatelessWidget {
  final SongModel song;
  final List<SongModel> queue;
  final int queueIndex;

  const _SongCard({required this.song, required this.queue, required this.queueIndex});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final libraryProvider = context.read<LibraryProvider>();
    final downloadProvider = context.read<DownloadProvider>();
    final isPlaying = audioProvider.currentSong?.id == song.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        audioProvider.playSong(song, queue: queue, queueIndex: queueIndex);
      },
      onLongPress: () {
        _showOptions(context, libraryProvider, downloadProvider);
      },
      child: Container(
        width: 132,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: song.albumArtUrl,
                    width: 132,
                    height: 132,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppTheme.surfaceColor,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.surfaceColor,
                      child: const Icon(Icons.music_note, color: Colors.white30, size: 40),
                    ),
                  ),
                ),
                if (isPlaying)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.equalizer, color: AppTheme.primaryColor, size: 30),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isPlaying ? AppTheme.primaryColor : (isDark ? Colors.white : const Color(0xFF121212)),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, LibraryProvider lib, DownloadProvider dl) {
    final inLib = lib.isInLibrary(song.id);
    final isDl = dl.isDownloaded(song.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(inLib ? Icons.favorite : Icons.favorite_border, color: inLib ? AppTheme.primaryColor : Colors.white),
              title: Text(inLib ? 'Hapus dari Library' : 'Simpan ke Library', style: const TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); lib.toggle(song); },
            ),
            ListTile(
              leading: Icon(isDl ? Icons.download_done : Icons.download_outlined, color: isDl ? AppTheme.primaryColor : Colors.white),
              title: Text(isDl ? 'Sudah Diunduh' : 'Unduh Offline', style: const TextStyle(color: Colors.white)),
              onTap: isDl ? null : () { Navigator.pop(context); dl.download(song); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
