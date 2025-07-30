import 'package:modizk_download/models/song.dart';

class Playlist {
  final String id;
  final String name;
  final String? imageUrl;
  final List<String> songIds;
  final DateTime createdDate;
  final DateTime lastModified;
  final bool isSystemPlaylist;

  Playlist({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.songIds,
    required this.createdDate,
    required this.lastModified,
    this.isSystemPlaylist = false,
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? imageUrl,
    List<String>? songIds,
    DateTime? createdDate,
    DateTime? lastModified,
    bool? isSystemPlaylist,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      songIds: songIds ?? List.from(this.songIds),
      createdDate: createdDate ?? this.createdDate,
      lastModified: lastModified ?? this.lastModified,
      isSystemPlaylist: isSystemPlaylist ?? this.isSystemPlaylist,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
    'songIds': songIds,
    'createdDate': createdDate.millisecondsSinceEpoch,
    'lastModified': lastModified.millisecondsSinceEpoch,
    'isSystemPlaylist': isSystemPlaylist,
  };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
    id: json['id'],
    name: json['name'],
    imageUrl: json['imageUrl'],
    songIds: List<String>.from(json['songIds'] ?? []),
    createdDate: DateTime.fromMillisecondsSinceEpoch(json['createdDate']),
    lastModified: DateTime.fromMillisecondsSinceEpoch(json['lastModified']),
    isSystemPlaylist: json['isSystemPlaylist'] ?? false,
  );

  int get songCount => songIds.length;
}