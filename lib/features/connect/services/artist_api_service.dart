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
  final String _baseUrl = '/users';

  ArtistApiService(this._dio);

  // Discover artists with filters
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
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (genre != null && genre.isNotEmpty) {
        queryParams['genre'] = genre;
      }

      final response = await _dio.get(
        '$_baseUrl/discover',
        queryParameters: queryParams,
      );

      final artists = (response.data['data']['artists'] as List)
          .map((artist) => ArtistModel.fromJson(artist))
          .toList();

      return {
        'artists': artists,
        'pagination': response.data['data']['pagination'],
      };
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Get artist profile
  Future<Map<String, dynamic>> getArtistProfile(String artistId) async {
    try {
      final response = await _dio.get('$_baseUrl/profile/$artistId');

      return {
        'user': ArtistModel.fromJson(response.data['data']['user']),
        'stats': response.data['data']['stats'],
      };
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      final response = await _dio.get('$_baseUrl/me');

      return {
        'user': ArtistModel.fromJson(response.data['data']['user']),
        'stats': response.data['data']['stats'],
      };
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Update user profile
  Future<ArtistModel> updateProfile({
    String? username,
    String? bio,
    String? profilePicture,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (bio != null) data['bio'] = bio;
      if (profilePicture != null) data['profilePicture'] = profilePicture;

      final response = await _dio.patch('$_baseUrl/me', data: data);

      return ArtistModel.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
