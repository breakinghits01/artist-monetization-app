import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../models/artist_model.dart';

final artistApiServiceProvider = Provider<ArtistApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ArtistApiService(dio);
});

class ArtistApiService {
  final Dio _dio;
  static const String _baseUrl = '/users';
  static const String _followBaseUrl = '/follow';

  ArtistApiService(this._dio);

  /// Discover artists with pagination and filters
  Future<Map<String, dynamic>> discoverArtists({
    int page = 1,
    int limit = 20,
    String? search,
    String? genre,
    String sortBy = 'followerCount', // followerCount, songCount, latest
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        if (search != null && search.isNotEmpty) 'search': search,
        if (genre != null && genre.isNotEmpty) 'genre': genre,
      };

      final response = await _dio.get(
        '$_baseUrl/discover',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final artists = (data['artists'] as List)
            .map((json) => ArtistModel.fromJson(json))
            .toList();

        return {
          'artists': artists,
          'pagination': data['pagination'],
        };
      }

      throw ApiException(message: 'Failed to fetch artists');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get artist profile by ID
  Future<ArtistModel> getArtistProfile(String userId) async {
    try {
      final response = await _dio.get('$_baseUrl/profile/$userId');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final user = data['user'];
        final stats = data['stats'];

        // Merge user and stats
        return ArtistModel.fromJson({
          ...user,
          'followerCount': stats['followerCount'] ?? 0,
          'followingCount': stats['followingCount'] ?? 0,
          'songCount': stats['songCount'] ?? 0,
        });
      }

      throw ApiException(message: 'Failed to fetch artist profile');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Follow an artist
  Future<void> followArtist(String artistId) async {
    try {
      final response = await _dio.post('$_followBaseUrl/$artistId');

      if (response.statusCode != 201) {
        throw ApiException(message: 'Failed to follow artist');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Unfollow an artist
  Future<void> unfollowArtist(String artistId) async {
    try {
      final response = await _dio.delete('$_followBaseUrl/$artistId');

      if (response.statusCode != 200) {
        throw ApiException(message: 'Failed to unfollow artist');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Check if following an artist
  Future<bool> checkFollowStatus(String artistId) async {
    try {
      final response = await _dio.get('$_followBaseUrl/status/$artistId');

      if (response.statusCode == 200) {
        return response.data['data']['isFollowing'] ?? false;
      }

      return false;
    } on DioException catch (e) {
      print('⚠️ Error checking follow status: $e');
      return false;
    }
  }

  /// Get follow stats for a user
  Future<FollowStats> getFollowStats(String userId) async {
    try {
      final response = await _dio.get('$_followBaseUrl/stats/$userId');

      if (response.statusCode == 200) {
        return FollowStats.fromJson(response.data['data']);
      }

      throw ApiException(message: 'Failed to fetch follow stats');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
