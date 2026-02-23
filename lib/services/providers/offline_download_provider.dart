import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../offline_download_manager.dart';
import '../../features/player/models/song_model.dart';
import '../../core/config/api_config.dart';
import '../../core/services/storage_service.dart';

/// Dio provider for HTTP requests
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: '${ApiConfig.baseUrl}/api/${ApiConfig.apiVersion}',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  
  // Add auth interceptor
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await StorageService().getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
  ));
  
  return dio;
});

/// Provider for offline download manager
final offlineDownloadManagerProvider = Provider<OfflineDownloadManager>((ref) {
  final dio = ref.watch(dioProvider);
  
  return OfflineDownloadManager(
    dio: dio,
  );
});

/// Download state for all songs
class OfflineDownloadState {
  final Map<String, OfflineDownloadProgress> downloadStates;
  final Set<String> downloadedSongIds;

  OfflineDownloadState({
    this.downloadStates = const {},
    this.downloadedSongIds = const {},
  });

  OfflineDownloadState copyWith({
    Map<String, OfflineDownloadProgress>? downloadStates,
    Set<String>? downloadedSongIds,
  }) {
    return OfflineDownloadState(
      downloadStates: downloadStates ?? this.downloadStates,
      downloadedSongIds: downloadedSongIds ?? this.downloadedSongIds,
    );
  }
}

/// Notifier for managing download states
class OfflineDownloadStateNotifier extends StateNotifier<OfflineDownloadState> {
  final OfflineDownloadManager _downloadManager;

  OfflineDownloadStateNotifier(this._downloadManager)
      : super(OfflineDownloadState()) {
    // Hook up callback to receive progress updates
    _downloadManager.onProgressUpdate = _onProgressUpdate;
    _loadDownloadedSongs();
  }
  
  @override
  void dispose() {
    // Clean up callback to prevent memory leaks
    _downloadManager.onProgressUpdate = null;
    super.dispose();
  }
  
  /// Called by OfflineDownloadManager when progress changes
  void _onProgressUpdate(String songId, OfflineDownloadProgress progress) {
    // Only update if notifier is still mounted
    if (!mounted) return;
    updateProgress(songId, progress);
  }

  /// Load all downloaded songs on init
  Future<void> _loadDownloadedSongs() async {
    final songs = await _downloadManager.getDownloadedSongs();
    final songIds = songs.map((s) => s.id).toSet();
    if (!mounted) return; // Check if still mounted before updating state
    state = state.copyWith(downloadedSongIds: songIds);
  }

  /// Update progress for a song
  void updateProgress(String songId, OfflineDownloadProgress progress) {
    // Safety check: don't update state if notifier is disposed
    if (!mounted) return;
    
    final newStates = Map<String, OfflineDownloadProgress>.from(state.downloadStates);
    newStates[songId] = progress;

    final newDownloadedIds = Set<String>.from(state.downloadedSongIds);
    if (progress.status == OfflineDownloadStatus.downloaded) {
      newDownloadedIds.add(songId);
    } else if (progress.status == OfflineDownloadStatus.failed) {
      newDownloadedIds.remove(songId);
    }

    state = state.copyWith(
      downloadStates: newStates,
      downloadedSongIds: newDownloadedIds,
    );
  }

  /// Download a song
  Future<bool> downloadSong(SongModel song) async {
    final success = await _downloadManager.downloadSong(song);
    // No need to reload - progress callback handles state updates
    return success;
  }

  /// Delete a downloaded song
  Future<bool> deleteDownload(String songId) async {
    final success = await _downloadManager.deleteDownload(songId);
    if (success) {
      final newStates = Map<String, OfflineDownloadProgress>.from(state.downloadStates);
      newStates.remove(songId);

      final newDownloadedIds = Set<String>.from(state.downloadedSongIds);
      newDownloadedIds.remove(songId);

      state = state.copyWith(
        downloadStates: newStates,
        downloadedSongIds: newDownloadedIds,
      );
    }
    return success;
  }

  /// Cancel ongoing download
  void cancelDownload(String songId) {
    _downloadManager.cancelDownload(songId);
    
    final newStates = Map<String, OfflineDownloadProgress>.from(state.downloadStates);
    newStates.remove(songId);

    state = state.copyWith(downloadStates: newStates);
  }

  /// Check if song is downloaded
  bool isDownloaded(String songId) {
    return state.downloadedSongIds.contains(songId);
  }

  /// Get download status
  OfflineDownloadStatus getDownloadStatus(String songId) {
    if (state.downloadStates.containsKey(songId)) {
      return state.downloadStates[songId]!.status;
    }
    return isDownloaded(songId)
        ? OfflineDownloadStatus.downloaded
        : OfflineDownloadStatus.notDownloaded;
  }

  /// Get download progress (0.0 to 1.0)
  double getDownloadProgress(String songId) {
    if (state.downloadStates.containsKey(songId)) {
      return state.downloadStates[songId]!.progress;
    }
    return isDownloaded(songId) ? 1.0 : 0.0;
  }

  /// Get local file path if downloaded
  Future<String?> getLocalFilePath(String songId) async {
    if (!isDownloaded(songId)) return null;
    return await _downloadManager.getLocalFilePath(songId);
  }

  /// Get decrypted file path for playback
  Future<String?> getDecryptedFilePath(String songId) async {
    if (!isDownloaded(songId)) return null;
    return await _downloadManager.getDecryptedFilePath(songId);
  }

  /// Clear playback cache (temporary decrypted files)
  Future<void> clearPlaybackCache() async {
    await _downloadManager.clearPlaybackCache();
  }

  /// Get all downloaded songs
  Future<List<SongModel>> getDownloadedSongs() async {
    return await _downloadManager.getDownloadedSongs();
  }

  /// Clear all downloads
  Future<void> clearAllDownloads() async {
    await _downloadManager.clearAllDownloads();
    state = OfflineDownloadState();
  }

  /// Get download statistics
  Future<Map<String, dynamic>> getDownloadStats() async {
    final count = await _downloadManager.getDownloadCount();
    final size = await _downloadManager.getTotalDownloadSize();
    
    return {
      'count': count,
      'totalSize': size,
      'totalSizeMB': (size / (1024 * 1024)).toStringAsFixed(2),
    };
  }
}

/// Provider for download state notifier
final offlineDownloadStateProvider =
    StateNotifierProvider<OfflineDownloadStateNotifier, OfflineDownloadState>((ref) {
  final manager = ref.watch(offlineDownloadManagerProvider);
  return OfflineDownloadStateNotifier(manager);
});

/// Provider to check if a specific song is downloaded
final isSongDownloadedProvider = Provider.family<bool, String>((ref, songId) {
  final state = ref.watch(offlineDownloadStateProvider);
  return state.downloadedSongIds.contains(songId);
});

/// Provider to get download status for a specific song
final songDownloadStatusProvider = Provider.family<OfflineDownloadStatus, String>((ref, songId) {
  final state = ref.watch(offlineDownloadStateProvider);
  if (state.downloadStates.containsKey(songId)) {
    return state.downloadStates[songId]!.status;
  }
  return state.downloadedSongIds.contains(songId)
      ? OfflineDownloadStatus.downloaded
      : OfflineDownloadStatus.notDownloaded;
});

/// Provider to get download progress for a specific song
final songDownloadProgressProvider = Provider.family<double, String>((ref, songId) {
  final state = ref.watch(offlineDownloadStateProvider);
  if (state.downloadStates.containsKey(songId)) {
    return state.downloadStates[songId]!.progress;
  }
  return state.downloadedSongIds.contains(songId) ? 1.0 : 0.0;
});
