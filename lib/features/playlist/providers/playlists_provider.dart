import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/playlist_model.dart';
import '../services/playlist_service.dart';

// State class
class PlaylistsState {
  final List<PlaylistModel> playlists;
  final bool isLoading;
  final String? error;

  PlaylistsState({
    this.playlists = const [],
    this.isLoading = false,
    this.error,
  });

  PlaylistsState copyWith({
    List<PlaylistModel>? playlists,
    bool? isLoading,
    String? error,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier class
class PlaylistsNotifier extends StateNotifier<PlaylistsState> {
  static const String _cacheKey = 'playlists_cache';
  final PlaylistService _service;
  final Ref _ref;

  PlaylistsNotifier(this._ref)
      : _service = PlaylistService(),
        super(PlaylistsState());

  /// Load cached playlists from local storage
  Future<List<PlaylistModel>> _loadCachedPlaylists(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString('${_cacheKey}_$userId');
      
      if (cacheData != null) {
        final List<dynamic> jsonList = json.decode(cacheData);
        final playlists = jsonList.map((json) => PlaylistModel.fromJson(json)).toList();
        debugPrint('📦 Loaded ${playlists.length} playlists from cache');
        return playlists;
      }
    } catch (e) {
      debugPrint('⚠️ Cache load failed: $e');
    }
    return [];
  }

  /// Save playlists to local cache
  Future<void> _savePlaylists(List<PlaylistModel> playlists, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = playlists.map((p) => p.toJson()).toList();
      await prefs.setString('${_cacheKey}_$userId', json.encode(jsonList));
      debugPrint('💾 Cached ${playlists.length} playlists');
    } catch (e) {
      debugPrint('⚠️ Cache save failed: $e');
    }
  }

  /// Load user's playlists (offline-first with network sync)
  Future<void> loadPlaylists() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Get current user ID
      final currentUser = _ref.read(currentUserProvider);
      final userId = currentUser?['_id'] ?? currentUser?['id'];
      
      debugPrint('🔍 [PLAYLIST DEBUG] Current user data: $currentUser');
      debugPrint('🔍 [PLAYLIST DEBUG] Extracted userId: $userId');
      debugPrint('🔍 [PLAYLIST DEBUG] Username: ${currentUser?['username']}');

      if (userId == null) {
        debugPrint('❌ [PLAYLIST DEBUG] No userId found - user not logged in');
        state = state.copyWith(
          isLoading: false,
          error: 'User not logged in',
        );
        return;
      }

      // Step 1: Load from cache first (instant UI)
      final cached = await _loadCachedPlaylists(userId);
      if (cached.isNotEmpty) {
        state = state.copyWith(
          playlists: cached,
          isLoading: false,
        );
        debugPrint('📦 Showing ${cached.length} cached playlists');
      } else {
        // No cache, but stop loading spinner
        debugPrint('⚠️ No cached playlists found');
        state = state.copyWith(isLoading: false);
      }

      // Step 2: Try network update (background sync)
      try {
        debugPrint('📋 Loading playlists from network for user: $userId');
        final fresh = await _service.getUserPlaylists(userId);
        
        debugPrint('🔍 [PLAYLIST DEBUG] Received ${fresh.length} playlists from API');
        if (fresh.isNotEmpty) {
          debugPrint('🔍 [PLAYLIST DEBUG] First playlist: ${fresh.first.name}');
          debugPrint('🔍 [PLAYLIST DEBUG] First playlist userId: ${fresh.first.userId}');
        }
        
        // ALWAYS update with network data (even if empty)
        // This ensures we show the correct data for the current user
        // and don't keep stale cache from a different user session
        await _savePlaylists(fresh, userId);
        
        state = state.copyWith(
          playlists: fresh,
          isLoading: false,
        );
        debugPrint('✅ Network sync complete: ${fresh.length} playlists');
      } catch (networkError) {
        debugPrint('⚠️ Network sync failed: $networkError');
        
        // Keep cached data if network fails
        if (cached.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            error: 'Offline - no cached playlists available',
          );
        } else {
          debugPrint('✅ Using cached data (offline mode)');
          // Already set loading to false above
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading playlists: $e');
      // Ensure loading is always set to false
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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
      final playlist = await _service.createPlaylist(
        name: name,
        description: description,
        coverImage: coverImage,
        isPublic: isPublic,
      );

      if (playlist != null) {
        // Add to local state
        final updatedPlaylists = [...state.playlists, playlist];
        state = state.copyWith(
          playlists: updatedPlaylists,
        );
        
        // Update cache
        final currentUser = _ref.read(currentUserProvider);
        final userId = currentUser?['_id'] ?? currentUser?['id'];
        if (userId != null) {
          await _savePlaylists(updatedPlaylists, userId);
        }
      }

      return playlist;
    } catch (e) {
      debugPrint('❌ Error creating playlist: $e');
      rethrow;
    }
  }

  /// Get playlist by ID with full details
  Future<PlaylistModel?> getPlaylistById(String playlistId) async {
    try {
      final playlist = await _service.getPlaylistById(playlistId);
      return playlist;
    } catch (e) {
      debugPrint('❌ Error getting playlist: $e');
      return null;
    }
  }

  /// Add song to playlist
  Future<bool> addSongToPlaylist(String playlistId, String songId) async {
    try {
      final success = await _service.addSongToPlaylist(playlistId, songId);

      if (success) {
        // Update local state - add song to playlist's songs array
        final updatedPlaylists = state.playlists.map((playlist) {
          if (playlist.id == playlistId) {
            return playlist.copyWith(
              songs: [...playlist.songs, songId],
              songCount: playlist.songCount + 1,
            );
          }
          return playlist;
        }).toList();

        state = state.copyWith(playlists: updatedPlaylists);
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error adding song to playlist: $e');
      rethrow;
    }
  }

  /// Remove song from playlist
  Future<bool> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      final success = await _service.removeSongFromPlaylist(playlistId, songId);

      if (success) {
        // Update local state - remove song from playlist's songs array
        final updatedPlaylists = state.playlists.map((playlist) {
          if (playlist.id == playlistId) {
            final updatedSongs = playlist.songs.where((id) => id != songId).toList();
            return playlist.copyWith(
              songs: updatedSongs,
              songCount: updatedSongs.length,
            );
          }
          return playlist;
        }).toList();

        state = state.copyWith(playlists: updatedPlaylists);
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error removing song from playlist: $e');
      return false;
    }
  }

  /// Delete playlist
  Future<bool> deletePlaylist(String playlistId) async {
    try {
      final success = await _service.deletePlaylist(playlistId);

      if (success) {
        // Remove from local state
        final updatedPlaylists = state.playlists.where((p) => p.id != playlistId).toList();
        state = state.copyWith(playlists: updatedPlaylists);
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error deleting playlist: $e');
      return false;
    }
  }

  /// Check if song is in playlist
  bool isSongInPlaylist(String playlistId, String songId) {
    final playlist = state.playlists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => PlaylistModel(
        id: '',
        userId: '',
        name: '',
        songs: [],
      ),
    );

    return playlist.songs.contains(songId);
  }
}

// Provider
final playlistsProvider = StateNotifierProvider<PlaylistsNotifier, PlaylistsState>((ref) {
  return PlaylistsNotifier(ref);
});
