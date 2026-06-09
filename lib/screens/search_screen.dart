import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/music_service.dart';
import '../models/song_model.dart';
import '../providers/audio_provider.dart';
import '../theme.dart';
import '../widgets/song_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final MusicService _musicService = MusicService();
  final FocusNode _focusNode = FocusNode();
  List<SongModel> _results = [];
  bool _isSearching = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty || query == _lastQuery) return;
    _lastQuery = query;
    setState(() => _isSearching = true);
    final results = await _musicService.searchSongs(query);
    if (mounted) setState(() { _results = results; _isSearching = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.backgroundColor : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final fillColor = isDark ? AppTheme.surfaceColor : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: TextStyle(color: textColor),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _search,
                      decoration: InputDecoration(
                        hintText: 'Cari lagu, artis...',
                        hintStyle: const TextStyle(color: AppTheme.secondaryTextColor),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryTextColor),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppTheme.secondaryTextColor),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() { _results = []; _lastQuery = ''; });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (v) {
                        setState(() {}); // update clear button
                        if (v.isEmpty) setState(() { _results = []; _lastQuery = ''; });
                      },
                    ),
                  ),
                  if (_controller.text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _search(_controller.text),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                      child: const Text(
                        'Cari',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]
                ],
              ),
            ),

            // Results
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : _results.isEmpty
                      ? _EmptyState(hasQuery: _controller.text.isNotEmpty && _lastQuery.isNotEmpty)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 120),
                          itemCount: _results.length,
                          itemBuilder: (context, index) => SongTile(
                            song: _results[index],
                            queue: _results,
                            queueIndex: index,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    if (hasQuery) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.secondaryTextColor),
            SizedBox(height: 16),
            Text('Tidak ada hasil ditemukan', style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 16)),
          ],
        ),
      );
    }
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 72, color: AppTheme.secondaryTextColor),
          SizedBox(height: 16),
          Text('Cari lagu favoritmu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Ketik judul, nama artis, atau lirik', style: TextStyle(color: AppTheme.secondaryTextColor)),
        ],
      ),
    );
  }
}
