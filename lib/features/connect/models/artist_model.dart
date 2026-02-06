class ArtistModel {
  final String id;
  final String username;
  final String email;
  final String? profilePicture;
  final String? bio;
  final int followerCount;
  final int followingCount;
  final int songCount;
  final bool hasExclusiveContent;
  final DateTime createdAt;

  ArtistModel({
    required this.id,
    required this.username,
    required this.email,
    this.profilePicture,
    this.bio,
    required this.followerCount,
    required this.followingCount,
    required this.songCount,
    required this.hasExclusiveContent,
    required this.createdAt,
  });

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    return ArtistModel(
      id: json['_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      profilePicture: json['profilePicture'] as String?,
      bio: json['bio'] as String?,
      followerCount: json['followerCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      songCount: json['songCount'] as int? ?? 0,
      hasExclusiveContent: json['hasExclusiveContent'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'profilePicture': profilePicture,
      'bio': bio,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'songCount': songCount,
      'hasExclusiveContent': hasExclusiveContent,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get formattedFollowerCount {
    if (followerCount >= 1000000) {
      return '${(followerCount / 1000000).toStringAsFixed(1)}M';
    } else if (followerCount >= 1000) {
      return '${(followerCount / 1000).toStringAsFixed(1)}K';
    }
    return followerCount.toString();
  }

  String get formattedSongCount {
    if (songCount >= 1000) {
      return '${(songCount / 1000).toStringAsFixed(1)}K';
    }
    return songCount.toString();
  }

  String get initials {
    final parts = username.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.substring(0, 2).toUpperCase();
  }
}
