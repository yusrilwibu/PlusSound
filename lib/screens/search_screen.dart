import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/music_service.dart';
import '../models/song_model.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../providers/download_provider.dart';
import '../theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MusicService _musicService = MusicService();
  List<SongModel> _searchResults = [];
  bool _isSearching = false;

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
    });

    final results = await _musicService.searchSongs(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  final List<Map<String, dynamic>> _genres = [
    {'name': 'Pop', 'colors': [Colors.pink, Colors.redAccent]},
    {'name': 'Indo Pop', 'colors': [Colors.orange, Colors.deepOrange]},
    {'name': 'Rock', 'colors': [Colors.black87, Colors.red[900]!]},
    {'name': 'K-Pop', 'colors': [Colors.purple, Colors.pinkAccent]},
    {'name': 'Dangdut', 'colors': [Colors.green, Colors.teal]},
    {'name': 'Hip Hop', 'colors': [Colors.blueGrey, Colors.black87]},
    {'name': 'Jazz', 'colors': [Colors.brown, Colors.orangeAccent]},
    {'name': 'R&B', 'colors': [Colors.deepPurple, Colors.indigo]},
    {'name': 'EDM', 'colors': [Colors.cyan, Colors.blueAccent]},
    {'name': 'Acoustic', 'colors': [Colors.amber, Colors.orange]},
    {'name': 'Chill', 'colors': [Colors.lightBlue, Colors.cyanAccent]},
    {'name': 'Viral', 'colors': [Colors.redAccent, Colors.purpleAccent]},
  ];

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 16.0, top: 24.0, bottom: 16.0),
              child: Text(
                'Cari',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                onSubmitted: _performSearch,
                onChanged: (val) {
                  if (val.isEmpty) {
                    setState(() {
                      _searchResults.clear();
                    });
                  }
                },
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: "Apa yang ingin kamu dengarkan?",
                  hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                  prefixIcon: Icon(Icons.search, color: Colors.black87, size: 28),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            if (_isSearching)
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)))
            else if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final song = _searchResults[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: song.albumArtUrl,
                          width: 56,
                          height: 56,
                          memCacheWidth: 112,
                          memCacheHeight: 112,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppTheme.surfaceColor),
                          errorWidget: (context, url, error) => Icon(Icons.music_note),
                        ),
                      ),
                      title: Text(
                        song.title,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.artist,
                        style: const TextStyle(color: AppTheme.secondaryTextColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Consumer<DownloadProvider>(
                            builder: (context, downloadProvider, child) {
                              final isDownloaded = downloadProvider.isDownloaded(song.id);
                              final isDownloading = downloadProvider.isDownloading(song.id);
                              final progress = downloadProvider.getProgress(song.id);

                              if (isDownloading) {
                                return Container(
                                  width: 40,
                                  height: 40,
                                  padding: const EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    color: AppTheme.primaryColor,
                                    strokeWidth: 2,
                                  ),
                                );
                              }

                              return IconButton(
                                icon: Icon(
                                  isDownloaded ? Icons.download_done : Icons.download_outlined,
                                  color: isDownloaded ? AppTheme.primaryColor : AppTheme.secondaryTextColor,
                                  size: 22,
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
                                  color: isLiked ? AppTheme.primaryColor : AppTheme.secondaryTextColor,
                                  size: 22,
                                ),
                                onPressed: () {
                                  libraryProvider.toggle(song);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        audioProvider.playSong(song);
                      },
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                        child: Text(
                          "Jelajahi semua",
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.6,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _genres.length,
                          itemBuilder: (context, index) {
                            final genre = _genres[index];
                            return GestureDetector(
                              onTap: () {
                                _searchController.text = genre['name'];
                                _performSearch(genre['name']);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    colors: genre['colors'],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text(
                                        genre['name'],
                                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: -15,
                                      bottom: -15,
                                      child: Transform.rotate(
                                        angle: 0.4,
                                        child: Icon(
                                          Icons.music_note,
                                          size: 70,
                                          color: Theme.of(context).textTheme.bodyLarge?.color.withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
