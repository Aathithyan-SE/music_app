import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modizk_download/models/downloaded_song.dart';
import 'package:modizk_download/models/sound_cloud_search_response.dart';
import 'package:modizk_download/services/music_provider.dart';

class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio();
  SharedPreferences? _prefs;

  // Keys for SharedPreferences
  static const String _downloadedSongsKey = 'downloaded_songs';

  // Local state
  List<DownloadedSong> _downloadedSongs = [];
  Map<String, double> _downloadProgress = {};
  Map<String, bool> _downloadingStatus = {};

  // Getters
  List<DownloadedSong> get downloadedSongs => _downloadedSongs;
  Map<String, double> get downloadProgress => _downloadProgress;
  Map<String, bool> get downloadingStatus => _downloadingStatus;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadDownloadedSongs();
  }

  // Load downloaded songs from SharedPreferences
  Future<void> _loadDownloadedSongs() async {
    try {
      final String? songsJson = _prefs?.getString(_downloadedSongsKey);
      if (songsJson != null) {
        final List<dynamic> songsList = json.decode(songsJson);
        _downloadedSongs = songsList.map((item) => DownloadedSong.fromJson(item)).toList();
        
        // Clean up songs whose files no longer exist
        await _cleanupMissingSongs();
      }
    } catch (e) {
      log('Error loading downloaded songs: $e');
      _downloadedSongs = [];
    }
  }

  // Save downloaded songs to SharedPreferences
  Future<void> _saveDownloadedSongs() async {
    try {
      final String songsJson = json.encode(_downloadedSongs.map((s) => s.toJson()).toList());
      await _prefs?.setString(_downloadedSongsKey, songsJson);
    } catch (e) {
      log('Error saving downloaded songs: $e');
    }
  }

  // Clean up songs whose files no longer exist
  Future<void> _cleanupMissingSongs() async {
    final List<DownloadedSong> validSongs = [];
    
    for (final song in _downloadedSongs) {
      final file = File(song.localFilePath);
      if (await file.exists()) {
        validSongs.add(song);
      }
    }
    
    if (validSongs.length != _downloadedSongs.length) {
      _downloadedSongs = validSongs;
      await _saveDownloadedSongs();
      notifyListeners();
    }
  }

  // Get downloads directory
  Future<Directory> _getDownloadsDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory downloadsDir = Directory('${appDocDir.path}/downloads');
    
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    
    return downloadsDir;
  }

  // Download a SoundCloud track
  Future<bool> downloadTrack(Track track, MusicProvider musicProvider) async {
    try {
      final String trackId = track.id.toString();
      
      // Check if already downloaded
      if (isTrackDownloaded(trackId)) {
        return false; // Already downloaded
      }

      // Check if currently downloading
      if (_downloadingStatus[trackId] == true) {
        return false; // Already downloading
      }

      // Check if track is streamable
      if (!track.streamable) {
        log('Track is not streamable: ${track.title}');
        throw Exception('Track is not streamable');
      }

      _downloadingStatus[trackId] = true;
      _downloadProgress[trackId] = 0.0;
      notifyListeners();

      // Find the best transcoding for download (prefer MP3/progressive over HLS)
      String? transcodingUrl = _findBestTranscodingForDownload(track);
      if (transcodingUrl == null) {
        // Log available transcodings for debugging
        log('No suitable transcoding found. Available transcodings:');
        for (int i = 0; i < track.media.transcodings.length; i++) {
          final t = track.media.transcodings[i];
          log('  ${i + 1}: protocol=${t.format.protocol}, mimeType=${t.format.mimeType}, url=${t.url}');
        }
        throw Exception('No suitable transcoding found for download');
      }

      log('Selected transcoding URL for download: $transcodingUrl');

      // Get downloadable track URL
      final downloadResponse = await musicProvider.musicService.getDownloadableTrack(transcodingUrl);
      if (downloadResponse.statusCode != 200) {
        log('Server returned status ${downloadResponse.statusCode}: ${downloadResponse.data}');
        throw Exception('Server error (${downloadResponse.statusCode}): ${downloadResponse.data}');
      }
      
      if (downloadResponse.data == null) {
        throw Exception('Server returned null response data');
      }

      String downloadUrl;
      if (downloadResponse.data is String) {
        downloadUrl = downloadResponse.data;
      } else if (downloadResponse.data is Map && downloadResponse.data['url'] != null) {
        downloadUrl = downloadResponse.data['url'];
      } else {
        throw Exception('Invalid response format for download URL');
      }

      // Get downloads directory
      final downloadsDir = await _getDownloadsDirectory();
      
      // Create safe filename
      final safeTitle = _createSafeFilename(track.title);
      final fileName = '${trackId}_$safeTitle.mp3';
      final filePath = '${downloadsDir.path}/$fileName';

      // Download the file
      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _downloadProgress[trackId] = progress;
            notifyListeners();
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      // Get file size
      final file = File(filePath);
      final fileSize = await file.length();

      // Create downloaded song object
      final downloadedSong = DownloadedSong(
        id: trackId,
        title: track.title,
        artist: track.user.username,
        artworkUrl: track.artworkUrl,
        localFilePath: filePath,
        downloadedAt: DateTime.now(),
        duration: track.duration,
        originalUrl: track.permalinkUrl,
        fileSize: fileSize,
      );

      // Add to downloaded songs list
      _downloadedSongs.insert(0, downloadedSong);
      await _saveDownloadedSongs();

      // Clean up progress tracking
      _downloadProgress.remove(trackId);
      _downloadingStatus.remove(trackId);
      
      notifyListeners();
      return true;

    } catch (e) {
      log('Error downloading track: $e');
      
      // Clean up on error
      final trackId = track.id.toString();
      _downloadProgress.remove(trackId);
      _downloadingStatus.remove(trackId);
      
      notifyListeners();
      return false;
    }
  }

  // Create safe filename from title
  String _createSafeFilename(String title) {
    return title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(' ', '_')
        .toLowerCase();
  }

  // Find the best transcoding for download (prefer progressive/MP3 over HLS)
  String? _findBestTranscodingForDownload(Track track) {
    final transcodings = track.media.transcodings;
    
    if (transcodings.isEmpty) {
      return null;
    }

    // Priority order for download formats:
    // 1. Progressive MP3 
    // 2. Any progressive format with audio mime type
    // 3. Non-HLS format
    // 4. Any available format as fallback

    String? progressiveMp3;
    String? progressiveAudio;
    String? nonHls;
    String? fallback;

    for (final transcoding in transcodings) {
      final protocol = transcoding.format.protocol.toLowerCase();
      final mimeType = transcoding.format.mimeType.toLowerCase();
      
      // Check for progressive MP3 (best option)
      if (protocol == 'progressive' && mimeType.contains('mp3')) {
        progressiveMp3 = transcoding.url;
        break; // This is the best option, use it immediately
      }
      
      // Check for progressive audio format
      if (protocol == 'progressive' && (mimeType.contains('audio') || mimeType.contains('mpeg'))) {
        progressiveAudio ??= transcoding.url;
      }
      
      // Check for non-HLS format
      if (!protocol.contains('hls') && !mimeType.contains('mpegurl')) {
        nonHls ??= transcoding.url;
      }
      
      // Keep first as fallback
      fallback ??= transcoding.url;
    }

    // Return in priority order
    return progressiveMp3 ?? progressiveAudio ?? nonHls ?? fallback;
  }

  // Check if a track is downloaded
  bool isTrackDownloaded(String trackId) {
    return _downloadedSongs.any((song) => song.id == trackId);
  }

  // Check if a track is currently downloading
  bool isTrackDownloading(String trackId) {
    return _downloadingStatus[trackId] == true;
  }

  // Get download progress for a track
  double getDownloadProgress(String trackId) {
    return _downloadProgress[trackId] ?? 0.0;
  }

  // Delete a downloaded song
  Future<bool> deleteDownloadedSong(String songId) async {
    try {
      final songIndex = _downloadedSongs.indexWhere((song) => song.id == songId);
      if (songIndex == -1) return false;

      final song = _downloadedSongs[songIndex];
      
      // Delete the file
      final file = File(song.localFilePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from list
      _downloadedSongs.removeAt(songIndex);
      await _saveDownloadedSongs();
      
      notifyListeners();
      return true;

    } catch (e) {
      log('Error deleting downloaded song: $e');
      return false;
    }
  }

  // Get downloaded song by ID
  DownloadedSong? getDownloadedSong(String songId) {
    try {
      return _downloadedSongs.firstWhere((song) => song.id == songId);
    } catch (e) {
      return null;
    }
  }

  // Get total downloaded songs count
  int get downloadedSongsCount => _downloadedSongs.length;

  // Get total downloaded size
  int get totalDownloadedSize {
    return _downloadedSongs.fold(0, (sum, song) => sum + song.fileSize);
  }

  // Clear all downloads
  Future<void> clearAllDownloads() async {
    try {
      // Delete all files
      for (final song in _downloadedSongs) {
        final file = File(song.localFilePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Clear the list
      _downloadedSongs.clear();
      await _saveDownloadedSongs();
      
      notifyListeners();

    } catch (e) {
      log('Error clearing all downloads: $e');
    }
  }
}