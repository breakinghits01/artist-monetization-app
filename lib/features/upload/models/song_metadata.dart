/// Song metadata for upload
class SongMetadata {
  final String title;
  final String? genre;
  final String? description;
  final int price;
  final int? duration; // Duration in seconds
  final String? coverArtPath;
  final String? coverArtUrl;
  final bool exclusive;
  final bool allowDownload;
  final bool allowRemix;
  final String? albumName;
  final String? lyrics;
  final DateTime? releaseDate;

  const SongMetadata({
    required this.title,
    this.genre,
    this.description,
    this.price = 10,
    this.duration,
    this.coverArtPath,
    this.coverArtUrl,
    this.exclusive = false,
    this.allowDownload = false,
    this.allowRemix = false,
    this.albumName,
    this.lyrics,
    this.releaseDate,
  });

  SongMetadata copyWith({
    String? title,
    String? genre,
    String? description,
    int? price,
    int? duration,
    String? coverArtPath,
    String? coverArtUrl,
    bool? exclusive,
    bool? allowDownload,
    bool? allowRemix,
    String? albumName,
    String? lyrics,
    DateTime? releaseDate,
  }) {
    return SongMetadata(
      title: title ?? this.title,
      genre: genre ?? this.genre,
      description: description ?? this.description,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      coverArtPath: coverArtPath ?? this.coverArtPath,
      coverArtUrl: coverArtUrl ?? this.coverArtUrl,
      exclusive: exclusive ?? this.exclusive,
      allowDownload: allowDownload ?? this.allowDownload,
      allowRemix: allowRemix ?? this.allowRemix,
      albumName: albumName ?? this.albumName,
      lyrics: lyrics ?? this.lyrics,
      releaseDate: releaseDate ?? this.releaseDate,
    );
  }
}

/// Available music genres
class MusicGenres {
  static const List<String> all = [
    'Pop',
    'Rock',
    'Hip Hop',
    'R&B',
    'Electronic',
    'Jazz',
    'Classical',
    'Country',
    'Folk',
    'Reggae',
    'Blues',
    'Metal',
    'Indie',
    'Alternative',
    'Soul',
    'Funk',
    'Dance',
    'House',
    'Techno',
    'Ambient',
    'Other',
  ];
}
