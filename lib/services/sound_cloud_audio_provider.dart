import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:modizk_download/models/sound_cloud_search_response.dart';
import 'package:modizk_download/services/music_provider.dart';
import 'package:modizk_download/services/local_music_provider.dart';
import 'package:modizk_download/services/native_media_notification_service.dart';
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
  
  // Store track collection directly to avoid context dependency
  List<Track> _trackCollection = [];
  MusicProvider? _musicProviderRef;

  SoundCloudAudioProvider() {
    print('🎵🎵🎵 SoundCloudAudioProvider constructor called 🎵🎵🎵');
    log('🎵 SoundCloudAudioProvider constructor called');
    _initSession();
    _setupPlayerListeners();
    log('🎵 SoundCloudAudioProvider constructor completed - listeners set up');
    print('🎵🎵🎵 SoundCloudAudioProvider constructor completed 🎵🎵🎵');
    // Don't setup notification callbacks here - they'll be set up when needed
  }

  // Getters
  AudioPlayer get player => _player;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isLoading => _isLoading;
  bool get autoPlayNext => _autoPlayNext;
  List<Track> get trackCollection => _trackCollection;
  double get progress => _totalDuration.inMilliseconds > 0
      ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
      : 0.0;

  /// Update track collection when new search results are available
  void updateTrackCollection(List<Track> tracks, MusicProvider musicProvider) {
    _trackCollection = tracks;
    _musicProviderRef = musicProvider;
    log('🎵 Updated track collection with ${tracks.length} tracks');
  }

  /// Check if there's a next track available
  bool get hasNext => currentIndex < _trackCollection.length - 1;

  /// Check if there's a previous track available  
  bool get hasPrevious => currentIndex > 0;

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  void _setupPlayerListeners() {
    log('🎵 Setting up SoundCloud player listeners...');
    _player.playingStream.listen((playing) {
      log('🎵 SoundCloud playingStream: $playing');
      _isPlaying = playing;
      _updateNotification(); // Update on play/pause state change
      notifyListeners();
    });

    _player.positionStream.listen((position) {
      log('🎵 SoundCloud positionStream: ${position.inSeconds}s');
      _currentPosition = position;
      // Let the notification service handle throttling
      _updateNotification();
      notifyListeners();
    });

    _player.durationStream.listen((duration) {
      log('🎵 SoundCloud durationStream: ${duration?.inSeconds}s');
      _totalDuration = duration ?? Duration.zero;
      _updateNotification(); // Update when duration is known
      notifyListeners();
    });
    
    log('🎵 SoundCloud player listeners set up successfully');

    _player.processingStateStream.listen((state) {
      _isLoading = state == ProcessingState.loading || state == ProcessingState.buffering;

      // Handle track completion and auto-play next
      if (state == ProcessingState.completed && _autoPlayNext) {
        _handleTrackCompletion();
      }

      notifyListeners();
    });
  }

  // Store context reference for notifications
  BuildContext? _notificationContext;

  void _setupNotificationCallbacks() {
    log('🎵 SoundCloud _setupNotificationCallbacks called - isInitialized: ${NativeMediaNotificationService.instance.isInitialized}');
    if (NativeMediaNotificationService.instance.isInitialized) {
      log('🎵 Setting up notification callbacks for SoundCloud');
      NativeMediaNotificationService.instance.setSoundCloudCallbacks(
        onPlay: () async {
          log('🎵 SoundCloud notification play button pressed');
          await resume();
        },
        onPause: () async {
          log('🎵 SoundCloud notification pause button pressed');
          await pause();
        },
        onStop: () async {
          log('🎵 SoundCloud notification stop button pressed');
          await stop();
        },
        onNext: () async {
          log('🎵 SoundCloud notification next button pressed');
          await playNextTrack();
        },
        onPrevious: () async {
          log('🎵 SoundCloud notification previous button pressed');
          await playPreviousTrack();
        },
        onSeek: (position) async {
          log('🎵 SoundCloud notification seek called: ${position.inSeconds}s');
          await seek(position);
        },
      );
    } else {
      log('❌ Cannot setup SoundCloud notification callbacks - service not initialized');
    }
  }

  void _updateNotification() async {
    log('🎵 SoundCloud _updateNotification called - currentTrack: ${currentTrack?.title}, isPlaying: $_isPlaying');
    
    if (currentTrack != null) {
      // Wait for service to be initialized if it's not ready yet
      if (!NativeMediaNotificationService.instance.isInitialized) {
        log('🎵 Waiting for notification service to initialize...');
        // Wait up to 5 seconds for initialization
        for (int i = 0; i < 50; i++) {
          if (NativeMediaNotificationService.instance.isInitialized) break;
          await Future.delayed(Duration(milliseconds: 100));
        }
        
        if (!NativeMediaNotificationService.instance.isInitialized) {
          log('❌ Notification service still not initialized after waiting');
          return;
        }
      }
      
      try {
        await NativeMediaNotificationService.instance.showMusicNotification(
          title: currentTrack!.title,
          artist: currentTrack!.user.username,
          isPlaying: _isPlaying,
          currentPosition: _currentPosition,
          totalDuration: _totalDuration,
          artworkUrl: currentTrack!.artworkUrl,
          isLocal: false,
        );
      } catch (e) {
        log('❌ Error updating music notification: $e');
      }
    }
  }

  void _handleTrackCompletion() async {
    // Use context-free navigation for track completion
    if (hasNext) {
      // There's a next track available
      await playNextTrack();
    } else {
      // No more tracks
      log('🎵 SoundCloud playlist completed');
      // Optionally restart from beginning:
      // await playTrackAtIndex(0);
    }
  }

  /// Context-free next track method for notifications
  Future<void> playNextTrack() async {
    if (hasNext && _musicProviderRef != null) {
      int nextIndex = currentIndex + 1;
      setCurrentTrack(_trackCollection[nextIndex], nextIndex);
      if (currentTrack != null && _notificationContext != null) {
        await playTrack(_notificationContext!);
      } else {
        log('❌ Cannot play next track - missing context or track');
      }
    } else {
      log('❌ No next track available or music provider not set');
    }
  }

  /// Context-free previous track method for notifications
  Future<void> playPreviousTrack() async {
    if (hasPrevious && _musicProviderRef != null) {
      int previousIndex = currentIndex - 1;
      setCurrentTrack(_trackCollection[previousIndex], previousIndex);
      if (currentTrack != null && _notificationContext != null) {
        await playTrack(_notificationContext!);
      } else {
        log('❌ Cannot play previous track - missing context or track');
      }
    } else {
      log('❌ No previous track available or music provider not set');
    }
  }

  /// Context-dependent next track method (for UI controls)
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

  /// Context-dependent previous track method (for UI controls)
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
    log('🎵🎵🎵 playTrack() called! Track: ${currentTrack?.title} 🎵🎵🎵');
    log('🎵 playTrack() called for track: ${currentTrack?.title}');
    try {
      // Store context for notification callbacks
      _notificationContext = context;
      
      // Get and store music provider reference and track collection
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      if (musicProvider.soundCloudResponse != null) {
        updateTrackCollection(musicProvider.soundCloudResponse!.collection, musicProvider);
      }
      
      // Setup notification callbacks if not already done
      _setupNotificationCallbacks();
      
      // CRITICAL FIX: Stop local music before playing SoundCloud
      final localProvider = Provider.of<LocalMusicProvider>(context, listen: false);
      if (localProvider.isLocalPlaying) {
        await localProvider.stopLocal();
      }

      await _player.stop();
      _isLoading = true;
      notifyListeners();

      final List<Transcoding> transcodings = currentTrack!.media.transcodings;
      log('🎵 Available transcodings: ${transcodings.length}');

      Transcoding? selectedTranscoding;

      for (final transcoding in transcodings) {
        if (transcoding.format.protocol == 'progressive' &&
            transcoding.format.mimeType.contains('audio/mpeg')) {
          selectedTranscoding = transcoding;
          log('🎵 Selected progressive MP3 transcoding');
          break;
        }
      }

      if (selectedTranscoding == null) {
        for (final transcoding in transcodings) {
          if (transcoding.format.protocol == 'progressive') {
            selectedTranscoding = transcoding;
            log('🎵 Selected progressive transcoding (non-MP3)');
            break;
          }
        }
      }

      selectedTranscoding ??= transcodings.first;
      log('🎵 Final selected transcoding: ${selectedTranscoding.format.protocol} - ${selectedTranscoding.format.mimeType}');

      log('🎵 About to get stream URL for: ${selectedTranscoding.url}');
      int status = await _musicProviderRef!.getStreamUrl(selectedTranscoding.url);
      log('🎵 Stream URL status: $status');

      if (status == 2) {
        log('🎵 Setting audio source: ${_musicProviderRef!.streamUrl!}');
        await _player.setAudioSource(AudioSource.uri(Uri.parse(_musicProviderRef!.streamUrl!)));
        log('🎵 Audio source set successfully, calling play()...');
        await _player.play();
        log('🎵 Player.play() called successfully');
        _isLoading = false; // Reset loading state after play starts
        notifyListeners();
      } else if (status == 3) {
        log("🎵 URL fetch error: ${_musicProviderRef!.streamError}");
        _isLoading = false; // Reset loading state on error
        notifyListeners();
      } else {
        log("🎵 Unknown status code: $status");
        _isLoading = false; // Reset loading state on error
        notifyListeners();
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
    // Hide notification when stopped and reset active provider
    if (NativeMediaNotificationService.instance.isInitialized) {
      await NativeMediaNotificationService.instance.hideNotification();
      NativeMediaNotificationService.instance.setActiveProvider('none');
    }
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
    _updateNotification();
    notifyListeners();
  }

  @override
  void dispose() {
    // Hide notification when disposing
    if (NativeMediaNotificationService.instance.isInitialized) {
      NativeMediaNotificationService.instance.hideNotification();
    }
    _player.dispose();
    super.dispose();
  }
}