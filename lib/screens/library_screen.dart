import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import '../models/song_model.dart';
import '../providers/library_provider.dart';
import '../providers/download_provider.dart';
import '../providers/audio_provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Koleksi Kamu'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.secondaryTextColor,
          tabs: const [
            Tab(text: 'Disukai'),
            Tab(text: 'Diunduh'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLikedTab(),
          _buildDownloadedTab(),
        ],
      ),
    );
  }

  Widget _buildLikedTab() {
    return Consumer<LibraryProvider>(
      builder: (context, provider, child) {
        if (!provider.loaded) {
          return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }
        final songs = provider.songs;
        if (songs.isEmpty) {
          return _buildEmptyState('Belum ada lagu yang disukai', Icons.favorite_border);
        }
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            return _buildSongTile(songs[index], isDownloadTile: false);
          },
        );
      },
    );
  }

  Widget _buildDownloadedTab() {
    return Consumer<DownloadProvider>(
      builder: (context, provider, child) {
        final songs = provider.downloadedSongs.map((m) => SongModel.fromMap(m)).toList();
        if (songs.isEmpty) {
          return _buildEmptyState('Belum ada lagu yang diunduh', Icons.download_done);
        }
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            return _buildSongTile(songs[index], isDownloadTile: true);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.secondaryTextColor.withOpacity(0.5)),
          SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(SongModel song, {required bool isDownloadTile}) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: song.albumArtUrl,
          width: 50,
          height: 50,
          memCacheWidth: 100,
          memCacheHeight: 100,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => Container(
            color: AppTheme.surfaceColor,
            width: 50,
            height: 50,
            child: Icon(Icons.music_note, color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          isDownloadTile ? Icons.delete_outline : Icons.favorite,
          color: isDownloadTile ? AppTheme.secondaryTextColor : AppTheme.primaryColor,
        ),
        onPressed: () {
          if (isDownloadTile) {
            Provider.of<DownloadProvider>(context, listen: false).deleteDownload(song.id);
          } else {
            Provider.of<LibraryProvider>(context, listen: false).toggle(song);
          }
        },
      ),
      onTap: () {
        audioProvider.playSong(song);
      },
    );
  }
}
