import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../player/models/song_model.dart';

/// User songs state
class UserSongsState {
  final List<SongModel> songs;
  final bool isLoading;
  final String? error;

  const UserSongsState({
    this.songs = const [],
    this.isLoading = false,
    this.error,
  });

  UserSongsState copyWith({
    List<SongModel>? songs,
    bool? isLoading,
    String? error,
  }) {
    return UserSongsState(
      songs: songs ?? this.songs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// User songs provider - fetches songs from backend
final userSongsProvider = StateNotifierProvider<UserSongsNotifier, UserSongsState>((ref) {
  return UserSongsNotifier();
});

class UserSongsNotifier extends StateNotifier<UserSongsState> {
  UserSongsNotifier() : super(const UserSongsState()) {
    fetchUserSongs();
  }

  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  /// Fetch user's songs (including drafts and published)
  Future<void> fetchUserSongs() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Add auth token
      final response = await _dio.get(
        '/api/songs/user',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConfig.tempToken}',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final songsData = response.data['songs'] as List;
        final songs = songsData.map((json) => _parseSong(json)).toList();
        
        state = state.copyWith(songs: songs, isLoading: false);
      } else {
        throw Exception('Failed to fetch songs');
      }
    } catch (e) {
      print('Error fetching user songs: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        songs: [], // Empty list on error
      );
    }
  }

  /// Refresh songs list
  Future<void> refresh() => fetchUserSongs();

  /// Add a new song to the list (called after upload)
  void addSong(SongModel song) {
    state = state.copyWith(
      songs: [song, ...state.songs],
    );
  }

  /// Parse song from API response
  SongModel _parseSong(Map<String, dynamic> json) {
    return SongModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      artist: json['artist']?['name'] ?? json['artistName'] ?? 'Unknown Artist',
      artistId: json['artist']?['_id'] ?? json['artistId'] ?? '',
      albumArt: json['coverArt'] ?? json['albumArt'] ?? 'https://via.placeholder.com/300',
      duration: Duration(seconds: json['duration'] ?? 180),
      audioUrl: json['audioUrl'] ?? json['fileUrl'] ?? '',
      genre: json['genre'] ?? 'Unknown',
      tokenReward: json['price'] ?? json['tokenReward'] ?? 10,
    );
  }
}
