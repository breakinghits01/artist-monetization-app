class Song {
  final String id;
  final String title;
  final String artist;
  final String albumArt;
  final String duration;
  final String genre;
  final int playCount;
  final DateTime releaseDate;
  final String? audioUrl;
  final double? price;
  final bool isLiked;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArt,
    required this.duration,
    required this.genre,
    required this.playCount,
    required this.releaseDate,
    this.audioUrl,
    this.price,
    this.isLiked = false,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumArt,
    String? duration,
    String? genre,
    int? playCount,
    DateTime? releaseDate,
    String? audioUrl,
    double? price,
    bool? isLiked,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArt: albumArt ?? this.albumArt,
      duration: duration ?? this.duration,
      genre: genre ?? this.genre,
      playCount: playCount ?? this.playCount,
      releaseDate: releaseDate ?? this.releaseDate,
      audioUrl: audioUrl ?? this.audioUrl,
      price: price ?? this.price,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'albumArt': albumArt,
      'duration': duration,
      'genre': genre,
      'playCount': playCount,
      'releaseDate': releaseDate.toIso8601String(),
      'audioUrl': audioUrl,
      'price': price,
      'isLiked': isLiked,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      albumArt: json['albumArt'],
      duration: json['duration'],
      genre: json['genre'],
      playCount: json['playCount'],
      releaseDate: DateTime.parse(json['releaseDate']),
      audioUrl: json['audioUrl'],
      price: json['price']?.toDouble(),
      isLiked: json['isLiked'] ?? false,
    );
  }
}

/// Mock data for 10 diverse songs
class MockSongs {
  static final List<Song> songs = [
    Song(
      id: '1',
      title: 'Neon Dreams',
      artist: 'Cyber Synthwave',
      albumArt: 'https://picsum.photos/seed/album1/300/300',
      duration: '3:45',
      genre: 'Electronic',
      playCount: 15420,
      releaseDate: DateTime(2025, 12, 15),
      price: 2.99,
      isLiked: true,
    ),
    Song(
      id: '2',
      title: 'Midnight Rider',
      artist: 'The Velvet Horizon',
      albumArt: 'https://picsum.photos/seed/album2/300/300',
      duration: '4:12',
      genre: 'Rock',
      playCount: 28350,
      releaseDate: DateTime(2025, 11, 20),
      price: 1.99,
      isLiked: false,
    ),
    Song(
      id: '3',
      title: 'Tokyo Nights',
      artist: 'DJ Pulse',
      albumArt: 'https://picsum.photos/seed/album3/300/300',
      duration: '5:23',
      genre: 'House',
      playCount: 42100,
      releaseDate: DateTime(2026, 1, 5),
      price: 3.49,
      isLiked: true,
    ),
    Song(
      id: '4',
      title: 'Whispers in the Rain',
      artist: 'Luna Echo',
      albumArt: 'https://picsum.photos/seed/album4/300/300',
      duration: '3:58',
      genre: 'Indie Pop',
      playCount: 19800,
      releaseDate: DateTime(2025, 10, 30),
      price: 2.49,
      isLiked: false,
    ),
    Song(
      id: '5',
      title: 'Bassline Paradise',
      artist: 'Groove Master',
      albumArt: 'https://picsum.photos/seed/album5/300/300',
      duration: '4:45',
      genre: 'Hip Hop',
      playCount: 35600,
      releaseDate: DateTime(2025, 12, 1),
      price: 2.99,
      isLiked: true,
    ),
    Song(
      id: '6',
      title: 'Smooth Operator',
      artist: 'Jazz Collective',
      albumArt: 'https://picsum.photos/seed/album6/300/300',
      duration: '6:15',
      genre: 'Jazz',
      playCount: 12450,
      releaseDate: DateTime(2025, 9, 15),
      price: 3.99,
      isLiked: false,
    ),
    Song(
      id: '7',
      title: 'Electric Love',
      artist: 'Starlight Symphony',
      albumArt: 'https://picsum.photos/seed/album7/300/300',
      duration: '3:32',
      genre: 'Pop',
      playCount: 58200,
      releaseDate: DateTime(2026, 1, 12),
      price: 1.99,
      isLiked: true,
    ),
    Song(
      id: '8',
      title: 'Soulful Sunrise',
      artist: 'R&B Vibes',
      albumArt: 'https://picsum.photos/seed/album8/300/300',
      duration: '4:28',
      genre: 'R&B',
      playCount: 23700,
      releaseDate: DateTime(2025, 11, 8),
      price: 2.49,
      isLiked: false,
    ),
    Song(
      id: '9',
      title: 'Quantum Pulse',
      artist: 'Future Bass',
      albumArt: 'https://picsum.photos/seed/album9/300/300',
      duration: '3:55',
      genre: 'EDM',
      playCount: 44900,
      releaseDate: DateTime(2025, 12, 20),
      price: 3.49,
      isLiked: true,
    ),
    Song(
      id: '10',
      title: 'Desert Highway',
      artist: 'Western Winds',
      albumArt: 'https://picsum.photos/seed/album10/300/300',
      duration: '5:02',
      genre: 'Country Rock',
      playCount: 16300,
      releaseDate: DateTime(2025, 10, 10),
      price: 2.99,
      isLiked: false,
    ),
  ];
}
