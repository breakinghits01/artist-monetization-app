import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/upload_session.dart';
import '../models/song_metadata.dart';
import 'file_validator.dart';

/// Upload service for handling file uploads
class UploadService {
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

  /// Create song from upload session (mock implementation)
  Future<Map<String, dynamic>> createSong(
    UploadSession session,
    SongMetadata metadata, {
    bool isDraft = false,
  }) async {
    try {
      // In a real app, this would:
      // 1. Upload audio file to server/CDN
      // 2. Upload cover art if provided
      // 3. Send metadata to backend API with draft status
      // 4. Get song ID and details back
      
      // For now, return mock data
      final song = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': metadata.title,
        'genre': metadata.genre ?? 'Pop',
        'description': metadata.description ?? '',
        'price': metadata.price,
        'audioUrl': session.tempStoragePath ?? session.filePath,
        'coverArt': metadata.coverArtUrl,
        'duration': 180, // Mock 3 minutes
        'exclusive': metadata.exclusive,
        'isDraft': isDraft,
        'status': isDraft ? 'draft' : 'published',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      debugPrint('Song created (${isDraft ? 'draft' : 'published'}): ${song['id']}');
      return song;
    } catch (e) {
      debugPrint('Error creating song: $e');
      rethrow;
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
