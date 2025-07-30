import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:modizk_download/models/sound_cloud_search_response.dart';
import 'package:modizk_download/services/music_provider.dart';
import 'package:provider/provider.dart';

class SoundCloudAudioProvider with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isLoading = false;
  Track? currentTrack = null;
  int currentIndex = 0;
  bool _autoPlayNext = true; // Flag to control auto-play behavior

  SoundCloudAudioProvider() {
    _initSession();
    _setupPlayerListeners();
  }

  // Getters
  AudioPlayer get player => _player;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isLoading => _isLoading;
  bool get autoPlayNext => _autoPlayNext;
  double get progress => _totalDuration.inMilliseconds > 0
      ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
      : 0.0;

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  void _setupPlayerListeners() {
    _player.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    _player.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    _player.durationStream.listen((duration) {
      _totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });

    _player.processingStateStream.listen((state) {
      _isLoading = state == ProcessingState.loading || state == ProcessingState.buffering;

      // Handle track completion and auto-play next
      if (state == ProcessingState.completed && _autoPlayNext) {
        _handleTrackCompletion();
      }

      notifyListeners();
    });
  }

  void _handleTrackCompletion() async {
    // Get the music provider to check if there's a next track
    final context = _getCurrentContext();
    if (context != null) {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      if (musicProvider.soundCloudResponse != null &&
          currentIndex < musicProvider.soundCloudResponse!.collection.length - 1) {
        // There's a next track available
        await playNext(context);
      } else {
        // No more tracks, you can optionally restart from beginning or stop
        log('Playlist completed');
        // Optionally restart from beginning:
        // await playTrackAtIndex(context, 0);
      }
    }
  }

  BuildContext? _getCurrentContext() {
    // This is a workaround to get context. In a real app, you might want to
    // pass context differently or use a different approach
    try {
      return WidgetsBinding.instance.focusManager.primaryFocus?.context;
    } catch (e) {
      return null;
    }
  }

  Future<void> playNext(BuildContext context) async {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);

    if (musicProvider.soundCloudResponse != null &&
        currentIndex < musicProvider.soundCloudResponse!.collection.length - 1) {
      int nextIndex = currentIndex + 1;
      setCurrentTrack(musicProvider.soundCloudResponse!.collection[nextIndex], nextIndex);
      if (currentTrack != null) {
        await playTrack(context);
      }
    }
  }

  Future<void> playPrevious(BuildContext context) async {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);

    if (musicProvider.soundCloudResponse != null && currentIndex > 0) {
      int previousIndex = currentIndex - 1;
      setCurrentTrack(musicProvider.soundCloudResponse!.collection[previousIndex], previousIndex);
      if (currentTrack != null) {
        await playTrack(context);
      }
    }
  }

  Future<void> playTrackAtIndex(BuildContext context, int index) async {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);

    if (musicProvider.soundCloudResponse != null &&
        index >= 0 &&
        index < musicProvider.soundCloudResponse!.collection.length) {
      setCurrentTrack(musicProvider.soundCloudResponse!.collection[index], index);
      if (currentTrack != null) {
        await playTrack(context);
      }
    }
  }

  void setAutoPlayNext(bool enabled) {
    _autoPlayNext = enabled;
    notifyListeners();
  }

  Future<void> playTrack(BuildContext context) async {
    try {
      await _player.stop();
      _isLoading = true;
      notifyListeners();

      final List<Transcoding> transcodings = currentTrack!.media.transcodings;

      Transcoding? selectedTranscoding;

      for (final transcoding in transcodings) {
        if (transcoding.format?.protocol == 'progressive' &&
            transcoding.format?.mimeType?.contains('audio/mpeg') == true) {
          selectedTranscoding = transcoding;
          break;
        }
      }

      if (selectedTranscoding == null) {
        for (final transcoding in transcodings) {
          if (transcoding.format?.protocol == 'progressive') {
            selectedTranscoding = transcoding;
            break;
          }
        }
      }

      selectedTranscoding ??= transcodings.first;

      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      int status = await musicProvider.getStreamUrl(selectedTranscoding.url);

      if (status == 2) {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(musicProvider.streamUrl!)));
        await _player.play();
      } else if (status == 3) {
        log("url fetch error: ${musicProvider.streamError}");
      }
    } catch (e) {
      print('Error playing track: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekToNext() async {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    if (newPosition < _totalDuration) {
      await seek(newPosition);
    }
  }

  Future<void> seekToPrevious() async {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      await seek(newPosition);
    } else {
      await seek(Duration.zero);
    }
  }

  void setCurrentTrack(Track track, int index){
    currentTrack = track;
    currentIndex = index;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}