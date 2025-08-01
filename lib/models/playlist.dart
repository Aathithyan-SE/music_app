import 'package:modizk_download/models/sound_cloud_search_response.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final List<Track> tracks;
  final String? coverImageUrl;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.tracks = const [],
    this.coverImageUrl,
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    List<Track>? tracks,
    String? coverImageUrl,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      tracks: tracks ?? this.tracks,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'tracks': tracks.map((track) => _trackToJson(track)).toList(),
    'coverImageUrl': coverImageUrl,
  };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    tracks: (json['tracks'] as List?)?.map((track) => _trackFromJson(track)).toList() ?? [],
    coverImageUrl: json['coverImageUrl'],
  );

  // Helper methods to convert Track objects to/from JSON
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