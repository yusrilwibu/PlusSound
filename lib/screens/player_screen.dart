import 'package:flutter/material.dart' hide RepeatMode;
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../providers/download_provider.dart';
import '../theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final song = audioProvider.currentSong;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                const SizedBox(height: 16),
                const Text(
                  "Tidak dapat memutar lagu",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  audioProvider.errorMessage.isNotEmpty ? audioProvider.errorMessage : "No song playing",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.5),
              AppTheme.backgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text("Memutar dari Pencarian", style: TextStyle(color: Colors.white, fontSize: 12)),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
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
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
                                      color: AppTheme.primaryColor,
                                      strokeWidth: 3,
                                    ),
                                  );
                                }
                                
                                return IconButton(
                                  icon: Icon(
                                    isDownloaded ? Icons.download_done : Icons.download_outlined,
                                    color: isDownloaded ? AppTheme.primaryColor : Colors.white,
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
                                    color: isLiked ? AppTheme.primaryColor : Colors.white,
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
                          progressBarColor: Colors.white,
                          baseBarColor: Colors.white.withOpacity(0.24),
                          bufferedBarColor: Colors.white.withOpacity(0.24),
                          thumbColor: Colors.white,
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
                                    ? AppTheme.primaryColor
                                    : Colors.white,
                              ),
                              onPressed: () => audioProvider.toggleShuffle(),
                            ),
                            // Skip Previous
                            IconButton(
                              icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                              onPressed: () => audioProvider.skipToPrevious(),
                            ),
                            // Play / Pause
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryColor,
                              ),
                              child: IconButton(
                                iconSize: 48,
                                icon: Icon(
                                  audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.black,
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
                              icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                              onPressed: () => audioProvider.skipToNext(),
                            ),
                            // Repeat
                            IconButton(
                              icon: Icon(
                                audioProvider.repeatMode == RepeatMode.one
                                    ? Icons.repeat_one
                                    : Icons.repeat,
                                color: audioProvider.repeatMode != RepeatMode.none
                                    ? AppTheme.primaryColor
                                    : Colors.white,
                              ),
                              onPressed: () => audioProvider.toggleRepeat(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // Bagian Lirik (Synced)
                        if (audioProvider.isLoadingLyrics)
                          const Center(child: CircularProgressIndicator(color: Colors.white))
                        else if (audioProvider.parsedLyrics.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: song.albumArtUrl.isNotEmpty ? AppTheme.primaryColor.withOpacity(0.4) : AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Lyrics",
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  audioProvider.currentLyrics,
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.5),
                                ),
                              ],
                            ),
                          )
                        else
                          SyncedLyricsView(audioProvider: audioProvider, color: song.albumArtUrl.isNotEmpty ? AppTheme.primaryColor : Colors.grey),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    // Kita ingin baris aktif berada di tengah container (380px / 2 = 190px)
    final itemHeight = 56.0;
    final containerHeight = 380.0;
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
      height: 380, // Spotify-style tall lyrics card
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        ? Colors.white
                        : isPassed
                            ? Colors.white.withOpacity(0.25)
                            : Colors.white.withOpacity(0.45),
                    fontSize: isCurrent ? 24 : 20,
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
