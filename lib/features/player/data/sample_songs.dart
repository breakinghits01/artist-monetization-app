import '../models/song_model.dart';

/// Sample songs with real audio URLs for testing
class SampleSongs {
  static final List<SongModel> songs = [
    SongModel(
      id: 'sample_1',
      title: 'Summer Vibes',
      artist: 'Bensound',
      artistId: 'artist_bensound',
      audioUrl: 'https://www.bensound.com/bensound-music/bensound-summer.mp3',
      duration: const Duration(minutes: 2, seconds: 49),
      tokenReward: 5,
      genre: 'Pop',
      isPremium: false,
      albumArt: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&h=500&fit=crop',
    ),
    SongModel(
      id: 'sample_2',
      title: 'Acoustic Breeze',
      artist: 'Bensound',
      artistId: 'artist_bensound',
      audioUrl: 'https://www.bensound.com/bensound-music/bensound-acousticbreeze.mp3',
      duration: const Duration(minutes: 2, seconds: 37),
      tokenReward: 5,
      genre: 'Acoustic',
      isPremium: false,
      albumArt: 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=500&h=500&fit=crop',
    ),
    SongModel(
      id: 'sample_3',
      title: 'Creative Minds',
      artist: 'Bensound',
      artistId: 'artist_bensound',
      audioUrl: 'https://www.bensound.com/bensound-music/bensound-creativeminds.mp3',
      duration: const Duration(minutes: 2, seconds: 25),
      tokenReward: 5,
      genre: 'Electronic',
      isPremium: false,
      albumArt: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500&h=500&fit=crop',
    ),
    SongModel(
      id: 'sample_4',
      title: 'Funky Element',
      artist: 'Bensound',
      artistId: 'artist_bensound',
      audioUrl: 'https://www.bensound.com/bensound-music/bensound-funkyelement.mp3',
      duration: const Duration(minutes: 3, seconds: 8),
      tokenReward: 5,
      genre: 'Funk',
      isPremium: false,
      albumArt: 'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=500&h=500&fit=crop',
    ),
    SongModel(
      id: 'sample_5',
      title: 'Ukulele Dreams',
      artist: 'Bensound',
      artistId: 'artist_bensound',
      audioUrl: 'https://www.bensound.com/bensound-music/bensound-ukulele.mp3',
      duration: const Duration(minutes: 2, seconds: 26),
      tokenReward: 5,
      genre: 'Acoustic',
      isPremium: false,
      albumArt: 'https://images.unsplash.com/photo-1510915361894-db8b60106cb1?w=500&h=500&fit=crop',
    ),
    SongModel(
      id: 'sample_6',
      title: 'Tenderness',
      artist: 'Bensound',
      artistId: 'artist_bensound',
      audioUrl: 'https://www.bensound.com/bensound-music/bensound-tenderness.mp3',
      duration: const Duration(minutes: 2, seconds: 3),
      tokenReward: 5,
      genre: 'Ambient',
      isPremium: true,
      albumArt: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=500&h=500&fit=crop',
    ),
  ];

  /// Get a random song
  static SongModel getRandom() {
    songs.shuffle();
    return songs.first;
  }

  /// Get song by ID
  static SongModel? getById(String id) {
    try {
      return songs.firstWhere((song) => song.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get songs by genre
  static List<SongModel> getByGenre(String genre) {
    return songs.where((song) => song.genre == genre).toList();
  }
}
