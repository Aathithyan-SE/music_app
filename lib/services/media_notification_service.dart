import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

class MediaNotificationService extends BaseAudioHandler with QueueHandler, SeekHandler {
  static MediaNotificationService? _instance;
  static MediaNotificationService get instance => _instance ??= MediaNotificationService._internal();

  MediaNotificationService._internal();

  final _player = AudioPlayer();
  AudioPlayer get player => _player;

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    // Will be handled by the provider
  }

  @override
  Future<void> skipToPrevious() async {
    // Will be handled by the provider
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  void setupPlayerListeners() {
    _player.playingStream.listen((playing) {
      playbackState.add(
        playbackState.value.copyWith(
          playing: playing,
          controls: [
            MediaControl.skipToPrevious,
            playing ? MediaControl.pause : MediaControl.play,
            MediaControl.skipToNext,
          ],
          androidCompactActionIndices: [0, 1, 2],
        ),
      );
    });

    _player.positionStream.listen((position) {
      final duration = _player.duration ?? Duration.zero;
      playbackState.add(
        playbackState.value.copyWith(
          updatePosition: position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: 0,
        ),
      );
    });

    _player.durationStream.listen((duration) {
      if (duration != null) {
        final item = mediaItem.value;
        if (item != null) {
          mediaItem.add(item.copyWith(duration: duration));
        }
      }
    });

    _player.processingStateStream.listen((state) {
      switch (state) {
        case ProcessingState.idle:
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.idle,
          ));
          break;
        case ProcessingState.loading:
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.loading,
          ));
          break;
        case ProcessingState.buffering:
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.buffering,
          ));
          break;
        case ProcessingState.ready:
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.ready,
          ));
          break;
        case ProcessingState.completed:
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.completed,
          ));
          break;
      }
    });
  }

  Future<void> initializeNotification() async {
    setupPlayerListeners();

    // Initialize playback state
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: [0, 1, 2],
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1.0,
        queueIndex: 0,
      ),
    );
  }

  Future<void> setCustomMediaItem({
    required String title,
    required String artist,
    Uint8List? artworkBytes,
    String? artworkUrl,
    Duration? duration,
  }) async {
    final item = MediaItem(
      id: title.hashCode.toString(),
      album: "Current Playing",
      title: title,
      artist: artist,
      duration: duration ?? Duration.zero,
      artUri: artworkUrl != null ? Uri.parse(artworkUrl) : null,
      extras: artworkBytes != null ? {'artworkBytes': artworkBytes} : null,
    );

    mediaItem.add(item);
  }

  Future<void> setAudioSource(AudioSource source) async {
    await _player.setAudioSource(source);
  }

  Future<void> setFilePath(String filePath) async {
    await _player.setFilePath(filePath);
  }
}

// Helper class to initialize the audio service
class AudioServiceHelper {
  static Future<void> init() async {
    await AudioService.init(
      builder: () => MediaNotificationService.instance,
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.modizk.audio',
        androidNotificationChannelName: 'Modizk Music',
        androidNotificationChannelDescription: 'Music playback controls',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
        androidNotificationClickStartsActivity: true,
        androidStopForegroundOnPause: false,
      ),
    );

    await MediaNotificationService.instance.initializeNotification();
  }
}