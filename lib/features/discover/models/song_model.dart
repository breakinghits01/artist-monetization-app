class SongModel {
  final String id;
  final String title;
  final int duration;
  final double price;
  final String? coverArt;
  final String audioUrl;
  final bool exclusive;
  final String? genre;
  final String? description;
  final int playCount;
  final bool featured;
  final Artist artist;
  final DateTime createdAt;

  const SongModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.price,
    this.coverArt,
    required this.audioUrl,
    required this.exclusive,
    this.genre,
    this.description,
    required this.playCount,
    required this.featured,
    required this.artist,
    required this.createdAt,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      duration: json['duration'],
      price: (json['price'] as num).toDouble(),
      coverArt: json['coverArt'],
      audioUrl: json['audioUrl'],
      exclusive: json['exclusive'] ?? false,
      genre: json['genre'],
      description: json['description'],
      playCount: json['playCount'] ?? 0,
      featured: json['featured'] ?? false,
      artist: Artist.fromJson(json['artistId']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedPlayCount {
    if (playCount >= 1000000) {
      return '${(playCount / 1000000).toStringAsFixed(1)}M';
    } else if (playCount >= 1000) {
      return '${(playCount / 1000).toStringAsFixed(1)}K';
    }
    return playCount.toString();
  }
}

class Artist {
  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;

  const Artist({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['_id'] ?? json['id'],
      username: json['username'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
    );
  }
}
