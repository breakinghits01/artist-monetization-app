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
  /// Per-playlist cancellation flags. Set by [cancelPlaylistDownload] and
  /// checked at the start of every loop iteration in [downloadPlaylist].
  final Map<String, bool> _cancelled = {};

  PlaylistDownloadNotifier(this._downloadManager, this._ref) : super({});

  /// Download all songs in a playlist.
  Future<bool> downloadPlaylist(String playlistId, List<SongModel> songs) async {
    if (songs.isEmpty) return false;

    // Prevent a second parallel download for the same playlist.
    if (state[playlistId]?.isDownloading == true) {
      debugPrint('⚠️ Playlist $playlistId already downloading — ignoring duplicate request');
      return false;
    }

    // Clear any stale cancellation flag from a previous run.
    _cancelled.remove(playlistId);

    // Use the already-hydrated Riverpod state for the pre-check.
    // This avoids calling isDownloaded() (SecureStorage read + File.exists)
    // once per song — for a 200-song playlist that eliminates ~200 async
    // crypto reads before the first real download even starts.
    // Edge-case: if the notifier hasn't finished its initial load yet, the
    // set may be empty. That's safe — _doDownloadSong still checks isDownloaded()
    // internally and skips files that are already on disk.
    final downloadedIds = _ref.read(offlineDownloadStateProvider).downloadedSongIds;
    final songsToDownload =
        songs.where((s) => !downloadedIds.contains(s.id)).toList();
    final alreadyDownloadedCount = songs.length - songsToDownload.length;

    // If all songs already downloaded, return success immediately.
    if (songsToDownload.isEmpty) {
      debugPrint('✅ All ${songs.length} songs already downloaded in playlist $playlistId');
      return true;
    }

    debugPrint('📥 Downloading ${songsToDownload.length} new songs ($alreadyDownloadedCount already downloaded)');

    // Initialize state.
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
      // Check cancellation flag BEFORE starting each song so cancellation
      // takes effect at the next song boundary (the current song, if any,
      // is cancelled via its CancelToken in cancelPlaylistDownload).
      if (_cancelled[playlistId] == true) {
        debugPrint('🚫 Playlist download cancelled at song ${i + 1}/${songsToDownload.length}');
        break;
      }

      final song = songsToDownload[i];

      // Guard: state entry may have been removed by cancelPlaylistDownload.
      if (!mounted || !state.containsKey(playlistId)) break;

      state = {
        ...state,
        playlistId: state[playlistId]!.copyWith(
          currentSongTitle: song.title,
          progress: i / songsToDownload.length,
        ),
      };

      final success = await _downloadManager.downloadSong(song);

      // Re-check cancellation and state after each await — state may have
      // been removed while the download was in progress.
      if (_cancelled[playlistId] == true ||
          !mounted ||
          !state.containsKey(playlistId)) {
        break;
      }

      if (success) {
        successCount++;
      } else {
        failedCount++;
      }

      state = {
        ...state,
        playlistId: state[playlistId]!.copyWith(
          downloadedCount: successCount,
          progress: (i + 1) / songsToDownload.length,
        ),
      };
    }

    // Clean up cancellation flag and check whether the user cancelled.
    final wasCancelled = _cancelled.remove(playlistId) ?? false;

    // Only write the final "done" state when not cancelled — if cancelled,
    // cancelPlaylistDownload has already removed the state entry.
    if (!wasCancelled && mounted && state.containsKey(playlistId)) {
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
    }

    debugPrint(
      '✅ Playlist download complete: $successCount succeeded, '
      '$failedCount failed, $alreadyDownloadedCount skipped'
      '${wasCancelled ? " (cancelled)" : ""}',
    );

    return !wasCancelled && failedCount == 0;
  }

  /// Cancel a playlist download in progress.
  void cancelPlaylistDownload(String playlistId, List<SongModel> songs) {
    // Signal the download loop to stop at the next song boundary.
    _cancelled[playlistId] = true;

    // Cancel the CancelToken for whichever song is currently downloading.
    // Songs that haven't started yet don't have tokens, but the loop will
    // exit via the _cancelled flag check before reaching them.
    for (final song in songs) {
      _downloadManager.cancelDownload(song.id);
    }

    // Remove state immediately so the UI stops showing a progress bar.
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

/// Provider to check if playlist is fully downloaded (synchronous check).
/// Uses a comma-separated String key instead of `List<String>`.
/// Dart's List uses reference equality, so two identical List instances would
/// be treated as different Riverpod family keys — causing cache misses and leaks.
final playlistDownloadedProvider = Provider.family<bool, String>((ref, songIdsKey) {
  if (songIdsKey.isEmpty) return false;

  final downloadedSongIds = ref.watch(offlineDownloadStateProvider).downloadedSongIds;

  for (final songId in songIdsKey.split(',')) {
    if (songId.isNotEmpty && !downloadedSongIds.contains(songId)) {
      return false;
    }
  }

  return true;
});
