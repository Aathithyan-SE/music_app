// Alternative: services/fallback_local_music_service.dart
// Use this if on_audio_query continues to have issues

import 'dart:developer';
import 'dart:typed_data';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../models/local_music_model.dart';

class FallbackLocalMusicService {
  List<LocalMusicModel> _allSongs = [];
  List<LocalMusicModel> _filteredSongs = [];
  bool _isInitialized = false;

  // Common music directories
  final List<String> _musicDirectories = [
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Downloads',
    '/sdcard/Music',
    '/sdcard/Download',
    '/sdcard/Downloads',
  ];

  // Supported audio formats
  final List<String> _supportedFormats = [
    '.mp3', '.mp4', '.m4a', '.aac', '.wav', '.ogg', '.flac', '.wma'
  ];

  // Getters
  List<LocalMusicModel> get allSongs => _allSongs;
  List<LocalMusicModel> get filteredSongs => _filteredSongs;
  bool get isInitialized => _isInitialized;

  /// Request necessary permissions
  Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+)
        var audioStatus = await Permission.audio.status;
        if (audioStatus.isDenied) {
          audioStatus = await Permission.audio.request();
        }

        // For older Android versions
        var storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied) {
          storageStatus = await Permission.storage.request();
        }

        return audioStatus.isGranted || storageStatus.isGranted;
      } else if (Platform.isIOS) {
        // iOS doesn't need these permissions for local files
        return true;
      }

      return false;
    } catch (e) {
      log('Permission error: $e');
      return false;
    }
  }

  /// Load all songs by scanning directories
  Future<List<LocalMusicModel>> loadAllSongs() async {
    try {
      log('Loading songs using fallback method...');

      if (!await requestPermission()) {
        throw Exception('Storage permission denied');
      }

      _allSongs.clear();
      int songId = 0;

      for (String dirPath in _musicDirectories) {
        final directory = Directory(dirPath);
        if (await directory.exists()) {
          log('Scanning directory: $dirPath');
          await _scanDirectory(directory, songId);
        }
      }

      _filteredSongs = List.from(_allSongs);
      _isInitialized = true;

      log('Found ${_allSongs.length} songs using fallback method');
      return _allSongs;
    } catch (e) {
      log('Error in fallback loading: $e');
      rethrow;
    }
  }

  /// Recursively scan directory for music files
  Future<void> _scanDirectory(Directory directory, int startId) async {
    try {
      await for (FileSystemEntity entity in directory.list(recursive: true)) {
        if (entity is File) {
          final path = entity.path.toLowerCase();

          if (_supportedFormats.any((format) => path.endsWith(format))) {
            try {
              final file = File(entity.path);
              final stat = await file.stat();

              // Skip very small files (less than 100KB)
              if (stat.size < 100000) continue;

              final fileName = entity.path.split('/').last;
              final nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));

              // Try to parse title and artist from filename
              final parts = nameWithoutExt.split(' - ');
              final title = parts.length > 1 ? parts[1].trim() : nameWithoutExt;
              final artist = parts.length > 1 ? parts[0].trim() : 'Unknown Artist';

              final song = LocalMusicModel(
                id: startId++,
                title: title,
                artist: artist,
                album: _extractAlbumFromPath(entity.path),
                filePath: entity.path,
                duration: 0, // We can't easily get duration without media metadata
                genre: null,
              );

              _allSongs.add(song);
            } catch (e) {
              log('Error processing file ${entity.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      log('Error scanning directory ${directory.path}: $e');
    }
  }

  /// Extract album name from file path
  String? _extractAlbumFromPath(String path) {
    final parts = path.split('/');
    if (parts.length >= 2) {
      // Look for album folder name
      for (int i = parts.length - 2; i >= 0; i--) {
        final part = parts[i];
        if (part != 'Music' && part != 'Download' && part != 'Downloads' &&
            part != '0' && part != 'emulated' && part != 'storage' &&
            part != 'sdcard' && part.isNotEmpty) {
          return part;
        }
      }
    }
    return null;
  }

  /// Search songs by query
  void searchSongs(String query) {
    if (query.isEmpty) {
      _filteredSongs = List.from(_allSongs);
      return;
    }

    final lowerQuery = query.toLowerCase();
    _filteredSongs = _allSongs.where((song) {
      return song.title.toLowerCase().contains(lowerQuery) ||
          song.artist.toLowerCase().contains(lowerQuery) ||
          (song.album?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Get artwork (placeholder - returns null since we can't extract without media libs)
  Future<Uint8List?> getSongArtwork(int songId) async {
    // Without media libraries, we can't extract artwork
    // You could implement a simple cache system here
    return null;
  }

  /// Sort songs
  void sortSongs(SortCriteria criteria, {bool ascending = true}) {
    switch (criteria) {
      case SortCriteria.title:
        _filteredSongs.sort((a, b) => ascending
            ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
            : b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SortCriteria.dateAdded:
      // Sort by filename for now
        _filteredSongs.sort((a, b) => ascending
            ? a.filePath.compareTo(b.filePath)
            : b.filePath.compareTo(a.filePath));
        break;
    }
  }

  /// Get all unique artists
  List<String> getAllArtists() {
    return _allSongs.map((song) => song.artist).toSet().toList()..sort();
  }

  /// Get all unique albums
  List<String> getAllAlbums() {
    return _allSongs
        .where((song) => song.album != null && song.album!.isNotEmpty)
        .map((song) => song.album!)
        .toSet()
        .toList()..sort();
  }

  /// Clear cache
  void clearCache() {
    _allSongs.clear();
    _filteredSongs.clear();
    _isInitialized = false;
  }
}

enum SortCriteria {
  title,
  dateAdded,
}