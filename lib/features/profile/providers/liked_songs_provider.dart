import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that manages liked songs state across the app
/// Stores song IDs that the user has liked
class LikedSongsNotifier extends StateNotifier<Set<String>> {
  LikedSongsNotifier() : super({});

  /// Check if a song is liked
  bool isLiked(String songId) => state.contains(songId);

  /// Toggle like state for a song
  void toggleLike(String songId) {
    if (state.contains(songId)) {
      // Unlike
      state = {...state}..remove(songId);
      print('❤️ Removed from liked: $songId');
    } else {
      // Like
      state = {...state, songId};
      print('💗 Added to liked: $songId');
    }
  }

  /// Load liked songs from API (future implementation)
  Future<void> fetchLikedSongs() async {
    try {
      // TODO: API call to get user's liked song IDs
      // final response = await _api.get('/users/me/liked');
      // state = Set<String>.from(response.data['songIds']);
      
      // For now, initialize empty
      state = {};
    } catch (e) {
      print('Error fetching liked songs: $e');
    }
  }

  // TODO: Save liked state to API (future implementation)
  // Future<void> _syncToApi(String songId, bool isLiked) async {
  //   try {
  //     if (isLiked) {
  //       await _api.post('/songs/$songId/like');
  //     } else {
  //       await _api.delete('/songs/$songId/like');
  //     }
  //   } catch (e) {
  //     print('Error syncing like state: $e');
  //   }
  // }
}

/// Global provider for liked songs
final likedSongsProvider =
    StateNotifierProvider<LikedSongsNotifier, Set<String>>(
  (ref) => LikedSongsNotifier(),
);
