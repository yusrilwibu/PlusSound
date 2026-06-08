import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../providers/download_provider.dart';
import '../theme.dart';

class SongTile extends StatelessWidget {
  final SongModel song;
  final List<SongModel>? queue;
  final int? queueIndex;
  final bool showIndex;
  final int? index;

  const SongTile({
    super.key,
    required this.song,
    this.queue,
    this.queueIndex,
    this.showIndex = false,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final libraryProvider = context.read<LibraryProvider>();
    final downloadProvider = context.watch<DownloadProvider>();
    final isPlaying = audioProvider.currentSong?.id == song.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: song.albumArtUrl,
              width: 50,
              height: 50,
              memCacheWidth: 100,
              memCacheHeight: 100,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppTheme.surfaceColor,
                child: Icon(Icons.music_note, color: Colors.white30),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppTheme.surfaceColor,
                child: Icon(Icons.music_note, color: Colors.white30),
              ),
            ),
          ),
          if (isPlaying)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.equalizer, color: AppTheme.primaryColor, size: 22),
            ),
        ],
      ),
      title: Text(
        song.title,
        style: TextStyle(
          color: isPlaying
              ? AppTheme.primaryColor
              : isDark
                  ? Colors.white
                  : const Color(0xFF121212),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (downloadProvider.isDownloaded(song.id))
            Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.download_done, size: 12, color: AppTheme.primaryColor),
            ),
          Expanded(
            child: Text(
              song.artist,
              style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: _MoreMenu(song: song, downloadProvider: downloadProvider, libraryProvider: libraryProvider),
      onTap: () {
        context.read<AudioProvider>().playSong(
          song,
          queue: queue,
          queueIndex: queueIndex,
        );
      },
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final SongModel song;
  final DownloadProvider downloadProvider;
  final LibraryProvider libraryProvider;

  const _MoreMenu({
    required this.song,
    required this.downloadProvider,
    required this.libraryProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading = downloadProvider.isDownloading(song.id);
    final isDownloaded = downloadProvider.isDownloaded(song.id);
    final progress = downloadProvider.getProgress(song.id);

    if (isDownloading) {
      return SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2.5,
          color: AppTheme.primaryColor,
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.more_vert, color: AppTheme.secondaryTextColor),
      onPressed: () => _showOptions(context, isDownloaded),
    );
  }

  void _showOptions(BuildContext context, bool isDownloaded) {
    final inLibrary = libraryProvider.isInLibrary(song.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _OptionSheet(
        song: song,
        inLibrary: inLibrary,
        isDownloaded: isDownloaded,
        libraryProvider: libraryProvider,
        downloadProvider: downloadProvider,
      ),
    );
  }
}

class _OptionSheet extends StatelessWidget {
  final SongModel song;
  final bool inLibrary;
  final bool isDownloaded;
  final LibraryProvider libraryProvider;
  final DownloadProvider downloadProvider;

  const _OptionSheet({
    required this.song,
    required this.inLibrary,
    required this.isDownloaded,
    required this.libraryProvider,
    required this.downloadProvider,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          SizedBox(height: 12),
          // Song header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: song.albumArtUrl,
                    width: 48,
                    height: 48,
                    memCacheWidth: 96,
                    memCacheHeight: 96,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceColor, child: Icon(Icons.music_note)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(song.artist, style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: Icon(inLibrary ? Icons.favorite : Icons.favorite_border, color: inLibrary ? AppTheme.primaryColor : Colors.white),
            title: Text(inLibrary ? 'Hapus dari Library' : 'Simpan ke Library', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            onTap: () {
              Navigator.pop(context);
              libraryProvider.toggle(song);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(inLibrary ? 'Dihapus dari library' : 'Disimpan ke library'),
                backgroundColor: AppTheme.surfaceColor,
                duration: const Duration(seconds: 2),
              ));
            },
          ),
          ListTile(
            leading: Icon(
              isDownloaded ? Icons.download_done : Icons.download_outlined,
              color: isDownloaded ? AppTheme.primaryColor : Colors.white,
            ),
            title: Text(isDownloaded ? 'Sudah Diunduh' : 'Unduh untuk Offline', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            onTap: isDownloaded
                ? null
                : () {
                    Navigator.pop(context);
                    downloadProvider.download(song);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Mengunduh lagu...'),
                      backgroundColor: AppTheme.surfaceColor,
                      duration: Duration(seconds: 2),
                    ));
                  },
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
