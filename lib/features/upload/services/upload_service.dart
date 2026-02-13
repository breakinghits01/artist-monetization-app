import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/storage_service.dart';
import '../models/upload_session.dart';
import '../models/song_metadata.dart';
import 'file_validator.dart';
import 'audio_metadata_extractor.dart';

/// Upload service for handling file uploads
class UploadService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final StorageService _storage = StorageService();
  
  /// Validate and initiate upload
  Future<UploadSession> initiateUpload(String filePath, {Uint8List? fileBytes}) async {
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
        fileBytes: fileBytes, // Store bytes for duration extraction
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
    // Extract audio duration from the file bytes
    int duration = metadata.duration ?? 240; // Default fallback
    
    try {
      // On web, we can extract duration from bytes
      if (kIsWeb && session.fileBytes != null) {
        debugPrint('🎵 Attempting to extract duration from ${session.fileBytes!.length} bytes');
        final extractedDuration = await AudioMetadataExtractor.getDurationFromBytes(
          session.fileBytes!,
          session.fileType,
        );
        
        if (extractedDuration != null && extractedDuration > 0) {
          duration = extractedDuration;
          debugPrint('✅ Using extracted duration: $duration seconds (${duration ~/ 60}:${(duration % 60).toString().padLeft(2, '0')})');
        } else {
          debugPrint('⚠️ Could not extract duration, using default: $duration seconds');
        }
      } else {
        debugPrint('⚠️ No file bytes available for duration extraction, using default: $duration seconds');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to extract duration: $e');
    }
    
    // Upload the audio file first
    String audioUrl;
    try {
      if (session.fileBytes != null) {
        debugPrint('📤 Uploading audio file to server...');
        audioUrl = await _uploadAudioFile(session.fileBytes!, session.fileName, session.fileType);
        debugPrint('✅ Audio file uploaded: $audioUrl');
      } else {
        throw Exception('No file bytes available for upload');
      }
    } catch (e) {
      debugPrint('❌ Failed to upload audio file: $e');
      throw Exception('Failed to upload audio file: $e');
    }
    
    // Prepare song data for backend (using actual schema)
    final songData = {
      'title': metadata.title,
      'genre': metadata.genre ?? 'Pop',
      'description': metadata.description ?? '',
      'price': metadata.price,
      'duration': duration,
      'audioUrl': audioUrl, // Use the uploaded file URL
      'coverArt': metadata.coverArtUrl ?? 'https://via.placeholder.com/300',
      'exclusive': metadata.exclusive,
      // Note: Backend schema doesn't have 'status' field yet
    };

    debugPrint('📤 Uploading song to database: ${songData['title']}');

    try {
      // Get actual user token from storage
      final token = await _storage.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated. Please login first.');
      }
      
      debugPrint('🔐 Using auth token for upload');
      
      // POST to backend API - this is REQUIRED
      final response = await _dio.post(
        ApiConfig.songsEndpoint,
        data: songData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
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
      // Cleanup logic here if needed
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
  
  /// Upload audio file to server and return the URL
  Future<String> _uploadAudioFile(Uint8List fileBytes, String fileName, String mimeType) async {
    try {
      // Get auth token
      final token = await _storage.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      // Create form data
      final formData = FormData.fromMap({
        'audio': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      });
      
      // Upload to server
      final response = await _dio.post(
        '${ApiConfig.songsEndpoint}/upload',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final fileUrl = response.data['data']['url'] as String;
        // Return full URL
        return fileUrl;
      } else {
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error uploading audio file: $e');
      rethrow;
    }
  }
}
