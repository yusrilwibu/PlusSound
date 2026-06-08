import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../theme.dart';
import '../screens/player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    if (audioProvider.isLoadingSong && audioProvider.currentSong == null) {
      return Container(
        height: 60,
        color: AppTheme.surfaceColor,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    final song = audioProvider.currentSong;
    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PlayerScreen()),
        );
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: song.albumArtUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[800]),
                      errorWidget: (context, url, error) => const Icon(Icons.music_note),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  if (audioProvider.isLoadingSong)
                     const Padding(
                       padding: EdgeInsets.all(8.0),
                       child: SizedBox(
                         width: 24, height: 24, 
                         child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2)
                       ),
                     )
                  else
                    IconButton(
                      icon: Icon(
                        audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (audioProvider.isPlaying) {
                          audioProvider.pause();
                        } else {
                          audioProvider.resume();
                        }
                      },
                    ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: audioProvider.totalDuration.inMilliseconds > 0
                  ? audioProvider.currentPosition.inMilliseconds / audioProvider.totalDuration.inMilliseconds
                  : 0.0,
              backgroundColor: Colors.white24,
              color: Colors.white,
              minHeight: 2,
            ),
          ],
        ),
      ),
    );
  }
}
