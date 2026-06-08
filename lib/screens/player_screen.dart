import 'package:flutter/material.dart' hide RepeatMode;
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../providers/download_provider.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:share_plus/share_plus.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _showMoreMenu(BuildContext context, AudioProvider audioProvider) {
    final song = audioProvider.currentSong;
    if (song == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: song.albumArtUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            song.artist,
                            style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Colors.white),
                title: const Text('Bagikan', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  Share.share('Dengarkan ${song.title} oleh ${song.artist} di PlusSound!\nhttps://youtu.be/${song.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: Colors.white),
                title: const Text('Pengatur Waktu Tidur', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Pengatur Waktu Tidur akan segera hadir')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music, color: Colors.white),
                title: const Text('Lihat Antrean', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Antrean akan segera hadir')));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final song = audioProvider.currentSong;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).textTheme.bodyLarge?.color, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).textTheme.bodyMedium?.color, size: 48),
                const SizedBox(height: 16),
                Text(
                  "Tidak dapat memutar lagu",
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  audioProvider.errorMessage.isNotEmpty ? audioProvider.errorMessage : "No song playing",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    BoxDecoration backgroundDecoration;
    if (settingsProvider.playerTheme == 1) { // Solid
      backgroundDecoration = BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      );
    } else if (settingsProvider.playerTheme == 2) { // Vibrant
      backgroundDecoration = BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else { // 0: Gradient Transparan
      backgroundDecoration = BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.5),
            Theme.of(context).scaffoldBackgroundColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).textTheme.bodyLarge?.color, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Column(
                  children: [
                    Text("Memutar dari Pencarian", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 12)),
                    if (_currentPage == 1)
                      Text("Lirik", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: Icon(Icons.more_vert, color: Theme.of(context).textTheme.bodyLarge?.color),
                    onPressed: () => _showMoreMenu(context, audioProvider),
                  ),
                ],
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    // Page 1: Player UI
                    _buildPlayerPage(context, audioProvider, song),
                    // Page 2: Lyrics UI
                    _buildLyricsPage(context, audioProvider, song),
                  ],
                ),
              ),
              // Page Indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: _currentPage == 0 ? 8 : 6,
                      height: _currentPage == 0 ? 8 : 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == 0 ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: _currentPage == 1 ? 8 : 6,
                      height: _currentPage == 1 ? 8 : 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == 1 ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerPage(BuildContext context, AudioProvider audioProvider, var song) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Hero(
                tag: 'albumArt',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: song.albumArtUrl,
                    width: MediaQuery.of(context).size.width - 48,
                    height: MediaQuery.of(context).size.width - 48,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 24, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Consumer<DownloadProvider>(
                  builder: (context, downloadProvider, child) {
                    final isDownloaded = downloadProvider.isDownloaded(song.id);
                    final isDownloading = downloadProvider.isDownloading(song.id);
                    final progress = downloadProvider.getProgress(song.id);
                    
                    if (isDownloading) {
                      return Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          value: progress,
                          color: Theme.of(context).colorScheme.primary,
                          strokeWidth: 3,
                        ),
                      );
                    }
                    
                    return IconButton(
                      icon: Icon(
                        isDownloaded ? Icons.download_done : Icons.download_outlined,
                        color: isDownloaded ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      onPressed: () {
                        if (isDownloaded) {
                          downloadProvider.deleteDownload(song.id);
                        } else {
                          downloadProvider.download(song);
                        }
                      },
                    );
                  },
                ),
                Consumer<LibraryProvider>(
                  builder: (context, libraryProvider, child) {
                    final isLiked = libraryProvider.isInLibrary(song.id);
                    return IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      onPressed: () {
                        libraryProvider.toggle(song);
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ProgressBar(
              progress: audioProvider.currentPosition,
              total: audioProvider.totalDuration,
              onSeek: (duration) {
                audioProvider.seek(duration);
              },
              progressBarColor: Theme.of(context).textTheme.bodyLarge?.color,
              baseBarColor: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.24),
              bufferedBarColor: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.24),
              thumbColor: Theme.of(context).textTheme.bodyLarge?.color,
              barHeight: 4.0,
              thumbRadius: 6.0,
              timeLabelTextStyle: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Shuffle
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: audioProvider.shuffle
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  onPressed: () => audioProvider.toggleShuffle(),
                ),
                // Skip Previous
                IconButton(
                  icon: Icon(Icons.skip_previous, color: Theme.of(context).textTheme.bodyLarge?.color, size: 36),
                  onPressed: () => audioProvider.skipToPrevious(),
                ),
                // Play / Pause
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: IconButton(
                    iconSize: 48,
                    icon: Icon(
                      audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black, // Tetap hitam agar kontras dengan warna aksen
                    ),
                    onPressed: () {
                      if (audioProvider.isPlaying) {
                        audioProvider.pause();
                      } else {
                        audioProvider.resume();
                      }
                    },
                  ),
                ),
                // Skip Next
                IconButton(
                  icon: Icon(Icons.skip_next, color: Theme.of(context).textTheme.bodyLarge?.color, size: 36),
                  onPressed: () => audioProvider.skipToNext(),
                ),
                // Repeat
                IconButton(
                  icon: Icon(
                    audioProvider.repeatMode == RepeatMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                    color: audioProvider.repeatMode != RepeatMode.none
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  onPressed: () => audioProvider.toggleRepeat(),
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // "Follow Playlist / About Artist" Bottom Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tentang Artis", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(song.artist, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text("Pencipta Lagu", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anda mengikuti artis ini')));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                          side: BorderSide(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text("Ikuti"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsPage(BuildContext context, AudioProvider audioProvider, var song) {
    if (audioProvider.isLoadingLyrics) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
    } else if (audioProvider.parsedLyrics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: song.albumArtUrl.isNotEmpty ? Theme.of(context).colorScheme.primary.withOpacity(0.4) : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Lirik tidak tersedia",
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (audioProvider.currentLyrics.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      audioProvider.currentLyrics,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 24, fontWeight: FontWeight.bold, height: 1.5),
                    ),
                  ),
                )
              else
                Text(
                  "Kami belum menemukan lirik untuk lagu ini.",
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16),
                ),
            ],
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: SyncedLyricsView(
          audioProvider: audioProvider, 
          color: song.albumArtUrl.isNotEmpty ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface
        ),
      );
    }
  }
}

class SyncedLyricsView extends StatefulWidget {
  final AudioProvider audioProvider;
  final Color color;

  const SyncedLyricsView({super.key, required this.audioProvider, required this.color});

  @override
  State<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends State<SyncedLyricsView> {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = -1;

  @override
  void didUpdateWidget(covariant SyncedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final lyrics = widget.audioProvider.parsedLyrics;
    if (lyrics.isEmpty) return;

    final pos = widget.audioProvider.currentPosition;
    
    // Find current active lyric line
    int newIndex = -1;
    for (int i = 0; i < lyrics.length; i++) {
      if (pos >= lyrics[i].time) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _currentIndex) {
      _currentIndex = newIndex;
      if (_currentIndex >= 0) {
        _scrollToIndex(_currentIndex);
      }
    }
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    
    // Setiap baris lirik sekitar 56px (padding 8*2 + font ~40)
    // Tinggi total container layar penuh
    final itemHeight = 56.0;
    final containerHeight = MediaQuery.of(context).size.height * 0.7; // perkiraan tinggi
    final targetOffset = (index * itemHeight) - (containerHeight / 2 - itemHeight / 2);
    
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = widget.audioProvider.parsedLyrics;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60), // padding vertikal lebih besar untuk page view
          itemCount: lyrics.length,
          itemBuilder: (context, index) {
            final isCurrent = index == _currentIndex;
            final isPassed = _currentIndex >= 0 && index < _currentIndex;

            return GestureDetector(
              onTap: () {
                widget.audioProvider.seek(lyrics[index].time);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    color: isCurrent
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : isPassed
                            ? Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.25)
                            : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.45),
                    fontSize: isCurrent ? 28 : 24, // Sedikit lebih besar
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                    height: 1.4,
                  ),
                  child: Text(lyrics[index].text),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
