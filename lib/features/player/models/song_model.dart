/// Song model for audio player
class SongModel {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String? albumArt;
  final String audioUrl;
  final Duration duration;
  final int tokenReward; // Tokens earned for completing this song
  final String? genre;
  final bool isPremium;
  final int playCount; // Number of times this song has been played
  
  // Engagement metrics
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final int shareCount;
  final double? averageRating; // 0-5 stars
  final int ratingCount;
  final int engagementScore;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    this.albumArt,
    required this.audioUrl,
    required this.duration,
    this.tokenReward = 5,
    this.genre,
    this.isPremium = false,
    this.playCount = 0,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.averageRating,
    this.ratingCount = 0,
    this.engagementScore = 0,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    // Backend populates artistId with user data (username, email, avatarUrl)
    final artistData = json['artistId'];
    final artistName = artistData is Map<String, dynamic> 
        ? (artistData['username'] as String?) 
        : null;
    final artistIdValue = artistData is Map<String, dynamic>
        ? (artistData['_id'] as String?)
        : (artistData as String?);
    
    return SongModel(
      id: json['_id'] as String,
      title: json['title'] as String,
      artist: artistName ?? 'Unknown Artist',
      artistId: artistIdValue ?? '',
      albumArt: json['albumArt'] as String?,
      audioUrl: json['audioUrl'] as String,
      duration: Duration(seconds: json['duration'] as int? ?? 0),
      tokenReward: json['tokenReward'] as int? ?? 5,
      genre: json['genre'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
      playCount: json['playCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      dislikeCount: json['dislikeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      shareCount: json['shareCount'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      ratingCount: json['ratingCount'] as int? ?? 0,
      engagementScore: json['engagementScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'artist': {'name': artist, '_id': artistId},
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'engagementScore': engagementScore,
      'albumArt': albumArt,
      'audioUrl': audioUrl,
      'duration': duration.inSeconds,
      'tokenReward': tokenReward,
      'genre': genre,
      'isPremium': isPremium,
      'playCount': playCount,
    };
  }

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? artistId,
    String? albumArt,
    String? audioUrl,
    Duration? duration,
    int? tokenReward,
    String? genre,
    bool? isPremium,
    int? playCount,
    int? likeCount,
    int? dislikeCount,
    int? commentCount,
    int? shareCount,
    double? averageRating,
    int? ratingCount,
    int? engagementScore,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      albumArt: albumArt ?? this.albumArt,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      tokenReward: tokenReward ?? this.tokenReward,
      genre: genre ?? this.genre,
      isPremium: isPremium ?? this.isPremium,
      playCount: playCount ?? this.playCount,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      engagementScore: engagementScore ?? this.engagementScore,
    );
  }
}
