import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../artist/models/artist_model.dart';
import '../../artist/services/artist_api_service.dart';
import '../../player/models/song_model.dart';
import '../../../core/config/api_config.dart';
import '../../../core/api/api_client.dart';

/// Provider for fetching any user's public profile by userId
/// Used when viewing other users' profiles (not the current logged-in user)
final publicUserProfileProvider =
    FutureProvider.family<ArtistModel, String>((ref, userId) async {
  final apiService = ref.watch(artistApiServiceProvider);
  
  try {
    final artist = await apiService.getArtistProfile(userId);
    return artist;
  } catch (e) {
    rethrow;
  }
});

/// Provider for fetching a specific user's songs by userId
/// This is different from userSongsProvider which fetches current user's songs
final publicUserSongsProvider =
    FutureProvider.family<List<SongModel>, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  
  try {
    // Use relative path without /api/v1 since dio baseUrl already includes it
    final endpoint = '/songs/artist/$userId';
    final response = await dio.get(endpoint);

    if (response.statusCode == 200) {
      final data = response.data['data'];
      final songsJson = data['songs'] as List? ?? [];

      return songsJson.map((json) => _parseSongFromJson(json)).toList();
    }

    return [];
  } catch (e) {
    print('❌ Error fetching user songs: $e');
    return [];
  }
});

/// Helper function to parse song JSON into SongModel
SongModel _parseSongFromJson(Map<String, dynamic> json) {
  // Handle artist data which could be populated object or just ID string
  final artistData = json['artistId'];
  final artistName = artistData is Map<String, dynamic>
      ? (artistData['username'] as String?)
      : null;
  final artistIdValue = artistData is Map<String, dynamic>
      ? (artistData['_id'] as String? ?? artistData['id'] as String?)
      : (artistData as String?);

  return SongModel(
    id: json['_id'] ?? json['id'] ?? '',
    title: json['title'] ?? 'Untitled',
    artist: artistName ?? json['artistName'] ?? 'Unknown Artist',
    artistId: artistIdValue ?? '',
    albumArt: json['coverArt'] ?? json['albumArt'] ?? 'https://via.placeholder.com/300',
    duration: Duration(seconds: json['duration'] ?? 180),
    audioUrl: json['fileUrl'] ?? json['audioUrl'] ?? '',
    genre: json['genre'] ?? 'Unknown',
    tokenReward: json['price'] ?? json['tokenReward'] ?? 10,
    playCount: json['playCount'] ?? 0,
    likeCount: json['likeCount'] ?? 0,
    dislikeCount: json['dislikeCount'] ?? 0,
    commentCount: json['commentCount'] ?? 0,
    shareCount: json['shareCount'] ?? 0,
    isPremium: json['exclusive'] ?? false,
  );
}
