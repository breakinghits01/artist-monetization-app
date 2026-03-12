import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/models/song_model.dart';
import '../../discover/services/song_api_service.dart';

/// Provider for fetching trending songs with real-time updates
final trendingSongsProvider =
    StateNotifierProvider<TrendingSongsNotifier, AsyncValue<List<SongModel>>>(
  (ref) => TrendingSongsNotifier(ref),
);

class TrendingSongsNotifier extends StateNotifier<AsyncValue<List<SongModel>>> {
  final Ref _ref;

  TrendingSongsNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchTrendingSongs();
  }

  /// Fetch trending songs from API
  Future<void> fetchTrendingSongs() async {
    try {
      state = const AsyncValue.loading();
      
      final apiService = _ref.read(songApiServiceProvider);
      
      // Fetch trending songs from API (sorted by play count descending)
      final result = await apiService.discoverSongs(
        page: 1,
        sortBy: 'playCount',
        sortOrder: 'desc',
        limit: 50, // Top 50 trending songs
      );
      
      final discoverSongs = result['songs'] as List;
      
      // Convert to player song models with engagement metrics
      final songs = discoverSongs.map((s) => SongModel(
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
        commentCount: s.commentCount,
        shareCount: s.shareCount,
      )).toList();
      
      state = AsyncValue.data(songs);
      print('✅ Loaded ${songs.length} trending songs');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      print('❌ Failed to load trending songs: $e');
    }
  }

  /// Update play count for a specific song in real-time
  void updateSongPlayCount(String songId, int newPlayCount) {
    state.whenData((songs) {
      final updatedSongs = songs.map((song) {
        if (song.id == songId) {
          return SongModel(
            id: song.id,
            title: song.title,
            artist: song.artist,
            artistId: song.artistId,
            albumArt: song.albumArt,
            audioUrl: song.audioUrl,
            duration: song.duration,
            tokenReward: song.tokenReward,
            genre: song.genre,
            isPremium: song.isPremium,
            playCount: newPlayCount, // Update with new count from backend
            likeCount: song.likeCount,
            dislikeCount: song.dislikeCount,
            commentCount: song.commentCount,
            shareCount: song.shareCount,
            averageRating: song.averageRating,
            ratingCount: song.ratingCount,
            engagementScore: song.engagementScore,
          );
        }
        return song;
      }).toList();

      state = AsyncValue.data(updatedSongs);
      print('✅ Updated song $songId play count to $newPlayCount in trending list');
    });
  }

  /// Refresh trending songs (for pull-to-refresh)
  Future<void> refresh() => fetchTrendingSongs();
}
