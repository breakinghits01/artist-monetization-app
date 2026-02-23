import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/models/song_model.dart';
import '../../discover/services/song_api_service.dart';

/// Provider for fetching trending songs
final trendingSongsProvider = FutureProvider<List<SongModel>>((ref) async {
  final apiService = ref.watch(songApiServiceProvider);
  
  // Fetch trending songs from API (sorted by play count descending)
  final result = await apiService.discoverSongs(
    page: 1,
    sortBy: 'playCount',
    sortOrder: 'desc',
    limit: 50, // Top 50 trending songs
  );
  
  final discoverSongs = result['songs'] as List;
  
  // Convert to player song models
  return discoverSongs.map((s) => SongModel(
    id: s.id,
    title: s.title,
    artist: s.artist?.username ?? 'Unknown Artist',
    artistId: s.artist?.id ?? '',
    albumArt: s.coverArt,
    audioUrl: s.audioUrl,
    duration: Duration(seconds: s.duration),
    tokenReward: s.price.toInt(),
    genre: s.genre,
    isPremium: s.exclusive,
    playCount: s.playCount,
  )).toList();
});
