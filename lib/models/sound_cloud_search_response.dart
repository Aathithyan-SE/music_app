// Main response model
class SoundCloudSearchResponse {
  final List<Track> collection;
  final int totalResults;
  String? nextHref;
  final String queryUrn;

  SoundCloudSearchResponse({
    required this.collection,
    required this.totalResults,
    this.nextHref,
    required this.queryUrn,
  });

  factory SoundCloudSearchResponse.fromJson(Map<String, dynamic> json) {
    return SoundCloudSearchResponse(
      collection: (json['collection'] as List? ?? [])
          .map((item) => Track.fromJson(item))
    .where((track) => track.policy.toLowerCase() == 'allow')
          .toList(),
      totalResults: json['total_results'] ?? 0,
      nextHref: json['next_href'],
      queryUrn: json['query_urn'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collection': collection.map((track) => track.toJson()).toList(),
      'total_results': totalResults,
      'next_href': nextHref,
      'query_urn': queryUrn,
    };
  }
}

// Track model
class Track {
  final String? artworkUrl;
  final String? caption;
  final bool commentable;
  final int commentCount;
  final String createdAt;
  final String? description;
  final bool downloadable;
  final int downloadCount;
  final int duration;
  final int fullDuration;
  final String embeddableBy;
  final String? genre;
  final bool hasDownloadsLeft;
  final int id;
  final String kind;
  final String? labelName;
  final String lastModified;
  final String license;
  final int likesCount;
  final String permalink;
  final String permalinkUrl;
  final int playbackCount;
  final bool public;
  final PublisherMetadata? publisherMetadata;
  final String? purchaseTitle;
  final String? purchaseUrl;
  final String? releaseDate;
  final int repostsCount;
  final String? secretToken;
  final String sharing;
  final String state;
  final bool streamable;
  final String tagList;
  final String title;
  final String uri;
  final String urn;
  final int userId;
  final dynamic visuals;
  final String waveformUrl;
  final String displayDate;
  final Media media;
  final String stationUrn;
  final String stationPermalink;
  final String trackAuthorization;
  final String monetizationModel;
  final String policy;
  final User user;

  Track({
    this.artworkUrl,
    this.caption,
    required this.commentable,
    required this.commentCount,
    required this.createdAt,
    this.description,
    required this.downloadable,
    required this.downloadCount,
    required this.duration,
    required this.fullDuration,
    required this.embeddableBy,
    this.genre,
    required this.hasDownloadsLeft,
    required this.id,
    required this.kind,
    this.labelName,
    required this.lastModified,
    required this.license,
    required this.likesCount,
    required this.permalink,
    required this.permalinkUrl,
    required this.playbackCount,
    required this.public,
    this.publisherMetadata,
    this.purchaseTitle,
    this.purchaseUrl,
    this.releaseDate,
    required this.repostsCount,
    this.secretToken,
    required this.sharing,
    required this.state,
    required this.streamable,
    required this.tagList,
    required this.title,
    required this.uri,
    required this.urn,
    required this.userId,
    this.visuals,
    required this.waveformUrl,
    required this.displayDate,
    required this.media,
    required this.stationUrn,
    required this.stationPermalink,
    required this.trackAuthorization,
    required this.monetizationModel,
    required this.policy,
    required this.user,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      artworkUrl: json['artwork_url'],
      caption: json['caption'],
      commentable: json['commentable'] ?? false,
      commentCount: json['comment_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
      description: json['description'],
      downloadable: json['downloadable'] ?? false,
      downloadCount: json['download_count'] ?? 0,
      duration: json['duration'] ?? 0,
      fullDuration: json['full_duration'] ?? 0,
      embeddableBy: json['embeddable_by'] ?? '',
      genre: json['genre'],
      hasDownloadsLeft: json['has_downloads_left'] ?? false,
      id: json['id'] ?? 0,
      kind: json['kind'] ?? '',
      labelName: json['label_name'],
      lastModified: json['last_modified'] ?? '',
      license: json['license'] ?? '',
      likesCount: json['likes_count'] ?? 0,
      permalink: json['permalink'] ?? '',
      permalinkUrl: json['permalink_url'] ?? '',
      playbackCount: json['playback_count'] ?? 0,
      public: json['public'] ?? false,
      publisherMetadata: json['publisher_metadata'] != null
          ? PublisherMetadata.fromJson(json['publisher_metadata'])
          : null,
      purchaseTitle: json['purchase_title'],
      purchaseUrl: json['purchase_url'],
      releaseDate: json['release_date'],
      repostsCount: json['reposts_count'] ?? 0,
      secretToken: json['secret_token'],
      sharing: json['sharing'] ?? '',
      state: json['state'] ?? '',
      streamable: json['streamable'] ?? false,
      tagList: json['tag_list'] ?? '',
      title: json['title'] ?? '',
      uri: json['uri'] ?? '',
      urn: json['urn'] ?? '',
      userId: json['user_id'] ?? 0,
      visuals: json['visuals'],
      waveformUrl: json['waveform_url'] ?? '',
      displayDate: json['display_date'] ?? '',
      media: json['media'] != null
          ? Media.fromJson(json['media'])
          : Media(transcodings: []),
      stationUrn: json['station_urn'] ?? '',
      stationPermalink: json['station_permalink'] ?? '',
      trackAuthorization: json['track_authorization'] ?? '',
      monetizationModel: json['monetization_model'] ?? '',
      policy: json['policy'] ?? '',
      user: json['user'] != null
          ? User.fromJson(json['user'])
          : User.empty(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'artwork_url': artworkUrl,
      'caption': caption,
      'commentable': commentable,
      'comment_count': commentCount,
      'created_at': createdAt,
      'description': description,
      'downloadable': downloadable,
      'download_count': downloadCount,
      'duration': duration,
      'full_duration': fullDuration,
      'embeddable_by': embeddableBy,
      'genre': genre,
      'has_downloads_left': hasDownloadsLeft,
      'id': id,
      'kind': kind,
      'label_name': labelName,
      'last_modified': lastModified,
      'license': license,
      'likes_count': likesCount,
      'permalink': permalink,
      'permalink_url': permalinkUrl,
      'playback_count': playbackCount,
      'public': public,
      'publisher_metadata': publisherMetadata?.toJson(),
      'purchase_title': purchaseTitle,
      'purchase_url': purchaseUrl,
      'release_date': releaseDate,
      'reposts_count': repostsCount,
      'secret_token': secretToken,
      'sharing': sharing,
      'state': state,
      'streamable': streamable,
      'tag_list': tagList,
      'title': title,
      'uri': uri,
      'urn': urn,
      'user_id': userId,
      'visuals': visuals,
      'waveform_url': waveformUrl,
      'display_date': displayDate,
      'media': media.toJson(),
      'station_urn': stationUrn,
      'station_permalink': stationPermalink,
      'track_authorization': trackAuthorization,
      'monetization_model': monetizationModel,
      'policy': policy,
      'user': user.toJson(),
    };
  }
}

// Publisher Metadata model
class PublisherMetadata {
  final int id;
  final String urn;
  final String? artist;
  final String? albumTitle;
  final bool? containsMusic;
  final String? upcOrEan;
  final String? isrc;
  final bool? explicit;
  final String? pLine;
  final String? pLineForDisplay;
  final String? cLine;
  final String? cLineForDisplay;
  final String? releaseTitle;
  final String? publisher;
  final String? iswc;
  final String? writerComposer;

  PublisherMetadata({
    required this.id,
    required this.urn,
    this.artist,
    this.albumTitle,
    this.containsMusic,
    this.upcOrEan,
    this.isrc,
    this.explicit,
    this.pLine,
    this.pLineForDisplay,
    this.cLine,
    this.cLineForDisplay,
    this.releaseTitle,
    this.publisher,
    this.iswc,
    this.writerComposer,
  });

  factory PublisherMetadata.fromJson(Map<String, dynamic> json) {
    return PublisherMetadata(
      id: json['id'] ?? 0,
      urn: json['urn'] ?? '',
      artist: json['artist'],
      albumTitle: json['album_title'],
      containsMusic: json['contains_music'],
      upcOrEan: json['upc_or_ean'],
      isrc: json['isrc'],
      explicit: json['explicit'],
      pLine: json['p_line'],
      pLineForDisplay: json['p_line_for_display'],
      cLine: json['c_line'],
      cLineForDisplay: json['c_line_for_display'],
      releaseTitle: json['release_title'],
      publisher: json['publisher'],
      iswc: json['iswc'],
      writerComposer: json['writer_composer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'urn': urn,
      'artist': artist,
      'album_title': albumTitle,
      'contains_music': containsMusic,
      'upc_or_ean': upcOrEan,
      'isrc': isrc,
      'explicit': explicit,
      'p_line': pLine,
      'p_line_for_display': pLineForDisplay,
      'c_line': cLine,
      'c_line_for_display': cLineForDisplay,
      'release_title': releaseTitle,
      'publisher': publisher,
      'iswc': iswc,
      'writer_composer': writerComposer,
    };
  }
}

// Media model
class Media {
  final List<Transcoding> transcodings;

  Media({required this.transcodings});

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      transcodings: (json['transcodings'] as List? ?? [])
          .map((item) => Transcoding.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transcodings': transcodings.map((t) => t.toJson()).toList(),
    };
  }
}

// Transcoding model
class Transcoding {
  final String url;
  final String preset;
  final int duration;
  final bool snipped;
  final Format format;
  final String quality;
  final bool isLegacyTranscoding;

  Transcoding({
    required this.url,
    required this.preset,
    required this.duration,
    required this.snipped,
    required this.format,
    required this.quality,
    required this.isLegacyTranscoding,
  });

  factory Transcoding.fromJson(Map<String, dynamic> json) {
    return Transcoding(
      url: json['url'] ?? '',
      preset: json['preset'] ?? '',
      duration: json['duration'] ?? 0,
      snipped: json['snipped'] ?? false,
      format: json['format'] != null
          ? Format.fromJson(json['format'])
          : Format(protocol: '', mimeType: ''),
      quality: json['quality'] ?? '',
      isLegacyTranscoding: json['is_legacy_transcoding'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'preset': preset,
      'duration': duration,
      'snipped': snipped,
      'format': format.toJson(),
      'quality': quality,
      'is_legacy_transcoding': isLegacyTranscoding,
    };
  }
}

// Format model
class Format {
  final String protocol;
  final String mimeType;

  Format({
    required this.protocol,
    required this.mimeType,
  });

  factory Format.fromJson(Map<String, dynamic> json) {
    return Format(
      protocol: json['protocol'] ?? '',
      mimeType: json['mime_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'protocol': protocol,
      'mime_type': mimeType,
    };
  }
}

// User model
class User {
  final String avatarUrl;
  final String? city;
  final int commentsCount;
  final String? countryCode;
  final String createdAt;
  final List<CreatorSubscription> creatorSubscriptions;
  final CreatorSubscription creatorSubscription;
  final String? description;
  final int followersCount;
  final int followingsCount;
  final String firstName;
  final String fullName;
  final int groupsCount;
  final int id;
  final String kind;
  final String lastModified;
  final String lastName;
  final int likesCount;
  final int playlistLikesCount;
  final String permalink;
  final String permalinkUrl;
  final int playlistCount;
  final int? repostsCount;
  final int trackCount;
  final String uri;
  final String urn;
  final String username;
  final bool verified;
  final UserVisuals? visuals;
  final Badges badges;
  final String stationUrn;
  final String stationPermalink;
  final DateOfBirth? dateOfBirth;

  User({
    required this.avatarUrl,
    this.city,
    required this.commentsCount,
    this.countryCode,
    required this.createdAt,
    required this.creatorSubscriptions,
    required this.creatorSubscription,
    this.description,
    required this.followersCount,
    required this.followingsCount,
    required this.firstName,
    required this.fullName,
    required this.groupsCount,
    required this.id,
    required this.kind,
    required this.lastModified,
    required this.lastName,
    required this.likesCount,
    required this.playlistLikesCount,
    required this.permalink,
    required this.permalinkUrl,
    required this.playlistCount,
    this.repostsCount,
    required this.trackCount,
    required this.uri,
    required this.urn,
    required this.username,
    required this.verified,
    this.visuals,
    required this.badges,
    required this.stationUrn,
    required this.stationPermalink,
    this.dateOfBirth,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      avatarUrl: json['avatar_url'] ?? '',
      city: json['city'],
      commentsCount: json['comments_count'] ?? 0,
      countryCode: json['country_code'],
      createdAt: json['created_at'] ?? '',
      creatorSubscriptions: (json['creator_subscriptions'] as List? ?? [])
          .map((item) => CreatorSubscription.fromJson(item))
          .toList(),
      creatorSubscription: json['creator_subscription'] != null
          ? CreatorSubscription.fromJson(json['creator_subscription'])
          : CreatorSubscription.empty(),
      description: json['description'],
      followersCount: json['followers_count'] ?? 0,
      followingsCount: json['followings_count'] ?? 0,
      firstName: json['first_name'] ?? '',
      fullName: json['full_name'] ?? '',
      groupsCount: json['groups_count'] ?? 0,
      id: json['id'] ?? 0,
      kind: json['kind'] ?? '',
      lastModified: json['last_modified'] ?? '',
      lastName: json['last_name'] ?? '',
      likesCount: json['likes_count'] ?? 0,
      playlistLikesCount: json['playlist_likes_count'] ?? 0,
      permalink: json['permalink'] ?? '',
      permalinkUrl: json['permalink_url'] ?? '',
      playlistCount: json['playlist_count'] ?? 0,
      repostsCount: json['reposts_count'],
      trackCount: json['track_count'] ?? 0,
      uri: json['uri'] ?? '',
      urn: json['urn'] ?? '',
      username: json['username'] ?? '',
      verified: json['verified'] ?? false,
      visuals: json['visuals'] != null ? UserVisuals.fromJson(json['visuals']) : null,
      badges: json['badges'] != null
          ? Badges.fromJson(json['badges'])
          : Badges.empty(),
      stationUrn: json['station_urn'] ?? '',
      stationPermalink: json['station_permalink'] ?? '',
      dateOfBirth: json['date_of_birth'] != null
          ? DateOfBirth.fromJson(json['date_of_birth'])
          : null,
    );
  }

  // Factory constructor for empty user
  factory User.empty() {
    return User(
      avatarUrl: '',
      commentsCount: 0,
      createdAt: '',
      creatorSubscriptions: [],
      creatorSubscription: CreatorSubscription.empty(),
      followersCount: 0,
      followingsCount: 0,
      firstName: '',
      fullName: '',
      groupsCount: 0,
      id: 0,
      kind: 'user',
      lastModified: '',
      lastName: '',
      likesCount: 0,
      playlistLikesCount: 0,
      permalink: '',
      permalinkUrl: '',
      playlistCount: 0,
      trackCount: 0,
      uri: '',
      urn: '',
      username: '',
      verified: false,
      badges: Badges.empty(),
      stationUrn: '',
      stationPermalink: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avatar_url': avatarUrl,
      'city': city,
      'comments_count': commentsCount,
      'country_code': countryCode,
      'created_at': createdAt,
      'creator_subscriptions': creatorSubscriptions.map((cs) => cs.toJson()).toList(),
      'creator_subscription': creatorSubscription.toJson(),
      'description': description,
      'followers_count': followersCount,
      'followings_count': followingsCount,
      'first_name': firstName,
      'full_name': fullName,
      'groups_count': groupsCount,
      'id': id,
      'kind': kind,
      'last_modified': lastModified,
      'last_name': lastName,
      'likes_count': likesCount,
      'playlist_likes_count': playlistLikesCount,
      'permalink': permalink,
      'permalink_url': permalinkUrl,
      'playlist_count': playlistCount,
      'reposts_count': repostsCount,
      'track_count': trackCount,
      'uri': uri,
      'urn': urn,
      'username': username,
      'verified': verified,
      'visuals': visuals?.toJson(),
      'badges': badges.toJson(),
      'station_urn': stationUrn,
      'station_permalink': stationPermalink,
      'date_of_birth': dateOfBirth?.toJson(),
    };
  }
}

// CreatorSubscription model
class CreatorSubscription {
  final Product product;

  CreatorSubscription({required this.product});

  factory CreatorSubscription.fromJson(Map<String, dynamic> json) {
    return CreatorSubscription(
      product: json['product'] != null
          ? Product.fromJson(json['product'])
          : Product.empty(),
    );
  }

  // Factory constructor for empty creator subscription
  factory CreatorSubscription.empty() {
    return CreatorSubscription(
      product: Product.empty(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
    };
  }
}

// Product model
class Product {
  final String id;

  Product({required this.id});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(id: json['id'] ?? '');
  }

  // Factory constructor for empty product
  factory Product.empty() {
    return Product(id: '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id};
  }
}

// UserVisuals model
class UserVisuals {
  final String urn;
  final bool enabled;
  final List<Visual> visuals;
  final dynamic tracking;

  UserVisuals({
    required this.urn,
    required this.enabled,
    required this.visuals,
    this.tracking,
  });

  factory UserVisuals.fromJson(Map<String, dynamic> json) {
    return UserVisuals(
      urn: json['urn'] ?? '',
      enabled: json['enabled'] ?? false,
      visuals: (json['visuals'] as List? ?? [])
          .map((item) => Visual.fromJson(item))
          .toList(),
      tracking: json['tracking'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'urn': urn,
      'enabled': enabled,
      'visuals': visuals.map((v) => v.toJson()).toList(),
      'tracking': tracking,
    };
  }
}

// Visual model
class Visual {
  final String urn;
  final int entryTime;
  final String visualUrl;

  Visual({
    required this.urn,
    required this.entryTime,
    required this.visualUrl,
  });

  factory Visual.fromJson(Map<String, dynamic> json) {
    return Visual(
      urn: json['urn'] ?? '',
      entryTime: json['entry_time'] ?? 0,
      visualUrl: json['visual_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'urn': urn,
      'entry_time': entryTime,
      'visual_url': visualUrl,
    };
  }
}

// Badges model
class Badges {
  final bool pro;
  final bool creatorMidTier;
  final bool proUnlimited;
  final bool verified;

  Badges({
    required this.pro,
    required this.creatorMidTier,
    required this.proUnlimited,
    required this.verified,
  });

  factory Badges.fromJson(Map<String, dynamic> json) {
    return Badges(
      pro: json['pro'] ?? false,
      creatorMidTier: json['creator_mid_tier'] ?? false,
      proUnlimited: json['pro_unlimited'] ?? false,
      verified: json['verified'] ?? false,
    );
  }

  // Factory constructor for empty badges
  factory Badges.empty() {
    return Badges(
      pro: false,
      creatorMidTier: false,
      proUnlimited: false,
      verified: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pro': pro,
      'creator_mid_tier': creatorMidTier,
      'pro_unlimited': proUnlimited,
      'verified': verified,
    };
  }
}

// DateOfBirth model
class DateOfBirth {
  final int month;
  final int year;
  final int day;

  DateOfBirth({
    required this.month,
    required this.year,
    required this.day,
  });

  factory DateOfBirth.fromJson(Map<String, dynamic> json) {
    return DateOfBirth(
      month: json['month'] ?? 1,
      year: json['year'] ?? 1900,
      day: json['day'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'year': year,
      'day': day,
    };
  }
}