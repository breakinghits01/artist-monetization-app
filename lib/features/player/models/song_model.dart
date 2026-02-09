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
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['_id'] as String,
      title: json['title'] as String,
      artist: json['artist']?['name'] as String? ?? 'Unknown Artist',
      artistId: json['artist']?['_id'] as String? ?? '',
      albumArt: json['albumArt'] as String?,
      audioUrl: json['audioUrl'] as String,
      duration: Duration(seconds: json['duration'] as int? ?? 0),
      tokenReward: json['tokenReward'] as int? ?? 5,
      genre: json['genre'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'artist': {'name': artist, '_id': artistId},
      'albumArt': albumArt,
      'audioUrl': audioUrl,
      'duration': duration.inSeconds,
      'tokenReward': tokenReward,
      'genre': genre,
      'isPremium': isPremium,
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
    );
  }
}
