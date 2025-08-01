import 'package:on_audio_query/on_audio_query.dart';

class LocalMusicModel {
  final int id;
  final String title;
  final String artist;
  final String? album;
  final String? artworkPath;
  final String filePath;
  final int duration;
  final String? genre;

  LocalMusicModel({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.artworkPath,
    required this.filePath,
    required this.duration,
    this.genre,
  });

  factory LocalMusicModel.fromSongModel(SongModel song) {
    return LocalMusicModel(
      id: song.id,
      title: song.title,
      artist: song.artist ?? "Unknown Artist",
      album: song.album,
      artworkPath: song.data,
      filePath: song.data,
      duration: song.duration ?? 0,
      genre: song.genre,
    );
  }

  Duration get durationAsTime => Duration(milliseconds: duration);
}
