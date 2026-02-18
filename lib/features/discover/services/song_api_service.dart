import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../models/song_model.dart';

final songApiServiceProvider = Provider<SongApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return SongApiService(dio);
});

class SongApiService {
  final Dio _dio;
  static const String _baseUrl = '/songs';

  SongApiService(this._dio);

  /// Discover songs with pagination and filters
  Future<Map<String, dynamic>> discoverSongs({
    int page = 1,
    int limit = 20,
    String? search,
    String? genre,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    bool? featured,
    bool? exclusive,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        '_t': DateTime.now().millisecondsSinceEpoch.toString(), // Cache buster
        if (search != null && search.isNotEmpty) 'search': search,
        if (genre != null && genre.isNotEmpty) 'genre': genre,
        if (featured != null) 'featured': featured.toString(),
        if (exclusive != null) 'exclusive': exclusive.toString(),
      };

      final response = await _dio.get(
        '$_baseUrl/discover',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final songs = (data['songs'] as List)
            .map((json) => SongModel.fromJson(json))
            .toList();

        return {
          'songs': songs,
          'pagination': data['pagination'],
        };
      }

      throw ApiException(message: 'Failed to fetch songs');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get available genres
  Future<List<String>> getGenres() async {
    try {
      final response = await _dio.get('$_baseUrl/genres');

      if (response.statusCode == 200) {
        final genres = (response.data['data']['genres'] as List)
            .map((g) => g.toString())
            .toList();
        return genres;
      }

      throw ApiException(message: 'Failed to fetch genres');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get song by ID
  Future<SongModel> getSongById(String songId) async {
    try {
      final response = await _dio.get('$_baseUrl/$songId');

      if (response.statusCode == 200) {
        return SongModel.fromJson(response.data['data']['song']);
      }

      throw ApiException(message: 'Failed to fetch song');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Start play session
  Future<String> startPlaySession(String songId) async {
    try {
      final response = await _dio.post('$_baseUrl/$songId/session/start');

      if (response.statusCode == 201) {
        return response.data['data']['sessionId'] as String;
      }

      throw ApiException(message: 'Failed to start play session');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Increment play count
  Future<int> incrementPlayCount(String songId) async {
    try {
      final response = await _dio.post('$_baseUrl/$songId/play');

      if (response.statusCode == 200) {
        return response.data['data']['playCount'] as int;
      }

      throw ApiException(message: 'Failed to increment play count');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
