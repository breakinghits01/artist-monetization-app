import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/playlist_model.dart';

/// Provider — uses the app-wide DioClient which already has the auth interceptor.
/// The real JWT is attached automatically to every request; no manual token
/// handling needed anywhere in this service.
final playlistServiceProvider = Provider<PlaylistService>((ref) {
  final dio = ref.watch(dioProvider);
  return PlaylistService(dio);
});

class PlaylistService {
  final Dio _dio;

  PlaylistService(this._dio);

  // ─── Playlists ─────────────────────────────────────────────────────────────

  /// Fetch all playlists owned by [userId].
  Future<List<PlaylistModel>> getUserPlaylists(String userId) async {
    try {
      debugPrint('📋 Fetching playlists for user: $userId');
      final response = await _dio.get('/playlists/user/$userId');

      final playlistsJson = response.data['data']['playlists'] as List;
      final playlists = playlistsJson.map((json) {
        if (json['_id'] != null) json['id'] = json['_id'];
        return PlaylistModel.fromJson(json);
      }).toList();

      debugPrint('✅ Loaded ${playlists.length} playlists');
      return playlists;
    } on DioException catch (e) {
      debugPrint('❌ Failed to fetch playlists: ${e.response?.data}');
      rethrow;
    }
  }

  /// Fetch a single playlist by ID (includes songs).
  Future<PlaylistModel?> getPlaylistById(String playlistId) async {
    try {
      final response = await _dio.get('/playlists/$playlistId');
      final data = response.data['data']['playlist'];
      if (data['_id'] != null) data['id'] = data['_id'];
      return PlaylistModel.fromJson(data);
    } on DioException catch (e) {
      debugPrint('❌ Failed to fetch playlist: ${e.response?.data}');
      return null;
    }
  }

  /// Create a new playlist.
  Future<PlaylistModel?> createPlaylist({
    required String name,
    String? description,
    String? coverImage,
    bool isPublic = true,
  }) async {
    try {
      debugPrint('📋 Creating playlist: $name');
      final response = await _dio.post(
        '/playlists',
        data: {
          'name': name,
          if (description != null) 'description': description,
          if (coverImage != null) 'coverImage': coverImage,
          'isPublic': isPublic,
        },
      );

      final data = response.data['data']['playlist'];
      if (data['_id'] != null) data['id'] = data['_id'];
      debugPrint('✅ Playlist created successfully');
      return PlaylistModel.fromJson(data);
    } on DioException catch (e) {
      debugPrint('❌ Failed to create playlist: ${e.response?.data}');
      rethrow;
    }
  }

  // ─── Songs ─────────────────────────────────────────────────────────────────

  /// Add [songId] to [playlistId].
  /// Throws an [Exception] with a user-facing message if the song is already present.
  Future<bool> addSongToPlaylist(String playlistId, String songId) async {
    try {
      debugPrint('📋 Adding song $songId to playlist $playlistId');
      await _dio.post('/playlists/$playlistId/songs/$songId');
      debugPrint('✅ Song added to playlist');
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        debugPrint('ℹ️ Song already in playlist');
        throw Exception('Song already in this playlist');
      }
      debugPrint('❌ Failed to add song: ${e.response?.data}');
      rethrow;
    }
  }

  /// Remove [songId] from [playlistId].
  Future<bool> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      await _dio.delete('/playlists/$playlistId/songs/$songId');
      debugPrint('✅ Song removed from playlist');
      return true;
    } on DioException catch (e) {
      debugPrint('❌ Failed to remove song: ${e.response?.data}');
      return false;
    }
  }

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  /// Permanently delete [playlistId].
  Future<bool> deletePlaylist(String playlistId) async {
    try {
      await _dio.delete('/playlists/$playlistId');
      debugPrint('✅ Playlist deleted');
      return true;
    } on DioException catch (e) {
      debugPrint('❌ Failed to delete playlist: ${e.response?.data}');
      return false;
    }
  }
}
