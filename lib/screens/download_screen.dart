import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import '../providers/audio_provider.dart';
import '../models/song_model.dart';
import '../theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.15),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Consumer<DownloadProvider>(
            builder: (context, downloadProvider, child) {
              final downloads = downloadProvider.downloadedSongs;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 16.0),
                      child: Row(
                        children: [
                          Text(
                            'Unduhan',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${downloads.length} lagu',
                              style: const TextStyle(
                                  color: AppTheme.primaryColor, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (downloads.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.download_for_offline_outlined,
                              size: 72,
                              color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white).withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada unduhan',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Unduh lagu favoritmu untuk\ndiputar tanpa internet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final map = downloads[index];
                          final id = map['id'] as String? ?? '';
                          final title = map['title'] as String? ?? 'Unknown';
                          final artist = map['artist'] as String? ?? 'Unknown';
                          final albumArtUrl = map['albumArtUrl'] as String? ?? '';

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: albumArtUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: albumArtUrl,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => _defaultArt(),
                                    )
                                  : _defaultArt(),
                            ),
                            title: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppTheme.secondaryTextColor,
                                  fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.download_done,
                                    color: AppTheme.primaryColor, size: 18),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    downloadProvider.deleteDownload(id);
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              final audioProvider = Provider.of<AudioProvider>(
                                  context,
                                  listen: false);
                              final song = SongModel.fromMap(map);
                              audioProvider.playSong(song);
                            },
                          );
                        },
                        childCount: downloads.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _defaultArt() {
    return Container(
      width: 52,
      height: 52,
      color: AppTheme.surfaceColor,
      child: const Icon(Icons.music_note, color: Colors.white30),
    );
  }
}
