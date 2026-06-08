import 'song_model.dart';

class PlaylistModel {
  final String id;
  final String name;
  final String? coverUrl;
  final List<SongModel> songs;
  final DateTime createdAt;

  const PlaylistModel({
    required this.id,
    required this.name,
    this.coverUrl,
    required this.songs,
    required this.createdAt,
  });

  PlaylistModel copyWith({
    String? id,
    String? name,
    String? coverUrl,
    List<SongModel>? songs,
    DateTime? createdAt,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      coverUrl: coverUrl ?? this.coverUrl,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Playlist',
      coverUrl: map['coverUrl'],
      songs: (map['songs'] as List<dynamic>? ?? [])
          .map((s) => SongModel.fromMap(s as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'coverUrl': coverUrl,
      'songs': songs.map((s) => s.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
