class ArtistModel {
  final String id;
  final String username;
  final String? email;
  final String? profilePicture;
  final String? bio;
  final int followerCount;
  final int followingCount;
  final int songCount;
  final bool hasExclusiveContent;
  final DateTime? createdAt;

  ArtistModel({
    required this.id,
    required this.username,
    this.email,
    this.profilePicture,
    this.bio,
    required this.followerCount,
    required this.followingCount,
    required this.songCount,
    this.hasExclusiveContent = false,
    this.createdAt,
  });

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    return ArtistModel(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? 'Unknown',
      email: json['email'],
      profilePicture: json['profilePicture'],
      bio: json['bio'],
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      songCount: json['songCount'] ?? 0,
      hasExclusiveContent: json['hasExclusiveContent'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      if (email != null) 'email': email,
      if (profilePicture != null) 'profilePicture': profilePicture,
      if (bio != null) 'bio': bio,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'songCount': songCount,
      'hasExclusiveContent': hasExclusiveContent,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}

/// Follow stats model
class FollowStats {
  final int followerCount;
  final int followingCount;

  FollowStats({
    required this.followerCount,
    required this.followingCount,
  });

  factory FollowStats.fromJson(Map<String, dynamic> json) {
    return FollowStats(
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followerCount': followerCount,
      'followingCount': followingCount,
    };
  }
}

