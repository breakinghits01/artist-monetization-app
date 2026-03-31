import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../features/player/models/song_model.dart';
import 'file_encryption_service.dart';

/// Offline download status for a song
enum OfflineDownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  failed,
}

/// Download progress data
class OfflineDownloadProgress {
  final String songId;
  final double progress; // 0.0 to 1.0
  final OfflineDownloadStatus status;
  final String? error;

  OfflineDownloadProgress({
    required this.songId,
    required this.progress,
    required this.status,
    this.error,
  });
}

/// Manages offline downloads for songs (Spotify-like)
/// - Stores files in app-private encrypted storage (AES-256)
/// - Only this app can decrypt and access downloaded songs
/// - Tracks download states per song
/// - Automatically deleted on app uninstall
class OfflineDownloadManager {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final FileEncryptionService _encryptionService;
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, OfflineDownloadProgress> _downloadProgress = {};
  
  /// Callback to notify state changes
  void Function(String, OfflineDownloadProgress)? onProgressUpdate;

  OfflineDownloadManager({
    required Dio dio,
    FlutterSecureStorage? secureStorage,
    FileEncryptionService? encryptionService,
    this.onProgressUpdate,
  })  : _dio = dio,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _encryptionService = encryptionService ?? FileEncryptionService();

  /// Get app-private directory for offline songs
  Future<Directory> _getOfflineDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory('${appDir.path}/offline_songs');
    
    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }
    
    return offlineDir;
  }

  /// Get metadata file path
  Future<File> _getMetadataFile() async {
    final dir = await _getOfflineDirectory();
    return File('${dir.path}/metadata.json');
  }

  /// Save song metadata (encrypted)
  Future<void> _saveMetadata(String songId, SongModel song) async {
    try {
      final metadataFile = await _getMetadataFile();
      Map<String, dynamic> allMetadata = {};

      // Load existing metadata
      if (await metadataFile.exists()) {
        final decrypted = await _secureStorage.read(key: 'offline_metadata') ?? '{}';
        allMetadata = json.decode(decrypted);
      }

      // Add new song metadata
      allMetadata[songId] = {
        'id': song.id,
        'title': song.title,
        'artist': song.artist,
        'artistId': song.artistId,
        'albumArt': song.albumArt,
        'duration': song.duration.inSeconds,
        'genre': song.genre,
        'audioUrl': song.audioUrl,
        'downloadedAt': DateTime.now().toIso8601String(),
      };

      // Encrypt and save
      final jsonStr = json.encode(allMetadata);
      await _secureStorage.write(key: 'offline_metadata', value: jsonStr);
      await metadataFile.writeAsString('encrypted'); // Marker file
    } catch (e) {
      debugPrint('Error saving metadata: $e');
      rethrow; // Propagate so downloadSong() can mark the download as failed
    }
  }

  /// Load all downloaded songs metadata
  Future<Map<String, dynamic>> _loadMetadata() async {
    try {
      final metadataFile = await _getMetadataFile();
      if (!await metadataFile.exists()) {
        return {};
      }

      final decrypted = await _secureStorage.read(key: 'offline_metadata') ?? '{}';
      return json.decode(decrypted);
    } catch (e) {
      debugPrint('Error loading metadata: $e');
      return {};
    }
  }

  /// Get local file path for a song (encrypted file)
  Future<String> _getLocalFilePath(String songId, String format) async {
    final dir = await _getOfflineDirectory();
    // Use .encrypted extension to indicate encrypted file
    return '${dir.path}/$songId.$format.encrypted';
  }

  /// Check if song is downloaded
  Future<bool> isDownloaded(String songId) async {
    try {
      final metadata = await _loadMetadata();
      if (!metadata.containsKey(songId)) return false;

      final filePath = await _getLocalFilePath(songId, 'mp3');
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      debugPrint('Error checking download status: $e');
      return false;
    }
  }

  /// Get download status for a song
  OfflineDownloadStatus getDownloadStatus(String songId) {
    if (_downloadProgress.containsKey(songId)) {
      return _downloadProgress[songId]!.status;
    }
    return OfflineDownloadStatus.notDownloaded;
  }

  /// Get download progress (0.0 to 1.0)
  double getDownloadProgress(String songId) {
    if (_downloadProgress.containsKey(songId)) {
      return _downloadProgress[songId]!.progress;
    }
    return 0.0;
  }

  /// Download song for offline playback
  Future<bool> downloadSong(SongModel song) async {
    final songId = song.id;

    try {
      // Check if already downloaded
      if (await isDownloaded(songId)) {
        debugPrint('Song already downloaded: $songId');
        return true;
      }

      // Set initial progress
      _updateProgress(songId, 0.0, OfflineDownloadStatus.downloading);

      // Get download URL from API
      debugPrint('🔽 Requesting download URL for song: $songId');
      final response = await _dio.get(
        '/download/song/$songId',
        queryParameters: {'format': 'mp3'},
      );

      debugPrint('📦 Download response status: ${response.statusCode}');
      debugPrint('📦 Download response data: ${response.data}');

      final responseData = response.data;
      if (responseData is! Map || responseData['success'] != true || responseData['data'] == null) {
        final errorMsg = (responseData is Map ? responseData['message'] : null) ?? 'Download failed';
        debugPrint('❌ Download request failed: $errorMsg');
        throw Exception(errorMsg);
      }

      final data = responseData['data'] as Map<String, dynamic>;
      final downloadUrl = data['downloadUrl'];
      
      if (downloadUrl == null || downloadUrl.toString().isEmpty) {
        throw Exception('Download URL is empty');
      }
      
      final fileSize = data['fileSize'] ?? 0;
      debugPrint('✅ Download URL received: $downloadUrl');

      // Get local file path
      final encryptedFilePath = await _getLocalFilePath(songId, 'mp3');
      final tempFilePath = '$encryptedFilePath.temp'; // Temporary unencrypted file
      debugPrint('📁 Saving to: $encryptedFilePath');

      // Create cancel token
      final cancelToken = CancelToken();
      _cancelTokens[songId] = cancelToken;

      // Download file to temporary location first
      debugPrint('⬇️ Starting download to temp file...');
      await _dio.download(
        downloadUrl,
        tempFilePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final progress = total > 0 ? received / total : 0.0;
          _updateProgress(songId, progress * 0.8, OfflineDownloadStatus.downloading); // 80% for download
          if (received % 100000 == 0 || progress == 1.0) {
            debugPrint('📊 Download progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
      );

      debugPrint('✅ Download completed successfully');
      debugPrint('🔒 Encrypting file...');
      
      // Update progress for encryption phase
      _updateProgress(songId, 0.85, OfflineDownloadStatus.downloading);
      
      // Encrypt the downloaded file
      final tempFile = File(tempFilePath);
      final encryptedFile = File(encryptedFilePath);
      
      final encrypted = await _encryptionService.encryptFile(tempFile, encryptedFile);
      
      if (!encrypted) {
        throw Exception('Failed to encrypt file');
      }
      
      debugPrint('✅ File encrypted successfully');
      
      // Delete temporary unencrypted file
      if (await tempFile.exists()) {
        await tempFile.delete();
        debugPrint('🗑️ Temporary file deleted');
      }
      
      _updateProgress(songId, 0.95, OfflineDownloadStatus.downloading);

      // Save metadata
      await _saveMetadata(songId, song);

      // Mark as completed
      _updateProgress(songId, 1.0, OfflineDownloadStatus.downloaded);

      // Cleanup
      _cancelTokens.remove(songId);

      // Confirm download with backend
      try {
        debugPrint('📝 Confirming download with backend...');
        await _dio.post(
          '/download/song/$songId/confirm',
          data: {'format': 'mp3', 'fileSize': fileSize},
        );
        debugPrint('✅ Download confirmed');
      } catch (e) {
        debugPrint('⚠️ Warning: Failed to confirm download: $e');
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error downloading song: $e');
      // Clean up any partial encrypted file to avoid stale/corrupt data
      try {
        final encryptedPath = await _getLocalFilePath(songId, 'mp3');
        final encryptedFile = File(encryptedPath);
        if (await encryptedFile.exists()) {
          await encryptedFile.delete();
          debugPrint('🗑️ Cleaned up partial download: $encryptedPath');
        }
      } catch (cleanupError) {
        debugPrint('⚠️ Cleanup failed: $cleanupError');
      }
      _updateProgress(
        songId,
        0.0,
        OfflineDownloadStatus.failed,
        error: e.toString(),
      );
      _cancelTokens.remove(songId);
      return false;
    }
  }

  /// Cancel ongoing download
  void cancelDownload(String songId) {
    if (_cancelTokens.containsKey(songId)) {
      _cancelTokens[songId]!.cancel('User cancelled');
      _cancelTokens.remove(songId);
      _downloadProgress.remove(songId);
    }
  }

  /// Delete downloaded song
  Future<bool> deleteDownload(String songId) async {
    try {
      // Delete file
      final filePath = await _getLocalFilePath(songId, 'mp3');
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from metadata
      final metadata = await _loadMetadata();
      metadata.remove(songId);
      final jsonStr = json.encode(metadata);
      await _secureStorage.write(key: 'offline_metadata', value: jsonStr);

      // Clear progress
      _downloadProgress.remove(songId);

      return true;
    } catch (e) {
      debugPrint('Error deleting download: $e');
      return false;
    }
  }

  /// Get local file path if downloaded, null otherwise
  Future<String?> getLocalFilePath(String songId) async {
    if (!await isDownloaded(songId)) return null;
    return await _getLocalFilePath(songId, 'mp3');
  }

  /// Get decrypted file for playback
  /// This creates a temporary decrypted file for the audio player
  Future<String?> getDecryptedFilePath(String songId) async {
    try {
      if (!await isDownloaded(songId)) {
        debugPrint('⚠️ Song not downloaded: $songId');
        return null;
      }

      final encryptedPath = await _getLocalFilePath(songId, 'mp3');
      final encryptedFile = File(encryptedPath);

      if (!await encryptedFile.exists()) {
        debugPrint('⚠️ Encrypted file not found: $encryptedPath');
        return null;
      }

      // Create temp directory for decrypted playback files
      final tempDir = await _getTempPlaybackDirectory();
      final decryptedPath = '${tempDir.path}/$songId.mp3';
      final decryptedFile = File(decryptedPath);

      // Check if already decrypted
      if (await decryptedFile.exists()) {
        debugPrint('✅ Using cached decrypted file: $decryptedPath');
        return decryptedPath;
      }

      debugPrint('🔓 Decrypting file for playback...');
      final decrypted = await _encryptionService.decryptFile(encryptedFile, decryptedFile);

      if (!decrypted) {
        debugPrint('❌ Failed to decrypt file');
        return null;
      }

      debugPrint('✅ File decrypted for playback: $decryptedPath');
      return decryptedPath;
    } catch (e) {
      debugPrint('❌ Error getting decrypted file: $e');
      return null;
    }
  }

  /// Get temporary playback directory
  Future<Directory> _getTempPlaybackDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final playbackDir = Directory('${tempDir.path}/playback_cache');
    
    if (!await playbackDir.exists()) {
      await playbackDir.create(recursive: true);
    }
    
    return playbackDir;
  }

  /// Clear temporary playback cache
  Future<void> clearPlaybackCache() async {
    try {
      final playbackDir = await _getTempPlaybackDirectory();
      if (await playbackDir.exists()) {
        await playbackDir.delete(recursive: true);
        debugPrint('🗑️ Playback cache cleared');
      }
    } catch (e) {
      debugPrint('❌ Error clearing playback cache: $e');
    }
  }

  /// Fast check: is the temporary decrypted playback file already cached?
  /// Does NOT perform decryption — only checks disk existence.
  /// Use this to avoid blocking the UI thread with unnecessary decryption work.
  Future<bool> hasCachedDecryptedFile(String songId) async {
    try {
      final tempDir = await _getTempPlaybackDirectory();
      return await File('${tempDir.path}/$songId.mp3').exists();
    } catch (e) {
      return false;
    }
  }

  /// Get all downloaded songs.
  /// Verifies each encrypted file still exists on disk and purges stale metadata
  /// entries whose files were removed (e.g. OS cleared app storage).
  Future<List<SongModel>> getDownloadedSongs() async {
    try {
      final metadata = await _loadMetadata();
      final songs = <SongModel>[];
      final staleIds = <String>[];

      for (final entry in metadata.entries) {
        final songId = entry.key;
        final data = entry.value;

        // Verify the encrypted file still exists on disk
        final filePath = await _getLocalFilePath(songId, 'mp3');
        if (!await File(filePath).exists()) {
          staleIds.add(songId);
          debugPrint('⚠️ Stale metadata (file missing): $songId');
          continue;
        }

        songs.add(SongModel(
          id: data['id'],
          title: data['title'],
          artist: data['artist'] ?? 'Unknown',
          artistId: data['artistId'],
          albumArt: data['albumArt'],
          duration: Duration(seconds: data['duration'] ?? 0),
          audioUrl: data['audioUrl'],
          genre: data['genre'],
        ));
      }

      // Purge stale metadata so SecureStorage stays in sync with disk
      if (staleIds.isNotEmpty) {
        for (final id in staleIds) {
          metadata.remove(id);
        }
        await _secureStorage.write(
          key: 'offline_metadata',
          value: json.encode(metadata),
        );
        debugPrint('🗑️ Purged ${staleIds.length} stale metadata entries');
      }

      return songs;
    } catch (e) {
      debugPrint('Error getting downloaded songs: $e');
      return [];
    }
  }

  /// Clear all downloads
  Future<void> clearAllDownloads() async {
    try {
      final dir = await _getOfflineDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      await _secureStorage.delete(key: 'offline_metadata');
      _downloadProgress.clear();
      _cancelTokens.clear();
    } catch (e) {
      debugPrint('Error clearing downloads: $e');
    }
  }

  /// Update progress and notify listeners
  void _updateProgress(
    String songId,
    double progress,
    OfflineDownloadStatus status, {
    String? error,
  }) {
    final progressData = OfflineDownloadProgress(
      songId: songId,
      progress: progress,
      status: status,
      error: error,
    );
    
    _downloadProgress[songId] = progressData;
    
    // Notify StateNotifier (safe even if callback is null or notifier disposed)
    try {
      onProgressUpdate?.call(songId, progressData);
    } catch (e) {
      // Ignore errors if notifier is disposed during callback
      debugPrint('Progress update callback error (likely disposed): $e');
    }
  }

  /// Get total downloads count
  Future<int> getDownloadCount() async {
    final metadata = await _loadMetadata();
    return metadata.length;
  }

  /// Get total size of downloads
  Future<int> getTotalDownloadSize() async {
    try {
      final metadata = await _loadMetadata();
      int totalSize = 0;

      for (final songId in metadata.keys) {
        final filePath = await _getLocalFilePath(songId, 'mp3');
        final file = File(filePath);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error calculating download size: $e');
      return 0;
    }
  }
}
