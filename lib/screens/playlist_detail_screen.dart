import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/playlist_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/song_tile.dart';
import '../theme.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlaylistProvider, AudioProvider>(
      builder: (context, playlistProvider, audioProvider, child) {
        final playlistIndex = playlistProvider.playlists.indexWhere((p) => p.id == playlistId);
        
        // Return if playlist was deleted
        if (playlistIndex == -1) {
          return const Scaffold(body: Center(child: Text("Playlist tidak ditemukan")));
        }
        
        final playlist = playlistProvider.playlists[playlistIndex];

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    playlist.name,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                      shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                  background: playlist.coverUrl != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: playlist.coverUrl!,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Theme.of(context).scaffoldBackgroundColor,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Theme.of(context).colorScheme.primary, Colors.black],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.queue_music, size: 80, color: Colors.white54),
                          ),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${playlist.songs.length} Lagu',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 14,
                        ),
                      ),
                      if (playlist.songs.isNotEmpty)
                        FloatingActionButton(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          onPressed: () {
                            audioProvider.playSong(
                              playlist.songs.first,
                              queue: playlist.songs,
                              queueIndex: 0,
                            );
                          },
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                        ),
                    ],
                  ),
                ),
              ),
              if (playlist.songs.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_off, size: 64, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada lagu di playlist ini',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = playlist.songs[index];
                      return Dismissible(
                        key: Key(song.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.redAccent,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          playlistProvider.removeSongFromPlaylist(playlist.id, song.id);
                        },
                        child: SongTile(
                          song: song,
                          queue: playlist.songs,
                          index: index,
                        ),
                      );
                    },
                    childCount: playlist.songs.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
