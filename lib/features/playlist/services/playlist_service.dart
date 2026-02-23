import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/config/api_config.dart';
import '../models/playlist_model.dart';

class PlaylistService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  /// Get user's playlists
  Future<List<PlaylistModel>> getUserPlaylists(String userId) async {
    try {
      debugPrint('📋 Fetching playlists for user: $userId');
      
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/v1/playlists/user/$userId',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConfig.tempToken}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final playlistsJson = data['playlists'] as List;
        
        final playlists = playlistsJson.map((json) {
          // Convert MongoDB _id to id
          if (json['_id'] != null) {
            json['id'] = json['_id'];
          }
          return PlaylistModel.fromJson(json);
        }).toList();
        
        debugPrint('✅ Loaded ${playlists.length} playlists');
        return playlists;
      }

      throw Exception('Failed to load playlists');
    } on DioException catch (e) {
      debugPrint('❌ Failed to fetch playlists: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      rethrow; // Re-throw instead of returning empty list
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      rethrow; // Re-throw instead of returning empty list
    }
  }

  /// Get playlist by ID with songs
  Future<PlaylistModel?> getPlaylistById(String playlistId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/v1/playlists/$playlistId',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConfig.tempToken}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data']['playlist'];
        if (data['_id'] != null) {
          data['id'] = data['_id'];
        }
        return PlaylistModel.fromJson(data);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Failed to fetch playlist: $e');
      return null;
    }
  }

  /// Create new playlist
  Future<PlaylistModel?> createPlaylist({
    required String name,
    String? description,
    String? coverImage,
    bool isPublic = true,
  }) async {
    try {
      debugPrint('📋 Creating playlist: $name');
      
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/v1/playlists',
        data: {
          'name': name,
          if (description != null) 'description': description,
          if (coverImage != null) 'coverImage': coverImage,
          'isPublic': isPublic,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConfig.tempToken}',
          },
        ),
      );

      if (response.statusCode == 201) {
        final data = response.data['data']['playlist'];
        if (data['_id'] != null) {
          data['id'] = data['_id'];
        }
        debugPrint('✅ Playlist created successfully');
        return PlaylistModel.fromJson(data);
      }

      throw Exception('Failed to create playlist');
    } on DioException catch (e) {
      debugPrint('❌ Failed to create playlist: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      rethrow;
    }
  }

  /// Add song to playlist
  Future<bool> addSongToPlaylist(String playlistId, String songId) async {
    try {
      debugPrint('📋 Adding song $songId to playlist $playlistId');
      
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/v1/playlists/$playlistId/songs/$songId',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConfig.tempToken}',
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Song added to playlist');
        return true;
      }

      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        // Song already in playlist
        debugPrint('ℹ️ Song already in playlist');
        throw Exception('Song already in this playlist');
      }
      debugPrint('❌ Failed to add song: ${e.message}');
      rethrow;
    }
  }

  /// Remove song from playlist
  Future<bool> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      final response = await _dio.delete(
        '${ApiConfig.baseUrl}/api/v1/playlists/$playlistId/songs/$songId',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConfig.tempToken}',
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Song removed from playlist');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Failed to remove song: $e');
      return false;
    }
  }

  /// Delete playlist
  Future<bool> deletePlaylist(String playlistId) async {
    try {
      final response = await _dio.delete(
        '${ApiConfig.baseUrl}/api/v1/playlists/$playlistId',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConfig.tempToken}',
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Playlist deleted');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Failed to delete playlist: $e');
      return false;
    }
  }
}
