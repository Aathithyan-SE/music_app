import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:developer';
import 'dart:typed_data';
import '../models/local_music_model.dart';
import '../services/sound_cloud_audio_provider.dart';
import '../services/native_media_notification_service.dart';
import 'local_music_service.dart';

import 'package:provider/provider.dart';

class LocalMusicProvider with ChangeNotifier {
  final LocalMusicService _localMusicService = LocalMusicService();
  final AudioPlayer _localPlayer = AudioPlayer();

  List<LocalMusicModel> _songs = [];
  List<LocalMusicModel> _filteredSongs = [];
  LocalMusicModel? _currentLocalTrack;
  int _currentLocalIndex = 0;

  bool _isLocalPlaying = false;
  Duration _localCurrentPosition = Duration.zero;
  Duration _localTotalDuration = Duration.zero;
  bool _isLocalLoading = false;

  String _searchQuery = '';
  String _loadingError = '';
  bool _autoPlayNext = true;

  List<LocalMusicModel> get songs => _filteredSongs;
  List<LocalMusicModel> get allSongs => _songs;
  LocalMusicModel? get currentLocalTrack => _currentLocalTrack;
  int get currentLocalIndex => _currentLocalIndex;
  bool get isLocalPlaying => _isLocalPlaying;
  Duration get localCurrentPosition => _localCurrentPosition;
  Duration get localTotalDuration => _localTotalDuration;
  bool get isLocalLoading => _isLocalLoading;
  String get searchQuery => _searchQuery;
  String get loadingError => _loadingError;
  bool get autoPlayNext => _autoPlayNext;
  AudioPlayer get localPlayer => _localPlayer;
  LocalMusicService get localMusicService => _localMusicService;

  // Progress as percentage (0.0 to 1.0)
  double get localProgress => _localTotalDuration.inMilliseconds > 0
      ? _localCurrentPosition.inMilliseconds / _localTotalDuration.inMilliseconds
      : 0.0;

  LocalMusicProvider() {
    _setupLocalPlayerListeners();
    // Don't setup notification callbacks here - they'll be set up when needed
  }

  void _setupLocalPlayerListeners() {
    // Listen to playing state changes
    _localPlayer.playingStream.listen((playing) {
      _isLocalPlaying = playing;
      _updateNotification(); // Update on play/pause state change
      notifyListeners();
    });

    // Listen to position changes
    _localPlayer.positionStream.listen((position) {
      _localCurrentPosition = position;
      // Let the notification service handle throttling
      _updateNotification();
      notifyListeners();
    });

    // Listen to duration changes
    _localPlayer.durationStream.listen((duration) {
      _localTotalDuration = duration ?? Duration.zero;
      _updateNotification(); // Update when duration is known
      notifyListeners();
    });

    // Listen to processing state changes
    _localPlayer.processingStateStream.listen((state) {
      _isLocalLoading = state == ProcessingState.loading ||
          state == ProcessingState.buffering;

      // Handle track completion
      if (state == ProcessingState.completed && _autoPlayNext) {
        _handleLocalTrackCompletion();
      }

      notifyListeners();
    });

    _localPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.ready &&
          playerState.playing == false) {
      }
    });
  }

  void _setupNotificationCallbacks() {
    log('🎵 Local _setupNotificationCallbacks called - isInitialized: ${NativeMediaNotificationService.instance.isInitialized}');
    if (NativeMediaNotificationService.instance.isInitialized) {
      log('🎵 Setting up notification callbacks for Local Music');
      NativeMediaNotificationService.instance.setLocalCallbacks(
        onPlay: () async {
          log('🎵 Local notification play button pressed');
          await resumeLocal();
        },
        onPause: () async {
          log('🎵 Local notification pause button pressed');
          await pauseLocal();
        },
        onStop: () async {
          log('🎵 Local notification stop button pressed');
          await stopLocal();
        },
        onNext: () async {
          log('🎵 Local notification next button pressed');
          await playNextLocal();
        },
        onPrevious: () async {
          log('🎵 Local notification previous button pressed');
          await playPreviousLocal();
        },
        onSeek: (position) async {
          log('🎵 Local notification seek called: ${position.inSeconds}s');
          await seekLocal(position);
        },
      );
    } else {
      log('❌ Cannot setup local notification callbacks - service not initialized');
    }
  }

  Future<void> _updateNotification() async {
    log('🎵 Local _updateNotification called - currentTrack: ${_currentLocalTrack?.title}, isPlaying: $_isLocalPlaying');
    
    if (_currentLocalTrack != null) {
      // Check if notification service is available
      if (!NativeMediaNotificationService.instance.isInitialized) {
        log('🎵 Notification service not initialized - skipping update');
        return;
      }
      
      // Always show notification for local music when playing
      if (_isLocalPlaying) {
        log('🎵 Local music is playing - forcing notification to show');
        NativeMediaNotificationService.instance.resetExplicitClose();
      }
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
      
      // No artwork for local music - show clean notification
      log('🎵 Showing local music notification without artwork');

      try {
        await NativeMediaNotificationService.instance.showMusicNotification(
          title: _currentLocalTrack!.title,
          artist: _currentLocalTrack!.artist,
          isPlaying: _isLocalPlaying,
          currentPosition: _localCurrentPosition,
          totalDuration: _localTotalDuration,
          // No artworkBytes or artworkUrl - clean notification
          isLocal: true,
        );
      } catch (e) {
        log('❌ Error updating local music notification: $e');
      }
    }
  }

  void _handleLocalTrackCompletion() {
    if (_currentLocalIndex < _filteredSongs.length - 1) {
      playNextLocal();
    } else {
      log('Local playlist completed');
    }
  }

  Future<void> loadLocalSongs() async {
    try {
      _isLocalLoading = true;
      _loadingError = '';
      notifyListeners();

      _songs = await _localMusicService.loadAllSongs();
      _filteredSongs = List.from(_songs);

      _isLocalLoading = false;
      log('Loaded ${_songs.length} local songs');
      notifyListeners();
    } catch (e) {
      _isLocalLoading = false;
      _loadingError = e.toString();
      log('Error loading local songs: $e');
      notifyListeners();
    }
  }

  void searchLocalSongs(String query) {
    _searchQuery = query;
    _localMusicService.searchSongs(query);
    _filteredSongs = _localMusicService.filteredSongs;

    if (_currentLocalTrack != null &&
        !_filteredSongs.any((song) => song.id == _currentLocalTrack!.id)) {
      _updateCurrentTrackIndex();
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredSongs = List.from(_songs);
    _updateCurrentTrackIndex();
    notifyListeners();
  }

  void _updateCurrentTrackIndex() {
    if (_currentLocalTrack != null) {
      _currentLocalIndex = _filteredSongs.indexWhere(
              (song) => song.id == _currentLocalTrack!.id
      );
      if (_currentLocalIndex == -1) {
        _currentLocalIndex = 0;
      }
    }
  }

  Future<void> playLocalTrack(LocalMusicModel track, int index, {BuildContext? context}) async {
    try {
      // Reset notification explicit close flag when starting new track
      NativeMediaNotificationService.instance.resetExplicitClose();
      
      // Setup notification callbacks if not already done
      _setupNotificationCallbacks();
      
      // CRITICAL FIX: Stop SoundCloud music before playing local
      if (context != null) {
        final soundCloudProvider = Provider.of<SoundCloudAudioProvider>(context, listen: false);
        if (soundCloudProvider.isPlaying) {
          await soundCloudProvider.stop();
        }
      }

      await _localPlayer.stop();
      _isLocalLoading = true;
      _currentLocalTrack = track;
      _currentLocalIndex = index;
      notifyListeners();

      log('Playing local track: ${track.title} from ${track.filePath}');

      await _localPlayer.setFilePath(track.filePath);
      await _localPlayer.play();
      await _updateNotification();

      _isLocalLoading = false;
      notifyListeners();
    } catch (e) {
      _isLocalLoading = false;
      _loadingError = 'Failed to play track: ${e.toString()}';
      log('Error playing local track: $e');
      notifyListeners();
    }
  }

  Future<void> playLocalTrackAtIndex(int index, {BuildContext? context}) async {
    if (index >= 0 && index < _filteredSongs.length) {
      await playLocalTrack(_filteredSongs[index], index, context: context);
    }
  }

  Future<void> playNextLocal({BuildContext? context}) async {
    if (_currentLocalIndex < _filteredSongs.length - 1) {
      await playLocalTrack(_filteredSongs[_currentLocalIndex + 1], _currentLocalIndex + 1, context: context);
    }
  }

  Future<void> playPreviousLocal({BuildContext? context}) async {
    if (_currentLocalIndex > 0) {
      await playLocalTrack(_filteredSongs[_currentLocalIndex - 1], _currentLocalIndex - 1, context: context);
    }
  }

  bool get hasNextTrack => _currentLocalIndex < _filteredSongs.length - 1;

  bool get hasPreviousTrack => _currentLocalIndex > 0;

  Future<void> pauseLocal() async {
    try {
      await _localPlayer.pause();
    } catch (e) {
      log('Error pausing: $e');
    }
  }

  // Resume current track
  Future<void> resumeLocal() async {
    try {
      await _localPlayer.play();
    } catch (e) {
      log('Error resuming: $e');
    }
  }

  Future<void> stopLocal() async {
    try {
      await _localPlayer.stop();
      // Hide notification when stopped and reset active provider
      if (NativeMediaNotificationService.instance.isInitialized) {
        await NativeMediaNotificationService.instance.hideNotification();
        NativeMediaNotificationService.instance.setActiveProvider('none');
      }
      // _currentLocalPosition = Duration.zero;
      notifyListeners();
    } catch (e) {
      log('Error stopping: $e');
    }
  }

  Future<void> seekLocal(Duration position) async {
    try {
      await _localPlayer.seek(position);
    } catch (e) {
      log('Error seeking: $e');
    }
  }

  // Seek forward by 10 seconds
  Future<void> seekForward() async {
    final newPosition = _localCurrentPosition + const Duration(seconds: 10);
    if (newPosition < _localTotalDuration) {
      await seekLocal(newPosition);
    } else {
      await seekLocal(_localTotalDuration);
    }
  }

  Future<void> seekBackward() async {
    final newPosition = _localCurrentPosition - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      await seekLocal(newPosition);
    } else {
      await seekLocal(Duration.zero);
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _localPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      log('Error setting volume: $e');
    }
  }

  Future<void> setSpeed(double speed) async {
    try {
      await _localPlayer.setSpeed(speed.clamp(0.5, 2.0));
    } catch (e) {
      log('Error setting speed: $e');
    }
  }

  void setAutoPlayNext(bool enabled) {
    _autoPlayNext = enabled;
    notifyListeners();
  }

  /// Set a custom collection of downloaded songs for playback
  void setDownloadedSongsCollection(List<LocalMusicModel> downloadedSongs) {
    _filteredSongs = List.from(downloadedSongs);
    _songs = List.from(downloadedSongs);
    notifyListeners();
    log('Set downloaded songs collection: ${downloadedSongs.length} songs');
  }

  Future<Uint8List?> getSongArtwork(int songId) async {
    try {
      // Check if this is a downloaded song by looking at the current track
      if (_currentLocalTrack != null && _isDownloadedSong(_currentLocalTrack!)) {
        log('Skipping artwork query for downloaded song: ${_currentLocalTrack!.title}');
        return null; // Don't try to get artwork from system media library for downloaded songs
      }
      
      return await _localMusicService.getSongArtwork(songId);
    } catch (e) {
      log('Error getting artwork: $e');
      return null;
    }
  }

  /// Check if a song is a downloaded song (not from system media library)
  bool _isDownloadedSong(LocalMusicModel song) {
    // Downloaded songs have artwork URLs instead of file paths
    return song.artworkPath != null && 
           song.artworkPath!.startsWith('http');
  }

  void shufflePlaylist() {
    if (_songs.length > 1) {
      _filteredSongs.shuffle();
      _updateCurrentTrackIndex();
      notifyListeners();
    }
  }

  void sortSongs(SortCriteria criteria, {bool ascending = true}) {
    _localMusicService.sortSongs(criteria, ascending: ascending);
    _filteredSongs = _localMusicService.filteredSongs;
    _updateCurrentTrackIndex();
    notifyListeners();
  }

  List<LocalMusicModel> getSongsByArtist(String artist) {
    return _songs.where((song) => song.artist == artist).toList();
  }

  List<LocalMusicModel> getSongsByAlbum(String album) {
    return _songs.where((song) => song.album == album).toList();
  }

  List<String> getAllArtists() {
    return _songs.map((song) => song.artist).toSet().toList()..sort();
  }

  List<String> getAllAlbums() {
    return _songs
        .where((song) => song.album != null)
        .map((song) => song.album!)
        .toSet()
        .toList()..sort();
  }

  void clearAll() {
    _songs.clear();
    _filteredSongs.clear();
    _currentLocalTrack = null;
    _currentLocalIndex = 0;
    _searchQuery = '';
    _loadingError = '';
    stopLocal();
    notifyListeners();
  }

  @override
  void dispose() {
    log('Disposing LocalMusicProvider');
    // Hide notification when disposing
    if (NativeMediaNotificationService.instance.isInitialized) {
      NativeMediaNotificationService.instance.hideNotification();
    }
    _localPlayer.dispose();
    super.dispose();
  }
}

