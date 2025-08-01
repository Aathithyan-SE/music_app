class DownloadedSong {
  final String id;
  final String title;
  final String artist;
  final String? artworkUrl;
  final String localFilePath;
  final DateTime downloadedAt;
  final int duration;
  final String originalUrl;
  final int fileSize;

  DownloadedSong({
    required this.id,
    required this.title,
    required this.artist,
    this.artworkUrl,
    required this.localFilePath,
    required this.downloadedAt,
    required this.duration,
    required this.originalUrl,
    required this.fileSize,
  });

  DownloadedSong copyWith({
    String? id,
    String? title,
    String? artist,
    String? artworkUrl,
    String? localFilePath,
    DateTime? downloadedAt,
    int? duration,
    String? originalUrl,
    int? fileSize,
  }) {
    return DownloadedSong(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      duration: duration ?? this.duration,
      originalUrl: originalUrl ?? this.originalUrl,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'artworkUrl': artworkUrl,
    'localFilePath': localFilePath,
    'downloadedAt': downloadedAt.millisecondsSinceEpoch,
    'duration': duration,
    'originalUrl': originalUrl,
    'fileSize': fileSize,
  };

  factory DownloadedSong.fromJson(Map<String, dynamic> json) => DownloadedSong(
    id: json['id'],
    title: json['title'],
    artist: json['artist'],
    artworkUrl: json['artworkUrl'],
    localFilePath: json['localFilePath'],
    downloadedAt: DateTime.fromMillisecondsSinceEpoch(json['downloadedAt']),
    duration: json['duration'],
    originalUrl: json['originalUrl'],
    fileSize: json['fileSize'],
  );

  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get formattedDuration {
    final minutes = (duration / 60000).floor();
    final seconds = ((duration % 60000) / 1000).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}