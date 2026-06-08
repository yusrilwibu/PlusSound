import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/music_service.dart' hide debugPrint;
import 'package:just_audio/just_audio.dart';
import '../services/download_service.dart';
import '../models/lrc_line.dart';

enum RepeatMode { none, all, one }

class AudioProvider with ChangeNotifier {
  final MyAudioHandler audioHandler;
  final MusicService _musicService = MusicService();
  final DownloadService _downloadService = DownloadService();

  SongModel? _currentSong;
  bool _isPlaying = false;
  String _currentLyrics = '';
  List<LrcLine> _parsedLyrics = [];
  bool _isLoadingLyrics = false;
  bool _isLoadingSong = false;
  String _errorMessage = '';

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Queue
  List<SongModel> _queue = [];
  int _queueIndex = -1;

  // Repeat & shuffle
  RepeatMode _repeatMode = RepeatMode.none;
  bool _shuffle = false;

  RepeatMode get repeatMode => _repeatMode;
  bool get shuffle => _shuffle;
  List<SongModel> get queue => _queue;
  int get queueIndex => _queueIndex;

  AudioProvider(this.audioHandler) {
    // Listen to playback state changes (playing/paused)
    audioHandler.playbackState.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      if (wasPlaying != _isPlaying) {
        notifyListeners();
      }
    });

    // Position update from audio player - throttled to avoid rebuild storms
    audioHandler.player.positionStream.listen((pos) {
      // Only update & notify if the change is significant (>= 500ms diff)
      if ((pos - _currentPosition).abs() >= const Duration(milliseconds: 500)) {
        _currentPosition = pos;
        notifyListeners();
      }
    });

    // Duration update
    audioHandler.player.durationStream.listen((d) {
      if (d != null && d != _totalDuration) {
        _totalDuration = d;
        notifyListeners();
      }
    });

    // Song completed listener
    audioHandler.player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onSongCompleted();
      }
    });

    // Player error listener — auto-retry with fresh URL
    audioHandler.player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        debugPrint('Player playback error: $e');
        if (_currentSong != null && !_isLoadingSong) {
          _retryCurrentSong();
        }
      },
    );
  }

  SongModel? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  String get currentLyrics => _currentLyrics;
  List<LrcLine> get parsedLyrics => _parsedLyrics;
  bool get isLoadingLyrics => _isLoadingLyrics;
  bool get isLoadingSong => _isLoadingSong;
  String get errorMessage => _errorMessage;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  void _onSongCompleted() async {
    if (_repeatMode == RepeatMode.one) {
      audioHandler.seek(Duration.zero);
      audioHandler.play();
      return;
    }

    // Cek pengaturan Auto Play
    final prefs = await SharedPreferences.getInstance();
    final autoPlay = prefs.getBool('auto_play') ?? true;

    if (!autoPlay) return; // Berhenti jika Auto Play dimatikan

    skipToNext();
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.none:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.none;
        break;
    }
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    notifyListeners();
  }

  void setQueue(List<SongModel> songs, int startIndex) {
    _queue = List.from(songs);
    _queueIndex = startIndex;
  }

  Future<void> playSong(SongModel song,
      {List<SongModel>? queue, int? queueIndex}) async {
    if (queue != null) {
      _queue = List.from(queue);
      _queueIndex = queueIndex ?? 0;
    } else if (!_queue.contains(song)) {
      _queue = [song];
      _queueIndex = 0;
    } else {
      _queueIndex = _queue.indexOf(song);
    }

    _isLoadingSong = true;
    _errorMessage = '';
    _currentSong = song;
    _currentLyrics = '';
    _parsedLyrics = [];
    _currentPosition = Duration.zero;
    _totalDuration = song.duration; // Use duration already known from search
    notifyListeners();

    try {
      // 1. Check for offline/downloaded file first
      String? localPath = await _downloadService.getLocalPath(song.id);
      String streamUrl = localPath ?? song.streamUrl;
      Map<String, String> streamHeaders = {};

      // 2. If no local file and no preview URL, get stream from service
      if (localPath == null && streamUrl.isEmpty) {
        final data = await _musicService.getStreamUrl(song.id);
        streamUrl = (data['url'] as String?)?.trim() ?? '';
        streamHeaders = Map<String, String>.from(data['headers'] as Map? ?? {});
      }

      if (streamUrl.isNotEmpty) {
        Duration finalDuration = song.duration;

        _currentSong = song.copyWith(
          duration: finalDuration,
          streamUrl: streamUrl,
        );
        if (finalDuration != Duration.zero) {
          _totalDuration = finalDuration;
        }

        await audioHandler.initAudio(
          streamUrl,
          song.title,
          song.artist,
          song.albumArtUrl,
          duration: finalDuration == Duration.zero ? null : finalDuration,
          headers: streamHeaders.isNotEmpty ? streamHeaders : null,
        );

        _isLoadingSong = false;
        notifyListeners();

        // 3. Fetch lyrics in the background — do not block UI
        _isLoadingLyrics = true;
        notifyListeners();
        _musicService.getLyrics(
          song.title,
          song.artist,
          duration: song.duration != Duration.zero ? song.duration : null,
        ).then((lyrics) {
          _currentLyrics = lyrics;
          try {
            _parsedLyrics = _parseLrc(lyrics);
          } catch (_) {
            _parsedLyrics = [];
          }
          _isLoadingLyrics = false;
          notifyListeners();
        }).catchError((_) {
          _isLoadingLyrics = false;
          notifyListeners();
        });
      } else {
        _isLoadingSong = false;
        _errorMessage = 'Gagal mendapatkan Stream URL dari server.';
        _currentSong = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('playSong error: $e');
      _isLoadingSong = false;
      _errorMessage = 'Terjadi kesalahan pemutaran: $e';
      _currentSong = null;
      notifyListeners();
    }
  }

  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    int next;
    if (_shuffle) {
      next = (List.generate(_queue.length, (i) => i)..shuffle()).first;
    } else {
      next = _queueIndex + 1;
      if (next >= _queue.length) {
        if (_repeatMode == RepeatMode.all) {
          next = 0;
        } else {
          return;
        }
      }
    }
    _queueIndex = next;
    await playSong(_queue[next]);
  }

  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    // If more than 3s in, restart current song
    if (_currentPosition.inSeconds > 3) {
      await audioHandler.seek(Duration.zero);
      return;
    }
    int prev = _queueIndex - 1;
    if (prev < 0) {
      prev = _repeatMode == RepeatMode.all ? _queue.length - 1 : 0;
    }
    _queueIndex = prev;
    await playSong(_queue[prev]);
  }

  void pause() => audioHandler.pause();
  void resume() => audioHandler.play();
  void seek(Duration position) => audioHandler.seek(position);

  /// Dipanggil saat ExoPlayer gagal (misal URL stream sudah expired)
  Future<void> _retryCurrentSong() async {
    final song = _currentSong;
    if (song == null || _isLoadingSong) return;
    debugPrint('Retrying song: ${song.title}');
    _isLoadingSong = true;
    notifyListeners();
    try {
      final data = await _musicService.getStreamUrl(song.id);
      final freshUrl = (data['url'] as String?)?.trim() ?? '';
      final freshHeaders = Map<String, String>.from(data['headers'] as Map? ?? {});
      if (freshUrl.isNotEmpty) {
        await audioHandler.initAudio(
          freshUrl,
          song.title,
          song.artist,
          song.albumArtUrl,
          duration: song.duration == Duration.zero ? null : song.duration,
          headers: freshHeaders.isNotEmpty ? freshHeaders : null,
        );
      } else {
        _errorMessage = 'Gagal memuat ulang stream audio.';
      }
    } catch (e) {
      debugPrint('Retry failed: $e');
      _errorMessage = 'Gagal memuat ulang: $e';
    } finally {
      _isLoadingSong = false;
      notifyListeners();
    }
  }

  List<LrcLine> _parseLrc(String lyrics) {
    if (lyrics.isEmpty || !lyrics.contains('[')) return [];
    
    final lines = lyrics.split('\n');
    final RegExp timeRegExp = RegExp(r'\[(\d+):(\d+\.\d+)\]');
    List<LrcLine> parsed = [];

    for (var line in lines) {
      final match = timeRegExp.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = double.parse(match.group(2)!);
        final duration = Duration(
          milliseconds: (minutes * 60 * 1000) + (seconds * 1000).toInt(),
        );
        final text = line.replaceFirst(timeRegExp, '').trim();
        if (text.isNotEmpty) {
          parsed.add(LrcLine(time: duration, text: text));
        }
      }
    }
    return parsed;
  }
}
