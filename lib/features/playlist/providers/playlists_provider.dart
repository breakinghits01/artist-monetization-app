import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final PlaylistService _service;
  final Ref _ref;

  PlaylistsNotifier(this._ref)
      : _service = PlaylistService(),
        super(PlaylistsState());

  /// Load user's playlists
  Future<void> loadPlaylists() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get current user ID
      final currentUser = _ref.read(currentUserProvider);
      final userId = currentUser?['_id'] ?? currentUser?['id'];

      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not logged in',
        );
        return;
      }

      debugPrint('📋 Loading playlists for user: $userId');
      final playlists = await _service.getUserPlaylists(userId);

      state = state.copyWith(
        playlists: playlists,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('❌ Error loading playlists: $e');
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
        state = state.copyWith(
          playlists: [...state.playlists, playlist],
        );
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
