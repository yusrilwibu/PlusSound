class SongModel {
  final String id;
  final String title;
  final String artist;
  final String albumArtUrl;
  final Duration duration;
  final String streamUrl;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArtUrl,
    required this.duration,
    required this.streamUrl,
  });

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumArtUrl,
    Duration? duration,
    String? streamUrl,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      duration: duration ?? this.duration,
      streamUrl: streamUrl ?? this.streamUrl,
    );
  }

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      albumArtUrl: map['albumArtUrl'] ?? '',
      duration: Duration(milliseconds: map['duration'] ?? 0),
      streamUrl: map['streamUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'albumArtUrl': albumArtUrl,
      'duration': duration.inMilliseconds,
      'streamUrl': streamUrl,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SongModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
