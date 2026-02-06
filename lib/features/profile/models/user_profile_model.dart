class UserProfile {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? bio;
  final String? avatarUrl;
  final String? coverPhotoUrl;
  final int followerCount;
  final int followingCount;
  final int totalPlays;
  final int songCount;
  final DateTime joinDate;
  final List<String>? favoriteGenres;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.bio,
    this.avatarUrl,
    this.coverPhotoUrl,
    this.followerCount = 0,
    this.followingCount = 0,
    this.totalPlays = 0,
    this.songCount = 0,
    required this.joinDate,
    this.favoriteGenres,
  });

  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    String? bio,
    String? avatarUrl,
    String? coverPhotoUrl,
    int? followerCount,
    int? followingCount,
    int? totalPlays,
    int? songCount,
    DateTime? joinDate,
    List<String>? favoriteGenres,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      totalPlays: totalPlays ?? this.totalPlays,
      songCount: songCount ?? this.songCount,
      joinDate: joinDate ?? this.joinDate,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'totalPlays': totalPlays,
      'songCount': songCount,
      'joinDate': joinDate.toIso8601String(),
      'favoriteGenres': favoriteGenres,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      bio: json['bio'],
      avatarUrl: json['avatarUrl'],
      coverPhotoUrl: json['coverPhotoUrl'],
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      totalPlays: json['totalPlays'] ?? 0,
      songCount: json['songCount'] ?? 0,
      joinDate: DateTime.parse(json['joinDate']),
      favoriteGenres: json['favoriteGenres'] != null
          ? List<String>.from(json['favoriteGenres'])
          : null,
    );
  }
}

/// Mock user profile data
class MockUserProfile {
  static final UserProfile profile = UserProfile(
    id: '6982b4dbb7a73570da690dab',
    username: 'dekzblaster',
    email: 'dekzblaster.gw1@gmail.com',
    role: 'fan',
    bio: 'Music enthusiast 🎵 | Cyberpunk vibes | Love discovering new sounds',
    avatarUrl: null,
    coverPhotoUrl: 'https://picsum.photos/seed/cover1/1200/400',
    followerCount: 1234,
    followingCount: 567,
    totalPlays: 185600,
    songCount: 10,
    joinDate: DateTime(2025, 6, 15),
    favoriteGenres: ['Electronic', 'Rock', 'Hip Hop', 'Pop'],
  );
}
