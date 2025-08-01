import 'dart:developer';
import 'dart:typed_data';
import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/local_music_model.dart';

class LocalMusicService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<LocalMusicModel> _allSongs = [];
  List<LocalMusicModel> _filteredSongs = [];
  bool _isInitialized = false;

  List<LocalMusicModel> get allSongs => _allSongs;
  List<LocalMusicModel> get filteredSongs => _filteredSongs;
  bool get isInitialized => _isInitialized;

  Future<bool> requestPermission() async {
    try {
      log('Requesting audio permissions...');
      if (Platform.isAndroid) {
        var storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied) {
          storageStatus = await Permission.storage.request();
        }

        var audioStatus = await Permission.audio.status;
        if (audioStatus.isDenied) {
          audioStatus = await Permission.audio.request();
        }

        if (!storageStatus.isGranted && !audioStatus.isGranted) {
          log('Both storage and audio permissions denied');
          return false;
        }
      }

      bool hasPermission = false;
      try {
        hasPermission = await _audioQuery.permissionsStatus();

        if (!hasPermission) {
          hasPermission = await _audioQuery.permissionsRequest();
        }
      } catch (e) {
        log('on_audio_query permission error: $e');
        if (Platform.isAndroid) {
          final audioStatus = await Permission.audio.status;
          final storageStatus = await Permission.storage.status;
          hasPermission = audioStatus.isGranted || storageStatus.isGranted;
        } else {
          return false;
        }
      }

      log('Final permission status: $hasPermission');
      return hasPermission;
    } catch (e) {
      log('Error requesting permissions: $e');
      return false;
    }
  }

  Future<List<LocalMusicModel>> loadAllSongs() async {
    try {
      log('Starting to load songs from device...');
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        throw Exception('Permission denied. Please grant audio access in device settings.');
      }

      List<SongModel> songs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      log('Found ${songs.length} songs on device');

      _allSongs = songs
          .where((song) => _isValidSong(song))
          .map((song) => LocalMusicModel.fromSongModel(song))
          .toList();

      _filteredSongs = List.from(_allSongs);
      _isInitialized = true;

      log('Successfully loaded ${_allSongs.length} valid songs');
      return _allSongs;
    } catch (e) {
      log('Error loading songs: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  bool _isValidSong(SongModel song) {
    if (song.data.isEmpty) return false;

    final file = File(song.data);
    if (!file.existsSync()) return false;

    final extension = song.data.toLowerCase().split('.').last;
    const supportedFormats = [
      'mp3', 'mp4', 'm4a', 'aac', 'wav', 'ogg', 'flac', 'wma'
    ];

    if (!supportedFormats.contains(extension)) return false;

    if (song.duration != null && song.duration! < 10000) return false; // Less than 10 seconds

    return true;
  }

  void searchSongs(String query) {
    if (query.isEmpty) {
      _filteredSongs = List.from(_allSongs);
      return;
    }

    final lowerQuery = query.toLowerCase();
    _filteredSongs = _allSongs.where((song) {
      return song.title.toLowerCase().contains(lowerQuery) ||
          song.artist.toLowerCase().contains(lowerQuery) ||
          (song.album?.toLowerCase().contains(lowerQuery) ?? false) ||
          (song.genre?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    log('Search for "$query" returned ${_filteredSongs.length} results');
  }

  Future<Uint8List?> getSongArtwork(int songId) async {
    try {
      final artwork = await _audioQuery.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 300,
        quality: 100,
      );

      if (artwork != null && artwork.isNotEmpty) {
        log('Successfully retrieved artwork for song ID: $songId');
        return artwork;
      }

      log('No artwork found for song ID: $songId');
      return null;
    } catch (e) {
      log('Error getting artwork for song ID $songId: $e');
      return null;
    }
  }

  List<LocalMusicModel> getSongsByArtist(String artistName) {
    return _allSongs.where((song) => song.artist == artistName).toList();
  }

  List<LocalMusicModel> getSongsByAlbum(String albumName) {
    return _allSongs.where((song) => song.album == albumName).toList();
  }

  List<String> getAllArtists() {
    final artists = _allSongs.map((song) => song.artist).toSet().toList();
    artists.sort();
    return artists;
  }

  List<String> getAllAlbums() {
    final albums = _allSongs
        .where((song) => song.album != null && song.album!.isNotEmpty)
        .map((song) => song.album!)
        .toSet()
        .toList();
    albums.sort();
    return albums;
  }

  List<String> getAllGenres() {
    final genres = _allSongs
        .where((song) => song.genre != null && song.genre!.isNotEmpty)
        .map((song) => song.genre!)
        .toSet()
        .toList();
    genres.sort();
    return genres;
  }

  List<String> getAlbumsByArtist(String artistName) {
    final albums = _allSongs
        .where((song) => song.artist == artistName &&
        song.album != null &&
        song.album!.isNotEmpty)
        .map((song) => song.album!)
        .toSet()
        .toList();
    albums.sort();
    return albums;
  }

  Duration getTotalDuration() {
    final totalMilliseconds = _allSongs.fold<int>(
      0,
          (sum, song) => sum + song.duration,
    );
    return Duration(milliseconds: totalMilliseconds);
  }

  Future<int> getTotalStorageSize() async {
    int totalSize = 0;

    for (final song in _allSongs) {
      try {
        final file = File(song.filePath);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      } catch (e) {
        log('Error getting file size for ${song.filePath}: $e');
      }
    }

    return totalSize;
  }

  Future<int> getSongFileSize(LocalMusicModel song) async {
    try {
      final file = File(song.filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      log('Error getting file size for ${song.filePath}: $e');
    }
    return 0;
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<List<LocalMusicModel>> refreshLibrary() async {
    log('Refreshing music library...');
    _allSongs.clear();
    _filteredSongs.clear();
    _isInitialized = false;

    return await loadAllSongs();
  }

  Future<bool> hasAnyMusic() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return false;

      final songs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      return songs.isNotEmpty;
    } catch (e) {
      log('Error checking for music: $e');
      return false;
    }
  }

  List<LocalMusicModel> getRecentlyAdded({int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    return _allSongs.where((song) {
      try {
        final file = File(song.filePath);
        final stat = file.statSync();
        return stat.modified.isAfter(cutoffDate);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  void sortSongs(SortCriteria criteria, {bool ascending = true}) {
    switch (criteria) {
      case SortCriteria.title:
        _filteredSongs.sort((a, b) => ascending
            ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
            : b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;

      case SortCriteria.artist:
        _filteredSongs.sort((a, b) => ascending
            ? a.artist.toLowerCase().compareTo(b.artist.toLowerCase())
            : b.artist.toLowerCase().compareTo(a.artist.toLowerCase()));
        break;

      case SortCriteria.album:
        _filteredSongs.sort((a, b) {
          final albumA = (a.album ?? '').toLowerCase();
          final albumB = (b.album ?? '').toLowerCase();
          return ascending ? albumA.compareTo(albumB) : albumB.compareTo(albumA);
        });
        break;

      case SortCriteria.duration:
        _filteredSongs.sort((a, b) => ascending
            ? a.duration.compareTo(b.duration)
            : b.duration.compareTo(a.duration));
        break;

      case SortCriteria.dateAdded:
        _filteredSongs.sort((a, b) {
          try {
            final fileA = File(a.filePath);
            final fileB = File(b.filePath);
            final statA = fileA.statSync();
            final statB = fileB.statSync();
            return ascending
                ? statA.modified.compareTo(statB.modified)
                : statB.modified.compareTo(statA.modified);
          } catch (e) {
            return 0;
          }
        });
        break;
    }
  }

  void clearCache() {
    _allSongs.clear();
    _filteredSongs.clear();
    _isInitialized = false;
    log('Music service cache cleared');
  }

  Map<String, dynamic> getMusicStats() {
    final totalDuration = getTotalDuration();
    final artists = getAllArtists();
    final albums = getAllAlbums();
    final genres = getAllGenres();

    return {
      'totalSongs': _allSongs.length,
      'totalArtists': artists.length,
      'totalAlbums': albums.length,
      'totalGenres': genres.length,
      'totalDuration': totalDuration,
      'averageSongDuration': _allSongs.isNotEmpty
          ? Duration(milliseconds: totalDuration.inMilliseconds ~/ _allSongs.length)
          : Duration.zero,
    };
  }
}

enum SortCriteria {
  title,
  artist,
  album,
  duration,
  dateAdded,
}