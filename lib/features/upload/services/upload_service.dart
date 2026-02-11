import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../models/upload_session.dart';
import '../models/song_metadata.dart';
import 'file_validator.dart';

/// Upload service for handling file uploads
class UploadService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  
  /// Validate and initiate upload
  Future<UploadSession> initiateUpload(String filePath) async {
    try {
      // Validate file
      final validation = await FileValidator.validate(filePath);
      
      if (!validation.isValid) {
        throw Exception(validation.error);
      }

      // Create upload session
      // On web, filePath is just the filename, so basename works fine
      final fileName = path.basename(filePath);
      final session = UploadSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: fileName,
        fileSize: validation.fileSize ?? 0, // Use 0 if null (web platform)
        fileType: validation.mimeType ?? 'audio/unknown', // Fallback MIME type
        filePath: filePath,
        uploadStatus: 'initiated',
        createdAt: DateTime.now(),
      );

      return session;
    } catch (e) {
      debugPrint('Error initiating upload: $e');
      rethrow;
    }
  }

  /// Upload file with progress tracking
  Stream<double> uploadWithProgress(UploadSession session, String filePath) async* {
    try {
      // Simulate upload progress (in real app, this would be actual upload)
      // For web or local storage, we'll just simulate progress
      
      // Simulate progress chunks
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        yield (i + 1) * 10.0; // Progress percentage
      }
      
      // For web, we skip local storage save
      // For native platforms, save to local storage
      if (!kIsWeb) {
        final savedPath = await LocalStorageHelper.saveFile(filePath, session.fileName);
        debugPrint('File saved to: $savedPath');
      } else {
        debugPrint('Web upload completed for: ${session.fileName}');
      }
      
      yield 100.0; // Complete
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  /// Process uploaded audio (simulate)
  Future<void> processAudio(UploadSession session) async {
    try {
      // In a real app, this would:
      // 1. Transcode audio to web-optimized format
      // 2. Extract metadata (duration, bitrate, etc.)
      // 3. Generate waveform
      // 4. Create thumbnail
      
      // Simulate processing time
      await Future.delayed(const Duration(seconds: 2));
      
      debugPrint('Audio processing completed for: ${session.fileName}');
    } catch (e) {
      debugPrint('Error processing audio: $e');
      rethrow;
    }
  }

  /// Create song from upload session - MUST save to database
  Future<Map<String, dynamic>> createSong(
    UploadSession session,
    SongMetadata metadata, {
    bool isDraft = false,
  }) async {
    // Prepare song data for backend (using actual schema)
    final songData = {
      'title': metadata.title,
      'genre': metadata.genre ?? 'Pop',
      'description': metadata.description ?? '',
      'price': metadata.price,
      'duration': 180, // TODO: Extract from actual audio file
      'audioUrl': session.tempStoragePath ?? session.filePath,
      'coverArt': metadata.coverArtUrl ?? 'https://via.placeholder.com/300',
      'exclusive': metadata.exclusive ?? false,
      // Note: Backend schema doesn't have 'status' field yet
    };

    debugPrint('📤 Uploading song to database: ${songData['title']}');

    try {
      // POST to backend API - this is REQUIRED
      final response = await _dio.post(
        ApiConfig.songsEndpoint,
        data: songData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConfig.tempToken}',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        debugPrint('✅ Song saved to database successfully!');
        
        // Extract song from response
        final song = data['data']?['song'] ?? data['song'] ?? data['data'] ?? data;
        
        return {
          'id': song['_id'] ?? song['id'],
          'title': song['title'] ?? '',
          'genre': song['genre'] ?? 'Pop',
          'description': song['description'] ?? '',
          'price': (song['price'] ?? 10).toInt(),
          'audioUrl': song['audioUrl'] ?? '',
          'coverArt': song['coverArt'] ?? 'https://via.placeholder.com/300',
          'duration': (song['duration'] ?? 180).toInt(),
          'exclusive': song['exclusive'] ?? false,
          'playCount': (song['playCount'] ?? 0).toInt(),
          'createdAt': song['createdAt'] ?? DateTime.now().toIso8601String(),
        };
      } else {
        throw Exception('Backend returned status ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ Failed to save to database: ${e.message}');
      debugPrint('❌ Response: ${e.response?.data}');
      throw Exception('Cannot save song - backend is required. Please check your API connection.');
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      throw Exception('Failed to save song: $e');
    }
  }


  /// Cancel upload and cleanup
  Future<void> cancelUpload(UploadSession session) async {
    try {
      // Delete temporary file if exists
      if (session.tempStoragePath != null) {
        await LocalStorageHelper.deleteFile(session.tempStoragePath!);
      }
      
      debugPrint('Upload cancelled: ${session.id}');
    } catch (e) {
      debugPrint('Error cancelling upload: $e');
    }
  }

  /// Get upload status (for polling)
  Future<UploadSession> getUploadStatus(String sessionId) async {
    // In a real app, this would query the backend
    // For now, return mock status
    throw UnimplementedError('Status checking not implemented for local storage');
  }
}
