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
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(minutes: 5), // 5 min for large files
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(minutes: 5),
    ),
  );
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

  /// Upload file with progress tracking (fast, no artificial delays)
  Stream<double> uploadWithProgress(UploadSession session, String filePath) async* {
    try {
      // Fast progress simulation - no delays
      yield 50.0; // Started
      
      // For web, we skip local storage save
      // For native platforms, save to local storage
      if (!kIsWeb) {
        final savedPath = await LocalStorageHelper.saveFile(filePath, session.fileName);
        debugPrint('File saved to: $savedPath');
      } else {
        debugPrint('Web upload prepared: ${session.fileName}');
      }
      
      yield 100.0; // Complete immediately
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  /// Process uploaded audio (fast, no delays)
  Future<void> processAudio(UploadSession session) async {
    try {
      // In production, this would do actual processing
      // For now, just log completion immediately
      debugPrint('Audio ready for upload: ${session.fileName}');
    } catch (e) {
      debugPrint('Error processing audio: $e');
      rethrow;
    }
  }

  /// Create song from upload session - Upload file + metadata in ONE request
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
        debugPrint('🎵 Extracting duration from ${session.fileBytes!.length} bytes');
        final extractedDuration = await AudioMetadataExtractor.getDurationFromBytes(
          session.fileBytes!,
          session.fileType,
        );
        
        if (extractedDuration != null && extractedDuration > 0) {
          duration = extractedDuration;
          debugPrint('✅ Extracted duration: $duration seconds');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Duration extraction failed, using default: $e');
    }

    try {
      if (session.fileBytes == null) {
        throw Exception('No file bytes available for upload');
      }

      // Get auth token
      final token = await _storage.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated. Please login first.');
      }
      
      debugPrint('📤 Uploading song with metadata in ONE request...');
      
      // Create form data with audio file + all metadata
      final formData = FormData.fromMap({
        'audio': MultipartFile.fromBytes(
          session.fileBytes!,
          filename: session.fileName,
          contentType: MediaType.parse(session.fileType),
        ),
        'title': metadata.title,
        'genre': metadata.genre ?? 'Pop',
        'price': metadata.price.toString(),
        'description': metadata.description ?? '',
        'exclusive': metadata.exclusive.toString(),
        'duration': duration.toString(), // Add duration field
      });
      
      // Single upload request to /songs/upload
      final response = await _dio.post(
        ApiConfig.uploadEndpoint,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        debugPrint('✅ Song uploaded successfully!');
        
        // Extract song from response
        final song = data['data']?['song'] ?? data['song'] ?? data['data'] ?? data;
        
        return {
          'id': song['_id'] ?? song['id'],
          'title': song['title'] ?? metadata.title,
          'genre': song['genre'] ?? metadata.genre,
          'description': song['description'] ?? metadata.description,
          'price': (song['price'] ?? metadata.price).toInt(),
          'audioUrl': song['audioUrl'] ?? '',
          'coverArt': song['coverArt'] ?? 'https://via.placeholder.com/300',
          'duration': duration,
          'exclusive': song['exclusive'] ?? metadata.exclusive,
          'playCount': (song['playCount'] ?? 0).toInt(),
          'createdAt': song['createdAt'] ?? DateTime.now().toIso8601String(),
        };
      } else {
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ Upload failed: ${e.message}');
      debugPrint('❌ Response: ${e.response?.data}');
      throw Exception('Upload failed: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      throw Exception('Upload failed: $e');
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
}
