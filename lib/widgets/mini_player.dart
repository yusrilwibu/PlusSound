import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/audio_provider.dart';
import '../theme.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (audioProvider.isLoadingSong && audioProvider.currentSong == null) {
      return Container(
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2),
          ),
        ),
      );
    }

    final song = audioProvider.currentSong;
    if (song == null) return const SizedBox.shrink();

    final progress = audioProvider.totalDuration.inMilliseconds > 0
        ? audioProvider.currentPosition.inMilliseconds / audioProvider.totalDuration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const PlayerScreen(),
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: song.albumArtUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppTheme.surfaceColor),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.surfaceColor,
                        child: const Icon(Icons.music_note, color: Colors.white30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF121212),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artist,
                          style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Prev
                  IconButton(
                    icon: Icon(Icons.skip_previous, color: isDark ? Colors.white : const Color(0xFF121212), size: 22),
                    onPressed: () => audioProvider.skipToPrevious(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  // Play/Pause
                  if (audioProvider.isLoadingSong)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        audioProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: AppTheme.primaryColor,
                        size: 36,
                      ),
                      onPressed: () {
                        audioProvider.isPlaying ? audioProvider.pause() : audioProvider.resume();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  // Next
                  IconButton(
                    icon: Icon(Icons.skip_next, color: isDark ? Colors.white : const Color(0xFF121212), size: 22),
                    onPressed: () => audioProvider.skipToNext(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
            // Progress bar tipis di bawah
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                minHeight: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
