import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../models/artist_model.dart';

final followApiServiceProvider = Provider<FollowApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return FollowApiService(dio);
});

class FollowApiService {
  final Dio _dio;
  final String _baseUrl = '/follow';

  FollowApiService(this._dio);

  // Follow an artist
  Future<void> followArtist(String artistId) async {
    try {
      await _dio.post('$_baseUrl/$artistId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Unfollow an artist
  Future<void> unfollowArtist(String artistId) async {
    try {
      await _dio.delete('$_baseUrl/$artistId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Get followers of a user
  Future<Map<String, dynamic>> getFollowers(String userId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/followers/$userId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final followers = (response.data['data']['followers'] as List)
          .map((follower) => ArtistModel.fromJson(follower))
          .toList();

      return {
        'followers': followers,
        'pagination': response.data['data']['pagination'],
      };
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Get artists that a user follows
  Future<Map<String, dynamic>> getFollowing(String userId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/following/$userId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final following = (response.data['data']['following'] as List)
          .map((artist) => ArtistModel.fromJson(artist))
          .toList();

      return {
        'following': following,
        'pagination': response.data['data']['pagination'],
      };
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Check if current user follows an artist
  Future<bool> checkFollowStatus(String artistId) async {
    try {
      final response = await _dio.get('$_baseUrl/status/$artistId');
      return response.data['data']['isFollowing'] as bool;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Get follow stats for a user
  Future<Map<String, int>> getFollowStats(String userId) async {
    try {
      final response = await _dio.get('$_baseUrl/stats/$userId');
      return {
        'followerCount': response.data['data']['followerCount'] as int,
        'followingCount': response.data['data']['followingCount'] as int,
      };
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
