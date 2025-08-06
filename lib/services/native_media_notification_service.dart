import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

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
  
  // Track if user explicitly closed the notification to prevent auto-reopening
  bool _userExplicitlyClosed = false;
  
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

  // Cache the custom music icon to avoid loading it every time
  static String? _cachedCustomIconDataUri;
  
  /// Load custom music icon from assets and cache it
  Future<String?> _getCustomMusicIcon() async {
    if (_cachedCustomIconDataUri != null) {
      return _cachedCustomIconDataUri;
    }
    
    try {
      final ByteData assetData = await rootBundle.load('assets/images/ic_music.png');
      final Uint8List assetBytes = assetData.buffer.asUint8List();
      final base64String = base64Encode(assetBytes);
      _cachedCustomIconDataUri = 'data:image/png;base64,$base64String';
      log('🎵 Custom music icon loaded and cached (${assetBytes.length} bytes)');
      return _cachedCustomIconDataUri;
    } catch (e) {
      log('❌ Failed to load custom music icon: $e');
      return null;
    }
  }

  /// Request notification permissions
  Future<bool> _requestNotificationPermissions() async {
    try {
      log('🎵 Requesting notification permissions...');
      
      // Request notification permission for Android 13+
      final notificationStatus = await Permission.notification.status;
      log('🎵 Current notification permission status: $notificationStatus');
      
      if (notificationStatus.isDenied) {
        final result = await Permission.notification.request();
        log('🎵 Notification permission request result: $result');
        if (result.isDenied) {
          log('❌ Notification permission denied');
          return false;
        }
      }
      
      log('✅ Notification permissions granted');
      return true;
    } catch (e) {
      log('❌ Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Initialize the native media notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      log('🎵 Initializing Native Media Notification Service...');
      
      // Request notification permissions first
      final permissionsGranted = await _requestNotificationPermissions();
      if (!permissionsGranted) {
        log('⚠️ Notification permissions not granted, but continuing with initialization...');
      }
      
      // Preload custom music icon
      await _getCustomMusicIcon();
      log('🎵 Custom music icon preloaded during initialization');
      _audioHandler = await AudioService.init(
        builder: () => MediaNotificationHandler(this),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.mycompany.CounterApp.audio',
          androidNotificationChannelName: 'Music Player',
          androidNotificationChannelDescription: 'Music playback controls',
          androidNotificationOngoing: true,
          // Remove icon completely - let it use default or artwork only
          androidShowNotificationBadge: true,
          androidStopForegroundOnPause: false,
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
      // Reset the explicit close flag when switching to a new provider (new song)
      _userExplicitlyClosed = false;
    }
  }

  /// Get the currently active provider
  String get activeProvider => _activeProvider;

  /// Reset the explicit close flag (called when user starts playing a new song)
  void resetExplicitClose() {
    _userExplicitlyClosed = false;
    log('🎵 Notification explicit close flag reset - notifications can show again');
  }
  
  /// Force reset notification state for debugging
  void forceResetNotificationState() {
    _userExplicitlyClosed = false;
    _activeProvider = 'none';
    log('🎵 FORCE RESET: notification state cleared');
  }

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
    // Don't show notification if user explicitly closed it
    if (_userExplicitlyClosed) {
      log('🎵 Notification was explicitly closed by user - not showing');
      return;
    }
    
    log('🎵 showMusicNotification - userExplicitlyClosed: $_userExplicitlyClosed, activeProvider: $_activeProvider');
    log('🎵 Native showMusicNotification called: $title by $artist (${isPlaying ? "Playing" : "Paused"}) - isLocal: $isLocal, isInitialized: $_isInitialized');
    
    // Force reset for local music to ensure it always shows
    if (isLocal) {
      log('🎵 Local music detected - forcing notification to show');
      _userExplicitlyClosed = false;
    }
    
    // Set active provider based on source
    setActiveProvider(isLocal ? 'local' : 'soundcloud');
    
    if (!_isInitialized || _audioHandler == null) {
      log('❌ Native Media Notification Service not initialized');
      return;
    }

    try {
      // Always ensure we have artwork - use custom icon as fallback
      Uri artworkUri;
      
      // For local music, ALWAYS use custom icon (no artwork)
      if (isLocal) {
        final customIcon = await _getCustomMusicIcon();
        if (customIcon != null) {
          artworkUri = Uri.parse(customIcon);
          log('🎵 Using custom music icon for local music');
        } else {
          // Fallback: create a minimal data URI to prevent app logo
          artworkUri = Uri.parse('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
          log('🎵 Using minimal fallback icon for local music');
        }
      } else if (artworkUrl != null && artworkUrl.isNotEmpty && Uri.tryParse(artworkUrl) != null) {
        // For SoundCloud: try to use track artwork first
        try {
          artworkUri = Uri.parse(artworkUrl);
          log('🎵 Using SoundCloud artwork URL: $artworkUrl');
        } catch (e) {
          log('🎵 Error parsing SoundCloud artwork URL: $e');
          // Fallback to custom icon
          final customIcon = await _getCustomMusicIcon();
          if (customIcon != null) {
            artworkUri = Uri.parse(customIcon);
            log('🎵 Using custom music icon as SoundCloud fallback');
          } else {
            artworkUri = Uri.parse('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
            log('🎵 Using minimal fallback for SoundCloud');
          }
        }
      } else if (artworkBytes != null && artworkBytes.isNotEmpty) {
        // Use provided artwork bytes
        try {
          final base64String = base64Encode(artworkBytes);
          artworkUri = Uri.parse('data:image/jpeg;base64,$base64String');
          log('🎵 Using provided artwork bytes (${artworkBytes.length} bytes)');
        } catch (e) {
          log('🎵 Error creating artwork data URI: $e');
          // Fallback to custom icon
          final customIcon = await _getCustomMusicIcon();
          if (customIcon != null) {
            artworkUri = Uri.parse(customIcon);
            log('🎵 Using custom music icon as bytes fallback');
          } else {
            artworkUri = Uri.parse('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
            log('🎵 Using minimal fallback for bytes');
          }
        }
      } else {
        // No artwork at all - use custom music icon
        final customIcon = await _getCustomMusicIcon();
        if (customIcon != null) {
          artworkUri = Uri.parse(customIcon);
          log('🎵 Using custom music icon (no artwork provided)');
        } else {
          artworkUri = Uri.parse('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
          log('🎵 Using minimal fallback (no artwork, no custom icon)');
        }
      }
      
      // Create MediaItem for the notification
      log('🎵 Creating MediaItem - title: $title, artist: $artist, duration: ${totalDuration.inSeconds}s, artUri: $artworkUri');
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
      log('🎵 MediaItem created successfully');

      // Remove stop action to simplify notification - just use standard controls

      // Update the media item and playback state through the handler
      final handler = _audioHandler! as MediaNotificationHandler;
      log('🎵 About to call handler.updateMediaItem...');
      await handler.updateMediaItem(mediaItem);
      log('🎵 handler.updateMediaItem completed successfully');
      
      // Create playback state with proper configuration
      final playbackState = PlaybackState(
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
      );
      
      log('🎵 About to update playback state...');
      handler.updatePlaybackState(playbackState);
      log('🎵 Playback state updated successfully');
      
      // Ensure the service is started as foreground
      if (isPlaying) {
        log('🎵 Starting playback to show notification...');
        await _audioHandler!.play();
      }

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
      
      // Reset active provider and explicit close flag
      _activeProvider = 'none';
      _userExplicitlyClosed = false;
      
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
  
  // Debouncing variables to prevent rapid button clicks
  DateTime? _lastPlayPauseClick;
  DateTime? _lastNextClick;
  DateTime? _lastPreviousClick;
  DateTime? _lastStopClick;
  static const Duration _debounceDelay = Duration(milliseconds: 500);
  
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
    // Debounce rapid clicks
    final now = DateTime.now();
    if (_lastPlayPauseClick != null && 
        now.difference(_lastPlayPauseClick!) < _debounceDelay) {
      log('🎵 Play button debounced');
      return;
    }
    _lastPlayPauseClick = now;
    
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
    // Debounce rapid clicks
    final now = DateTime.now();
    if (_lastPlayPauseClick != null && 
        now.difference(_lastPlayPauseClick!) < _debounceDelay) {
      log('🎵 Pause button debounced');
      return;
    }
    _lastPlayPauseClick = now;
    
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
    // Debounce rapid clicks
    final now = DateTime.now();
    if (_lastNextClick != null && 
        now.difference(_lastNextClick!) < _debounceDelay) {
      log('🎵 Next button debounced');
      return;
    }
    _lastNextClick = now;
    
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
    // Debounce rapid clicks
    final now = DateTime.now();
    if (_lastPreviousClick != null && 
        now.difference(_lastPreviousClick!) < _debounceDelay) {
      log('🎵 Previous button debounced');
      return;
    }
    _lastPreviousClick = now;
    
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
    // Debounce rapid clicks
    final now = DateTime.now();
    if (_lastStopClick != null && 
        now.difference(_lastStopClick!) < _debounceDelay) {
      log('🎵 Stop button debounced');
      return;
    }
    _lastStopClick = now;
    
    log('🎵 Native notification close button pressed - active provider: ${_service.activeProvider}');
    
    // Mark as explicitly closed by user to prevent auto-reopening
    _service._userExplicitlyClosed = true;
    
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
    
    // Hide the notification completely when close is pressed
    await _service.hideNotification();
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