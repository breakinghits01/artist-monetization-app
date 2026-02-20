import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../features/discover/models/song_model.dart';

class DownloadFormat {
  final String format;
  final int? bitrate;
  final int? fileSize;
  final String quality;

  DownloadFormat({
    required this.format,
    this.bitrate,
    this.fileSize,
    required this.quality,
  });

  factory DownloadFormat.fromJson(Map<String, dynamic> json) {
    return DownloadFormat(
      format: json['format'] ?? '',
      bitrate: json['bitrate'],
      fileSize: json['fileSize'],
      quality: json['quality'] ?? '',
    );
  }

  String get fileSizeFormatted {
    if (fileSize == null) return 'Unknown';
    final mb = fileSize! / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} MB';
  }
}

class DownloadHistory {
  final String id;
  final SongModel song;
  final String format;
  final int fileSize;
  final DateTime downloadedAt;

  DownloadHistory({
    required this.id,
    required this.song,
    required this.format,
    required this.fileSize,
    required this.downloadedAt,
  });

  factory DownloadHistory.fromJson(Map<String, dynamic> json) {
    return DownloadHistory(
      id: json['_id'] ?? '',
      song: SongModel.fromJson(json['songId'] ?? {}),
      format: json['format'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      downloadedAt: DateTime.parse(json['downloadedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class DownloadProgress {
  final String songId;
  final String songTitle;
  final String format;
  final double progress; // 0.0 to 1.0
  final int downloaded;
  final int total;
  final String status; // downloading, completed, failed, paused, cancelled
  final String? error;

  DownloadProgress({
    required this.songId,
    required this.songTitle,
    required this.format,
    required this.progress,
    required this.downloaded,
    required this.total,
    required this.status,
    this.error,
  });

  int get downloadedBytes => downloaded;
  int get fileSize => total;

  String get downloadedFormatted {
    final mb = downloaded / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} MB';
  }

  String get totalFormatted {
    final mb = total / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} MB';
  }
}

class DownloadService {
  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, DownloadProgress> _downloadProgress = {};

  DownloadService(this._dio);

  Map<String, DownloadProgress> get downloadProgress => Map.unmodifiable(_downloadProgress);

  /// Get available download formats for a song
  Future<List<DownloadFormat>> getAvailableFormats(String songId) async {
    try {
      final response = await _dio.get('/download/song/$songId/formats');
      
      if (response.data['success'] == true && response.data['data'] != null) {
        final formats = (response.data['data']['formats'] as List)
            .map((f) => DownloadFormat.fromJson(f))
            .toList();
        return formats;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting available formats: $e');
      return [];
    }
  }

  /// Download a song in specified format
  Future<String?> downloadSong({
    required String songId,
    required String songTitle,
    required String format,
    Function(double)? onProgress,
  }) async {
    try {
      // Get download URL from API
      final response = await _dio.get(
        '/download/song/$songId',
        queryParameters: {'format': format},
      );

      if (response.data['success'] != true || response.data['data'] == null) {
        throw Exception(response.data['message'] ?? 'Download failed');
      }

      final downloadUrl = response.data['data']['downloadUrl'];
      final fileSize = response.data['data']['fileSize'] ?? 0;

      // Create download progress tracker
      _downloadProgress[songId] = DownloadProgress(
        songId: songId,
        songTitle: songTitle,
        format: format,
        progress: 0.0,
        downloaded: 0,
        total: fileSize,
        status: 'downloading',
      );

      // Get download directory
      final directory = await _getDownloadDirectory();
      final sanitizedTitle = songTitle.replaceAll(RegExp(r'[^\w\s-]'), '');
      final filePath = '${directory.path}/$sanitizedTitle.$format';

      // Create cancel token for this download
      final cancelToken = CancelToken();
      _cancelTokens[songId] = cancelToken;

      // Download file
      await _dio.download(
        downloadUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final progress = total > 0 ? received / total : 0.0;
          
          _downloadProgress[songId] = DownloadProgress(
            songId: songId,
            songTitle: songTitle,
            format: format,
            progress: progress,
            downloaded: received,
            total: total,
            status: 'downloading',
          );
          
          if (onProgress != null) {
            onProgress(progress);
          }
        },
      );

      // Mark as completed
      _downloadProgress[songId] = DownloadProgress(
        songId: songId,
        songTitle: songTitle,
        format: format,
        progress: 1.0,
        downloaded: fileSize,
        total: fileSize,
        status: 'completed',
      );

      // Clean up cancel token
      _cancelTokens.remove(songId);

      // Confirm download with backend (track in history)
      try {
        await _dio.post(
          '/download/song/$songId/confirm',
          data: {'format': format, 'fileSize': fileSize},
        );
      } catch (e) {
        debugPrint('Warning: Failed to confirm download tracking: $e');
        // Don't fail the download if tracking fails
      }

      return filePath;
    } catch (e) {
      debugPrint('Error downloading song: $e');
      
      // Mark as failed
      if (_downloadProgress.containsKey(songId)) {
        _downloadProgress[songId] = DownloadProgress(
          songId: _downloadProgress[songId]!.songId,
          songTitle: _downloadProgress[songId]!.songTitle,
          format: _downloadProgress[songId]!.format,
          progress: _downloadProgress[songId]!.progress,
          downloaded: _downloadProgress[songId]!.downloaded,
          total: _downloadProgress[songId]!.total,
          status: 'failed',
          error: e.toString(),
        );
      }
      
      return null;
    }
  }

  /// Cancel download
  void cancelDownload(String songId) {
    if (_cancelTokens.containsKey(songId)) {
      _cancelTokens[songId]!.cancel('User cancelled download');
      _cancelTokens.remove(songId);
      
      if (_downloadProgress.containsKey(songId)) {
        _downloadProgress[songId] = DownloadProgress(
          songId: _downloadProgress[songId]!.songId,
          songTitle: _downloadProgress[songId]!.songTitle,
          format: _downloadProgress[songId]!.format,
          progress: _downloadProgress[songId]!.progress,
          downloaded: _downloadProgress[songId]!.downloaded,
          total: _downloadProgress[songId]!.total,
          status: 'cancelled',
        );
      }
    }
  }

  /// Get download history
  Future<List<DownloadHistory>> getDownloadHistory({int limit = 50}) async {
    try {
      final response = await _dio.get(
        '/download/history',
        queryParameters: {'limit': limit},
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final history = (response.data['data']['history'] as List)
            .map((h) => DownloadHistory.fromJson(h))
            .toList();
        return history;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting download history: $e');
      return [];
    }
  }

  /// Check if user can download (handles rate limiting)
  Future<bool> canDownload(String songId) async {
    try {
      final formats = await getAvailableFormats(songId);
      return formats.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking download permission: $e');
      return false;
    }
  }

  /// Get download directory based on platform
  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Use external storage on Android
      final directory = await getExternalStorageDirectory();
      final downloadDir = Directory('${directory!.path}/Downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return downloadDir;
    } else if (Platform.isIOS) {
      // Use documents directory on iOS
      return await getApplicationDocumentsDirectory();
    } else {
      // Use downloads directory on desktop
      return await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    }
  }

  /// Check if a song is downloaded locally
  Future<String?> getLocalFilePath(String songId, String songTitle) async {
    try {
      final directory = await _getDownloadDirectory();
      final sanitizedTitle = songTitle.replaceAll(RegExp(r'[^\w\s-]'), '');
      
      // Check for MP3 first (most common format)
      final mp3Path = '${directory.path}/$sanitizedTitle.mp3';
      if (await File(mp3Path).exists()) {
        return mp3Path;
      }
      
      // Check for other formats
      final formats = ['wav', 'flac', 'aac', 'm4a'];
      for (final format in formats) {
        final path = '${directory.path}/$sanitizedTitle.$format';
        if (await File(path).exists()) {
          return path;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error checking local file: $e');
      return null;
    }
  }

  /// Check if a song is downloaded (returns format if found)
  Future<String?> isDownloaded(String songId, String songTitle) async {
    final filePath = await getLocalFilePath(songId, songTitle);
    if (filePath == null) return null;
    
    // Extract format from file path
    final extension = filePath.split('.').last;
    return extension;
  }

  /// Clear completed downloads from progress tracker
  void clearCompleted() {
    _downloadProgress.removeWhere((key, value) => value.status == 'completed');
  }

  void dispose() {
    // Cancel all ongoing downloads
    for (var token in _cancelTokens.values) {
      token.cancel('Service disposed');
    }
    _cancelTokens.clear();
    _dio.close();
  }
}
