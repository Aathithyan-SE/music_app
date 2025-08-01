import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';

/// Native Android MediaStyle notification service using audio_service
/// This creates the same type of media notifications that Spotify, YouTube Music, etc. use
class NativeMediaNotificationService {
  static NativeMediaNotificationService? _instance;
  static NativeMediaNotificationService get instance => _instance ??= NativeMediaNotificationService._internal();
  
  NativeMediaNotificationService._internal();

  static AudioHandler? _audioHandler;
  bool _isInitialized = false;
  
  // Track which provider is currently active
  String _activeProvider = 'none'; // 'local', 'soundcloud', or 'none'
  
  // Track app lifecycle to properly clean up notifications
  StreamSubscription? _taskKillerSubscription;
  
  // Callbacks for local music provider
  Function()? onLocalPlayPressed;
  Function()? onLocalPausePressed; 
  Function()? onLocalStopPressed;
  Function()? onLocalSkipToNext;
  Function()? onLocalSkipToPrevious;
  Function(Duration)? onLocalSeek;
  
  // Callbacks for SoundCloud provider
  Function()? onSoundCloudPlayPressed;
  Function()? onSoundCloudPausePressed; 
  Function()? onSoundCloudStopPressed;
  Function()? onSoundCloudSkipToNext;
  Function()? onSoundCloudSkipToPrevious;
  Function(Duration)? onSoundCloudSeek;
  
  // Legacy callbacks for backward compatibility
  Function()? onPlayPressed;
  Function()? onPausePressed; 
  Function()? onStopPressed;
  Function()? onSkipToNext;
  Function()? onSkipToPrevious;
  Function(Duration)? onSeek;

  /// Initialize the native media notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      log('🎵 Initializing Native Media Notification Service...');
      _audioHandler = await AudioService.init(
        builder: () => MediaNotificationHandler(this),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.mycompany.CounterApp.audio',
          androidNotificationChannelName: 'Music Player',
          androidNotificationChannelDescription: 'Music playback controls',
          androidNotificationOngoing: false,
          androidNotificationIcon: 'mipmap/ic_launcher',
          androidShowNotificationBadge: true,
          androidStopForegroundOnPause: true,
          androidResumeOnClick: true,
          androidNotificationClickStartsActivity: true,
        ),
      );
      
      // Setup task killer detection
      _setupTaskKillerDetection();
      
      _isInitialized = true;
      log('🎵 ✅ Native Media Notification Service initialized successfully!');
    } catch (e) {
      log('❌ Error initializing Native Media Notification Service: $e');
      rethrow;
    }
  }

  /// Setup task killer detection to clean up notifications when app is terminated
  void _setupTaskKillerDetection() {
    try {
      // Listen to system events that indicate app termination
      SystemChannels.lifecycle.setMessageHandler((message) async {
        log('🎵 App lifecycle event: $message');
        
        if (message == 'AppLifecycleState.detached') {
          // App is being killed - clean up notification
          log('🎵 App being killed - cleaning up notification');
          await _forceCleanupNotification();
        }
        return null;
      });
      
      log('🎵 Task killer detection setup complete');
    } catch (e) {
      log('❌ Error setting up task killer detection: $e');
    }
  }

  /// Force cleanup notification when app is terminated
  Future<void> _forceCleanupNotification() async {
    try {
      if (_audioHandler != null) {
        await _audioHandler!.stop();
        await (_audioHandler as MediaNotificationHandler).cleanup();
      }
      _activeProvider = 'none';
      log('🎵 Force cleanup completed');
    } catch (e) {
      log('❌ Error during force cleanup: $e');
    }
  }

  /// Set active provider and ensure only one source updates notifications
  void setActiveProvider(String provider) {
    if (provider != _activeProvider) {
      log('🎵 Switching active provider from $_activeProvider to $provider');
      _activeProvider = provider;
    }
  }

  /// Get the currently active provider
  String get activeProvider => _activeProvider;

  /// Show music notification (API compatible with MediaNotificationService)
  Future<void> showMusicNotification({
    required String title,
    required String artist,
    required bool isPlaying,
    required Duration currentPosition,
    required Duration totalDuration,
    String? artworkUrl,
    Uint8List? artworkBytes,
    bool isLocal = false,
  }) async {
    // log('🎵 Native showMusicNotification called: $title by $artist (${isPlaying ? "Playing" : "Paused"}) - isLocal: $isLocal');
    
    // Set active provider based on source
    setActiveProvider(isLocal ? 'local' : 'soundcloud');
    
    if (!_isInitialized || _audioHandler == null) {
      log('❌ Native Media Notification Service not initialized');
      return;
    }

    try {
      // Handle artwork properly - prioritize actual music artwork over app icon
      Uri? artworkUri;
      
      if (artworkBytes != null && artworkBytes.isNotEmpty) {
        // Convert local artwork bytes to data URI
        final base64String = base64Encode(artworkBytes);
        artworkUri = Uri.parse('data:image/jpeg;base64,$base64String');
        log('🎵 Using local artwork data URI (${artworkBytes.length} bytes)');
      } else if (artworkUrl != null && artworkUrl.isNotEmpty) {
        // Use remote artwork URL
        artworkUri = Uri.parse(artworkUrl);
        log('🎵 Using remote artwork URL: $artworkUrl');
      } else {
        // No artwork available - don't set artUri to avoid showing app icon
        // log('🎵 No artwork available - notification will show default music icon');
      }
      
      // Create MediaItem for the notification
      final mediaItem = MediaItem(
        id: isLocal ? 'local_$title' : 'remote_$title',
        title: title,
        artist: artist,
        duration: totalDuration,
        artUri: artworkUri, // Only set when actual music artwork is available
        album: 'MelodyVault',
        genre: 'Music',
        playable: true,
        extras: {
          'isLocal': isLocal,
          'currentPosition': currentPosition.inMilliseconds,
        },
      );

      // Update the media item and playback state through the handler
      final handler = _audioHandler! as MediaNotificationHandler;
      await handler.updateMediaItem(mediaItem);
      handler.updatePlaybackState(PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 2], // prev, play/pause, next
        processingState: AudioProcessingState.ready,
        playing: isPlaying,
        updatePosition: currentPosition,
        bufferedPosition: totalDuration,
        speed: isPlaying ? 1.0 : 0.0,
        queueIndex: 0,
      ));

      log('🎵 Native media notification updated: $title by $artist (${isPlaying ? "Playing" : "Paused"})');
    } catch (e) {
      log('❌ Error updating native media notification: $e');
    }
  }

  /// Hide/remove the media notification
  Future<void> hideNotification() async {
    if (!_isInitialized || _audioHandler == null) return;

    try {
      // More aggressive cleanup when explicitly hiding
      final handler = _audioHandler! as MediaNotificationHandler;
      await handler.cleanup();
      await _audioHandler!.stop();
      
      // Reset active provider
      _activeProvider = 'none';
      
      log('🎵 Native media notification hidden and cleaned up');
    } catch (e) {
      log('❌ Error hiding native media notification: $e');
    }
  }

  /// Set callback functions for local music provider
  void setLocalCallbacks({
    Function()? onPlay,
    Function()? onPause,
    Function()? onStop,
    Function()? onNext,
    Function()? onPrevious,
    Function(Duration)? onSeek,
  }) {
    if (!_isInitialized) return;
    
    log('🎵 Setting local music callbacks');
    onLocalPlayPressed = onPlay;
    onLocalPausePressed = onPause;
    onLocalStopPressed = onStop;
    onLocalSkipToNext = onNext;
    onLocalSkipToPrevious = onPrevious;
    onLocalSeek = onSeek;
  }

  /// Set callback functions for SoundCloud provider
  void setSoundCloudCallbacks({
    Function()? onPlay,
    Function()? onPause,
    Function()? onStop,
    Function()? onNext,
    Function()? onPrevious,
    Function(Duration)? onSeek,
  }) {
    if (!_isInitialized) return;
    
    log('🎵 Setting SoundCloud callbacks');
    onSoundCloudPlayPressed = onPlay;
    onSoundCloudPausePressed = onPause;
    onSoundCloudStopPressed = onStop;
    onSoundCloudSkipToNext = onNext;
    onSoundCloudSkipToPrevious = onPrevious;
    onSoundCloudSeek = onSeek;
  }

  /// Set callback functions (API compatible with MediaNotificationService)
  void setCallbacks({
    Function()? onPlay,
    Function()? onPause,
    Function()? onStop,
    Function()? onNext,
    Function()? onPrevious,
    Function(Duration)? onSeek,
  }) {
    if (!_isInitialized) return;
    
    onPlayPressed = onPlay;
    onPausePressed = onPause;
    onStopPressed = onStop;
    onSkipToNext = onNext;
    onSkipToPrevious = onPrevious;
    this.onSeek = onSeek;
  }

  /// Check if initialized (API compatible with MediaNotificationService)
  bool get isInitialized => _isInitialized;

  /// Dispose (API compatible with MediaNotificationService)
  Future<void> dispose() async {
    if (_isInitialized) {
      log('🎵 Disposing Native Media Notification Service...');
      
      try {
        // Cancel task killer subscription
        await _taskKillerSubscription?.cancel();
        _taskKillerSubscription = null;
        
        // Hide notification and cleanup
        await hideNotification();
        
        // Force cleanup the audio handler
        if (_audioHandler != null) {
          await _audioHandler!.stop();
          await (_audioHandler as MediaNotificationHandler).cleanup();
        }
        
        // Reset state
        _activeProvider = 'none';
        _isInitialized = false;
        
        log('🎵 ✅ Native Media Notification Service disposed successfully');
      } catch (e) {
        log('❌ Error disposing notification service: $e');
      }
    }
  }

  /// Get the audio handler for media controls
  static AudioHandler? get audioHandler => _audioHandler;
}

/// Custom AudioHandler that manages the native media notification
class MediaNotificationHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  
  final NativeMediaNotificationService _service;
  
  MediaNotificationHandler(this._service);

  /// Update the current media item
  @override
  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }

  /// Update the playback state
  void updatePlaybackState(PlaybackState state) {
    playbackState.add(state);
  }
  
  /// Handle play button press
  @override
  Future<void> play() async {
    log('🎵 Native notification play button pressed - active provider: ${_service.activeProvider}');
    
    // Call the appropriate callback based on active provider
    switch (_service.activeProvider) {
      case 'local':
        _service.onLocalPlayPressed?.call();
        break;
      case 'soundcloud':
        _service.onSoundCloudPlayPressed?.call();
        break;
      default:
        _service.onPlayPressed?.call(); // Fallback to legacy callback
        break;
    }
    
    playbackState.add(playbackState.value.copyWith(
      playing: true,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
    ));
  }

  /// Handle pause button press
  @override
  Future<void> pause() async {
    log('🎵 Native notification pause button pressed - active provider: ${_service.activeProvider}');
    
    // Call the appropriate callback based on active provider
    switch (_service.activeProvider) {
      case 'local':
        _service.onLocalPausePressed?.call();
        break;
      case 'soundcloud':
        _service.onSoundCloudPausePressed?.call();
        break;
      default:
        _service.onPausePressed?.call(); // Fallback to legacy callback
        break;
    }
    
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
    ));
  }

  /// Handle next button press
  @override
  Future<void> skipToNext() async {
    log('🎵 Native notification next button pressed - active provider: ${_service.activeProvider}');
    
    // Call the appropriate callback based on active provider
    switch (_service.activeProvider) {
      case 'local':
        _service.onLocalSkipToNext?.call();
        break;
      case 'soundcloud':
        _service.onSoundCloudSkipToNext?.call();
        break;
      default:
        _service.onSkipToNext?.call(); // Fallback to legacy callback
        break;
    }
  }

  /// Handle previous button press
  @override
  Future<void> skipToPrevious() async {
    log('🎵 Native notification previous button pressed - active provider: ${_service.activeProvider}');
    
    // Call the appropriate callback based on active provider
    switch (_service.activeProvider) {
      case 'local':
        _service.onLocalSkipToPrevious?.call();
        break;
      case 'soundcloud':
        _service.onSoundCloudSkipToPrevious?.call();
        break;
      default:
        _service.onSkipToPrevious?.call(); // Fallback to legacy callback
        break;
    }
  }

  /// Handle seek/scrub on progress bar
  @override
  Future<void> seek(Duration position) async {
    log('🎵 Native notification seek to: ${position.inSeconds}s - active provider: ${_service.activeProvider}');
    
    // Call the appropriate callback based on active provider
    switch (_service.activeProvider) {
      case 'local':
        _service.onLocalSeek?.call(position);
        break;
      case 'soundcloud':
        _service.onSoundCloudSeek?.call(position);
        break;
      default:
        _service.onSeek?.call(position); // Fallback to legacy callback
        break;
    }
    
    // Update the playback state with new position
    playbackState.add(playbackState.value.copyWith(
      updatePosition: position,
    ));
  }



  /// Handle stop
  @override
  Future<void> stop() async {
    log('🎵 Native notification stopped - active provider: ${_service.activeProvider}');
    
    // Call the appropriate callback based on active provider
    switch (_service.activeProvider) {
      case 'local':
        _service.onLocalStopPressed?.call();
        break;
      case 'soundcloud':
        _service.onSoundCloudStopPressed?.call();
        break;
      default:
        _service.onStopPressed?.call(); // Fallback to legacy callback
        break;
    }
    
    await cleanup();
    super.stop();
  }

  /// Cleanup method for when app is terminated or disposed
  Future<void> cleanup() async {
    try {
      log('🎵 MediaNotificationHandler cleanup started');
      
      // Clear all media items and stop playback state
      mediaItem.add(null);
      playbackState.add(PlaybackState(
        controls: [],
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 0.0,
      ));
      
      log('🎵 MediaNotificationHandler cleanup completed');
    } catch (e) {
      log('❌ Error during MediaNotificationHandler cleanup: $e');
    }
  }

  /// Handle task killer scenarios
  @override
  Future<void> onTaskRemoved() async {
    log('🎵 Task removed - cleaning up notification');
    await cleanup();
    super.onTaskRemoved();
  }
}

// Alias for backward compatibility with existing code
class MediaNotificationService {
  static MediaNotificationService? _instance;
  static MediaNotificationService get instance => _instance ??= MediaNotificationService._internal();
  
  MediaNotificationService._internal();

  // Delegate all calls to the native service
  Future<void> initialize() async {
    log('🎵 MediaNotificationService initialize() - using native audio_service...');
    await NativeMediaNotificationService.instance.initialize();
  }

  bool get isInitialized => NativeMediaNotificationService.instance.isInitialized;

  void setCallbacks({
    Function()? onPlay,
    Function()? onPause,
    Function()? onStop,
    Function()? onNext,
    Function()? onPrevious,
    Function(Duration)? onSeek,
  }) {
    NativeMediaNotificationService.instance.setCallbacks(
      onPlay: onPlay,
      onPause: onPause,
      onStop: onStop,
      onNext: onNext,
      onPrevious: onPrevious,
      onSeek: onSeek,
    );
  }

  Future<void> showMusicNotification({
    required String title,
    required String artist,
    required bool isPlaying,
    required Duration currentPosition,
    required Duration totalDuration,
    String? artworkUrl,
    Uint8List? artworkBytes,
    bool isLocal = false,
  }) async {
    await NativeMediaNotificationService.instance.showMusicNotification(
      title: title,
      artist: artist,
      isPlaying: isPlaying,
      currentPosition: currentPosition,
      totalDuration: totalDuration,
      artworkUrl: artworkUrl,
      artworkBytes: artworkBytes,
      isLocal: isLocal,
    );
  }

  Future<void> hideNotification() async {
    await NativeMediaNotificationService.instance.hideNotification();
  }

  Future<void> dispose() async {
    await NativeMediaNotificationService.instance.dispose();
  }
}