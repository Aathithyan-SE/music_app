class Song {
  final String id;
  final String title;
  final String artist;
  final String? albumArt;
  final String? filePath;
  final Duration? duration;
  final bool isLiked;
  final bool isDownloaded;
  final DateTime? addedDate;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.albumArt,
    this.filePath,
    this.duration,
    this.isLiked = false,
    this.isDownloaded = false,
    this.addedDate,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumArt,
    String? filePath,
    Duration? duration,
    bool? isLiked,
    bool? isDownloaded,
    DateTime? addedDate,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArt: albumArt ?? this.albumArt,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      isLiked: isLiked ?? this.isLiked,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'albumArt': albumArt,
    'filePath': filePath,
    'duration': duration?.inMilliseconds,
    'isLiked': isLiked,
    'isDownloaded': isDownloaded,
    'addedDate': addedDate?.millisecondsSinceEpoch,
  };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
    id: json['id'],
    title: json['title'],
    artist: json['artist'],
    albumArt: json['albumArt'],
    filePath: json['filePath'],
    duration: json['duration'] != null 
      ? Duration(milliseconds: json['duration'])
      : null,
    isLiked: json['isLiked'] ?? false,
    isDownloaded: json['isDownloaded'] ?? false,
    addedDate: json['addedDate'] != null 
      ? DateTime.fromMillisecondsSinceEpoch(json['addedDate'])
      : null,
  );

  // Sample data for development
  static List<Song> sampleSongs = [
    Song(
      id: '1',
      title: 'Sunset Dreams',
      artist: 'Aurora Waves',
      albumArt: 'assets/images/album1.jpg',
      duration: const Duration(minutes: 3, seconds: 45),
      addedDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Song(
      id: '2',
      title: 'Midnight Jazz',
      artist: 'Blue Moon Collective',
      albumArt: 'assets/images/album2.jpg',
      duration: const Duration(minutes: 4, seconds: 20),
      addedDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Song(
      id: '3',
      title: 'Digital Harmony',
      artist: 'Neon Pulse',
      albumArt: 'assets/images/album3.jpg',
      duration: const Duration(minutes: 3, seconds: 15),
      addedDate: DateTime.now(),
    ),
    Song(
      id: '4',
      title: 'Ocean Breeze',
      artist: 'Coastal Sounds',
      albumArt: 'assets/images/album4.jpg',
      duration: const Duration(minutes: 5, seconds: 10),
      addedDate: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Song(
      id: '5',
      title: 'Electric Nights',
      artist: 'Voltage Dreams',
      albumArt: 'assets/images/album5.jpg',
      duration: const Duration(minutes: 3, seconds: 55),
      addedDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];
}