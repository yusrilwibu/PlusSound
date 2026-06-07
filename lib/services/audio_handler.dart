import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'youtube_audio_source.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  MyAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _player.durationStream.listen((d) {
      if (d != null) {
        final current = mediaItem.value;
        if (current != null) {
          mediaItem.add(current.copyWith(duration: d));
        }
      }
    });
  }

  AudioPlayer get player => _player;

  Future<void> initAudio(
    String url,
    String title,
    String artist,
    String artUri, {
    Duration? duration,
    Map<String, String>? headers,
  }) async {
    final item = MediaItem(
      id: url,
      album: 'PlusSound',
      title: title,
      artist: artist,
      artUri: artUri.isNotEmpty ? Uri.parse(artUri) : null,
      duration: duration,
    );
    mediaItem.add(item);
    if (url.startsWith('/')) {
      await _player.setFilePath(url);
    } else {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          headers: headers,
        ),
      );
    }
    play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> skipToNext() async {
    // handled externally by AudioProvider queue
  }

  @override
  Future<void> skipToPrevious() async {
    // handled externally by AudioProvider queue
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
