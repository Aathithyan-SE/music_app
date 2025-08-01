import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:modizk_download/models/playlist.dart';
import 'package:modizk_download/models/sound_cloud_search_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PlaylistService extends ChangeNotifier {
  static final PlaylistService _instance = PlaylistService._internal();
  factory PlaylistService() => _instance;
  PlaylistService._internal();

  SharedPreferences? _prefs;
  final Uuid _uuid = const Uuid();

  // Keys for SharedPreferences
  static const String _playlistsKey = 'playlists';
  static const String _recentSongsKey = 'recent_songs';
  static const String _likedSongsKey = 'liked_songs';

  // Local state
  List<Playlist> _playlists = [];
  List<Track> _recentSongs = [];
  List<Track> _likedSongs = [];

  // Getters
  List<Playlist> get playlists => _playlists;
  List<Track> get recentSongs => _recentSongs;
  List<Track> get likedSongs => _likedSongs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadData();
  }

  // Private method to load all data from SharedPreferences
  Future<void> _loadData() async {
    try {
      await _loadPlaylists();
      await _loadRecentSongs();
      await _loadLikedSongs();
    } catch (e) {
      log('Error loading playlist data: $e');
    }
  }

  // Load playlists from SharedPreferences
  Future<void> _loadPlaylists() async {
    final String? playlistsJson = _prefs?.getString(_playlistsKey);
    if (playlistsJson != null) {
      try {
        final List<dynamic> playlistsList = json.decode(playlistsJson);
        _playlists = playlistsList.map((item) => Playlist.fromJson(item)).toList();
      } catch (e) {
        log('Error loading playlists: $e');
        _playlists = [];
      }
    }
  }

  // Load recent songs from SharedPreferences
  Future<void> _loadRecentSongs() async {
    final String? recentJson = _prefs?.getString(_recentSongsKey);
    if (recentJson != null) {
      try {
        final List<dynamic> recentList = json.decode(recentJson);
        _recentSongs = recentList.map((item) => _trackFromJson(item)).toList();
      } catch (e) {
        log('Error loading recent songs: $e');
        _recentSongs = [];
      }
    }
  }

  // Load liked songs from SharedPreferences
  Future<void> _loadLikedSongs() async {
    final String? likedJson = _prefs?.getString(_likedSongsKey);
    if (likedJson != null) {
      try {
        final List<dynamic> likedList = json.decode(likedJson);
        _likedSongs = likedList.map((item) => _trackFromJson(item)).toList();
      } catch (e) {
        log('Error loading liked songs: $e');
        _likedSongs = [];
      }
    }
  }

  // Save playlists to SharedPreferences
  Future<void> _savePlaylists() async {
    try {
      final String playlistsJson = json.encode(_playlists.map((p) => p.toJson()).toList());
      await _prefs?.setString(_playlistsKey, playlistsJson);
    } catch (e) {
      log('Error saving playlists: $e');
    }
  }

  // Save recent songs to SharedPreferences
  Future<void> _saveRecentSongs() async {
    try {
      final String recentJson = json.encode(_recentSongs.map((t) => _trackToJson(t)).toList());
      await _prefs?.setString(_recentSongsKey, recentJson);
    } catch (e) {
      log('Error saving recent songs: $e');
    }
  }

  // Save liked songs to SharedPreferences
  Future<void> _saveLikedSongs() async {
    try {
      final String likedJson = json.encode(_likedSongs.map((t) => _trackToJson(t)).toList());
      await _prefs?.setString(_likedSongsKey, likedJson);
    } catch (e) {
      log('Error saving liked songs: $e');
    }
  }

  // Playlist management methods
  Future<Playlist> createPlaylist({
    required String name,
    String? description,
    String? coverImageUrl,
  }) async {
    final playlist = Playlist(
      id: _uuid.v4(),
      name: name,
      description: description,
      createdAt: DateTime.now(),
      tracks: [],
      coverImageUrl: coverImageUrl,
    );

    _playlists.add(playlist);
    await _savePlaylists();
    notifyListeners();
    return playlist;
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((playlist) => playlist.id == playlistId);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final index = _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index != -1) {
      _playlists[index] = _playlists[index].copyWith(name: newName);
      await _savePlaylists();
      notifyListeners();
    }
  }

  Future<void> addTrackToPlaylist(String playlistId, Track track) async {
    final index = _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index != -1) {
      final playlist = _playlists[index];
      
      // Check if track is already in playlist
      if (!playlist.tracks.any((t) => t.id == track.id)) {
        final updatedTracks = List<Track>.from(playlist.tracks)..add(track);
        _playlists[index] = playlist.copyWith(tracks: updatedTracks);
        await _savePlaylists();
        notifyListeners();
      }
    }
  }

  Future<void> removeTrackFromPlaylist(String playlistId, int trackId) async {
    final index = _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index != -1) {
      final playlist = _playlists[index];
      final updatedTracks = playlist.tracks.where((track) => track.id != trackId).toList();
      _playlists[index] = playlist.copyWith(tracks: updatedTracks);
      await _savePlaylists();
      notifyListeners();
    }
  }

  // Recent songs management
  Future<void> addToRecentSongs(Track track) async {
    // Remove if already exists to avoid duplicates
    _recentSongs.removeWhere((t) => t.id == track.id);
    
    // Add to beginning of list
    _recentSongs.insert(0, track);
    
    // Keep only last 10 songs
    if (_recentSongs.length > 10) {
      _recentSongs = _recentSongs.sublist(0, 10);
    }
    
    await _saveRecentSongs();
    notifyListeners();
  }

  Future<void> clearRecentSongs() async {
    _recentSongs.clear();
    await _saveRecentSongs();
    notifyListeners();
  }

  // Liked songs management
  Future<void> toggleLikeSong(Track track) async {
    final index = _likedSongs.indexWhere((t) => t.id == track.id);
    
    if (index != -1) {
      // Song is already liked, remove it
      _likedSongs.removeAt(index);
    } else {
      // Song is not liked, add it
      _likedSongs.insert(0, track);
    }
    
    await _saveLikedSongs();
    notifyListeners();
  }

  bool isTrackLiked(Track track) {
    return _likedSongs.any((t) => t.id == track.id);
  }

  Future<void> clearLikedSongs() async {
    _likedSongs.clear();
    await _saveLikedSongs();
    notifyListeners();
  }

  // Utility methods
  Playlist? getPlaylistById(String id) {
    try {
      return _playlists.firstWhere((playlist) => playlist.id == id);
    } catch (e) {
      return null;
    }
  }

  bool isTrackInPlaylist(String playlistId, Track track) {
    final playlist = getPlaylistById(playlistId);
    return playlist?.tracks.any((t) => t.id == track.id) ?? false;
  }

  List<Playlist> getPlaylistsContaining(Track track) {
    return _playlists.where((playlist) => 
        playlist.tracks.any((t) => t.id == track.id)).toList();
  }

  // Helper methods for Track serialization (copied from Playlist model)
  static Map<String, dynamic> _trackToJson(Track track) => {
    'id': track.id,
    'title': track.title,
    'artworkUrl': track.artworkUrl,
    'duration': track.duration,
    'fullDuration': track.fullDuration,
    'permalinkUrl': track.permalinkUrl,
    'user': {
      'id': track.user.id,
      'username': track.user.username,
      'avatarUrl': track.user.avatarUrl,
      'permalink': track.user.permalink,
      'permalinkUrl': track.user.permalinkUrl,
    },
    'genre': track.genre,
    'tagList': track.tagList,
    'createdAt': track.createdAt,
    'description': track.description,
    'playbackCount': track.playbackCount,
    'likesCount': track.likesCount,
    'commentCount': track.commentCount,
    'downloadCount': track.downloadCount,
    'repostsCount': track.repostsCount,
    'public': track.public,
    'streamable': track.streamable,
    'downloadable': track.downloadable,
    'commentable': track.commentable,
    'hasDownloadsLeft': track.hasDownloadsLeft,
    'kind': track.kind,
    'labelName': track.labelName,
    'lastModified': track.lastModified,
    'license': track.license,
    'permalink': track.permalink,
    'purchaseTitle': track.purchaseTitle,
    'purchaseUrl': track.purchaseUrl,
    'releaseDate': track.releaseDate,
    'secretToken': track.secretToken,
    'sharing': track.sharing,
    'state': track.state,
    'uri': track.uri,
    'urn': track.urn,
    'userId': track.userId,
    'visuals': track.visuals,
    'waveformUrl': track.waveformUrl,
    'displayDate': track.displayDate,
    'stationUrn': track.stationUrn,
    'stationPermalink': track.stationPermalink,
    'trackAuthorization': track.trackAuthorization,
    'monetizationModel': track.monetizationModel,
    'policy': track.policy,
    'embeddableBy': track.embeddableBy,
    'caption': track.caption,
    'publisherMetadata': track.publisherMetadata?.toJson(),
    'media': track.media.toJson(),
  };

  static Track _trackFromJson(Map<String, dynamic> json) => Track(
    id: json['id'],
    title: json['title'],
    artworkUrl: json['artworkUrl'],
    duration: json['duration'],
    fullDuration: json['fullDuration'],
    permalinkUrl: json['permalinkUrl'],
    user: User.fromJson(json['user']),
    genre: json['genre'],
    tagList: json['tagList'],
    createdAt: json['createdAt'],
    description: json['description'],
    playbackCount: json['playbackCount'],
    likesCount: json['likesCount'],
    commentCount: json['commentCount'],
    downloadCount: json['downloadCount'],
    repostsCount: json['repostsCount'],
    public: json['public'],
    streamable: json['streamable'],
    downloadable: json['downloadable'],
    commentable: json['commentable'],
    hasDownloadsLeft: json['hasDownloadsLeft'],
    kind: json['kind'],
    labelName: json['labelName'],
    lastModified: json['lastModified'],
    license: json['license'],
    permalink: json['permalink'],
    purchaseTitle: json['purchaseTitle'],
    purchaseUrl: json['purchaseUrl'],
    releaseDate: json['releaseDate'],
    secretToken: json['secretToken'],
    sharing: json['sharing'],
    state: json['state'],
    uri: json['uri'],
    urn: json['urn'],
    userId: json['userId'],
    visuals: json['visuals'],
    waveformUrl: json['waveformUrl'],
    displayDate: json['displayDate'],
    stationUrn: json['stationUrn'],
    stationPermalink: json['stationPermalink'],
    trackAuthorization: json['trackAuthorization'],
    monetizationModel: json['monetizationModel'],
    policy: json['policy'],
    embeddableBy: json['embeddableBy'],
    caption: json['caption'],
    publisherMetadata: json['publisherMetadata'] != null 
        ? PublisherMetadata.fromJson(json['publisherMetadata']) 
        : null,
    media: Media.fromJson(json['media']),
  );
}