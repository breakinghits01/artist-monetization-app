import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../offline_download_manager.dart';
import '../../features/player/models/song_model.dart';
import 'offline_download_provider.dart';

/// Download state for a playlist
class PlaylistDownloadState {
  final bool isDownloading;
  final double progress; // 0.0 to 1.0
  final int downloadedCount;
  final int totalCount;
  final String? currentSongTitle;
  final String? error;

  PlaylistDownloadState({
    required this.isDownloading,
    this.progress = 0.0,
    this.downloadedCount = 0,
    this.totalCount = 0,
    this.currentSongTitle,
    this.error,
  });

  PlaylistDownloadState copyWith({
    bool? isDownloading,
    double? progress,
    int? downloadedCount,
    int? totalCount,
    String? currentSongTitle,
    String? error,
  }) {
    return PlaylistDownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
      downloadedCount: downloadedCount ?? this.downloadedCount,
      totalCount: totalCount ?? this.totalCount,
      currentSongTitle: currentSongTitle ?? this.currentSongTitle,
      error: error ?? this.error,
    );
  }
}

/// Manages downloading all songs in a playlist
class PlaylistDownloadNotifier extends StateNotifier<Map<String, PlaylistDownloadState>> {
  final OfflineDownloadManager _downloadManager;
  final Ref _ref;

  PlaylistDownloadNotifier(this._downloadManager, this._ref) : super({});

  /// Download all songs in a playlist
  Future<bool> downloadPlaylist(String playlistId, List<SongModel> songs) async {
    if (songs.isEmpty) return false;

    // Filter out already-downloaded songs for accurate progress tracking
    final songsToDownload = <SongModel>[];
    int alreadyDownloadedCount = 0;
    
    for (final song in songs) {
      final isDownloaded = await _downloadManager.isDownloaded(song.id);
      if (isDownloaded) {
        alreadyDownloadedCount++;
      } else {
        songsToDownload.add(song);
      }
    }

    // If all songs already downloaded, return success immediately
    if (songsToDownload.isEmpty) {
      debugPrint('✅ All ${songs.length} songs already downloaded in playlist $playlistId');
      return true;
    }

    debugPrint('📥 Downloading ${songsToDownload.length} new songs ($alreadyDownloadedCount already downloaded)');

    // Initialize state with accurate count (only songs that need downloading)
    state = {
      ...state,
      playlistId: PlaylistDownloadState(
        isDownloading: true,
        totalCount: songsToDownload.length,
        downloadedCount: 0,
        progress: 0.0,
      ),
    };

    int successCount = 0;
    int failedCount = 0;

    for (int i = 0; i < songsToDownload.length; i++) {
      final song = songsToDownload[i];
      
      // Update current song
      state = {
        ...state,
        playlistId: state[playlistId]!.copyWith(
          currentSongTitle: song.title,
          progress: i / songsToDownload.length,
        ),
      };

      // Download song
      final success = await _downloadManager.downloadSong(song);
      
      if (success) {
        successCount++;
      } else {
        failedCount++;
      }

      // Update progress
      state = {
        ...state,
        playlistId: state[playlistId]!.copyWith(
          downloadedCount: successCount,
          progress: (i + 1) / songsToDownload.length,
        ),
      };

      // No need to invalidate - progress callback handles state updates automatically
    }

    // Complete
    state = {
      ...state,
      playlistId: state[playlistId]!.copyWith(
        isDownloading: false,
        progress: 1.0,
        currentSongTitle: null,
        error: failedCount > 0 
            ? 'Failed to download $failedCount song${failedCount > 1 ? 's' : ''}'
            : null,
      ),
    };

    debugPrint('✅ Playlist download complete: $successCount succeeded, $failedCount failed, $alreadyDownloadedCount skipped');
    
    return failedCount == 0;
  }

  /// Cancel playlist download
  void cancelPlaylistDownload(String playlistId, List<SongModel> songs) {
    // Cancel all ongoing downloads
    for (final song in songs) {
      _downloadManager.cancelDownload(song.id);
    }

    // Remove state
    final newState = Map<String, PlaylistDownloadState>.from(state);
    newState.remove(playlistId);
    state = newState;
  }

  /// Check if playlist is fully downloaded
  Future<bool> isPlaylistDownloaded(List<String> songIds) async {
    for (final songId in songIds) {
      final isDownloaded = await _downloadManager.isDownloaded(songId);
      if (!isDownloaded) return false;
    }
    return songIds.isNotEmpty;
  }

  /// Delete all downloaded songs in playlist
  Future<void> deletePlaylistDownloads(List<String> songIds) async {
    for (final songId in songIds) {
      await _downloadManager.deleteDownload(songId);
    }
    _ref.invalidate(offlineDownloadStateProvider);
  }
}

/// Provider for playlist download management
final playlistDownloadProvider = StateNotifierProvider<PlaylistDownloadNotifier, Map<String, PlaylistDownloadState>>((ref) {
  final downloadManager = ref.watch(offlineDownloadManagerProvider);
  return PlaylistDownloadNotifier(downloadManager, ref);
});

/// Provider to check if a specific playlist is downloading
final playlistDownloadStateProvider = Provider.family<PlaylistDownloadState?, String>((ref, playlistId) {
  final allStates = ref.watch(playlistDownloadProvider);
  return allStates[playlistId];
});

/// Provider to check if playlist is fully downloaded (synchronous check)
final playlistDownloadedProvider = Provider.family<bool, List<String>>((ref, songIds) {
  if (songIds.isEmpty) return false;
  
  final downloadedSongIds = ref.watch(offlineDownloadStateProvider).downloadedSongIds;
  
  // Check if all songs in the playlist are in the downloaded set
  for (final songId in songIds) {
    if (!downloadedSongIds.contains(songId)) {
      return false;
    }
  }
  
  return true;
});
