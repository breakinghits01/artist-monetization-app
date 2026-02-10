import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Validates audio files for upload
class FileValidator {
  // Allowed audio file extensions
  static const List<String> allowedExtensions = [
    'mp3',
    'm4a',
    'wav',
    'flac',
    'ogg',
    'aac',
  ];

  // Allowed MIME types
  static const List<String> allowedMimeTypes = [
    'audio/mpeg',
    'audio/mp4',
    'audio/wav',
    'audio/x-wav',
    'audio/flac',
    'audio/ogg',
    'audio/aac',
    'audio/x-m4a',
  ];

  // File size limits
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB
  static const int minFileSize = 100 * 1024; // 100KB

  /// Validate an audio file
  static Future<ValidationResult> validate(String filePath) async {
    try {
      // For web platform, we can't access file system directly
      // Just validate the file extension from the name
      if (kIsWeb) {
        final extension = path.extension(filePath).toLowerCase().replaceFirst('.', '');
        if (extension.isEmpty) {
          return ValidationResult.error('File has no extension');
        }
        
        if (!allowedExtensions.contains(extension)) {
          return ValidationResult.error(
            'Invalid file format. Allowed formats: ${allowedExtensions.join(', ').toUpperCase()}',
          );
        }
        
        // For web, we'll assume valid file - actual validation happens on upload
        return ValidationResult.success(
          fileSize: 0, // Unknown for web until uploaded
          mimeType: 'audio/$extension',
          extension: extension,
        );
      }
      
      // Native platform validation
      final file = File(filePath);

      // Check if file exists
      if (!await file.exists()) {
        return ValidationResult.error('File does not exist');
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        final sizeMB = (maxFileSize / (1024 * 1024)).toStringAsFixed(0);
        return ValidationResult.error('File too large. Maximum size: ${sizeMB}MB');
      }
      if (fileSize < minFileSize) {
        return ValidationResult.error('File too small. Minimum size: 100KB');
      }

      // Check file extension
      final extension = path.extension(filePath).toLowerCase().replaceFirst('.', '');
      if (!allowedExtensions.contains(extension)) {
        return ValidationResult.error(
          'Invalid file format. Allowed formats: ${allowedExtensions.join(', ').toUpperCase()}',
        );
      }

      // Check MIME type
      final mimeType = lookupMimeType(filePath);
      if (mimeType == null || !allowedMimeTypes.contains(mimeType)) {
        return ValidationResult.error('Invalid audio file type');
      }

      return ValidationResult.success(
        fileSize: fileSize,
        mimeType: mimeType,
        extension: extension,
      );
    } catch (e) {
      return ValidationResult.error('Error validating file: ${e.toString()}');
    }
  }

  /// Get file size in human-readable format
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final String? error;
  final int? fileSize;
  final String? mimeType;
  final String? extension;

  ValidationResult._({
    required this.isValid,
    this.error,
    this.fileSize,
    this.mimeType,
    this.extension,
  });

  factory ValidationResult.success({
    required int fileSize,
    required String mimeType,
    required String extension,
  }) {
    return ValidationResult._(
      isValid: true,
      fileSize: fileSize,
      mimeType: mimeType,
      extension: extension,
    );
  }

  factory ValidationResult.error(String message) {
    return ValidationResult._(
      isValid: false,
      error: message,
    );
  }
}

/// Local storage helper for uploaded files
class LocalStorageHelper {
  /// Get the upload directory
  static Future<Directory> getUploadDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Local storage not available on web platform');
    }
    
    final appDir = await getApplicationDocumentsDirectory();
    final uploadDir = Directory('${appDir.path}/uploads');
    
    if (!await uploadDir.exists()) {
      await uploadDir.create(recursive: true);
    }
    
    return uploadDir;
  }

  /// Save file to local storage
  static Future<String> saveFile(String sourcePath, String fileName) async {
    if (kIsWeb) {
      // For web, we can't save to local file system
      // Just return the source path (file name)
      return sourcePath;
    }
    
    try {
      final uploadDir = await getUploadDirectory();
      final file = File(sourcePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(fileName);
      final baseName = path.basenameWithoutExtension(fileName);
      final newFileName = '${timestamp}_$baseName$extension';
      final newPath = '${uploadDir.path}/$newFileName';
      
      await file.copy(newPath);
      return newPath;
    } catch (e) {
      debugPrint('Error saving file: $e');
      rethrow;
    }
  }

  /// Delete file from storage
  static Future<void> deleteFile(String filePath) async {
    if (kIsWeb) return; // No-op on web
    
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  /// Get all uploaded files
  static Future<List<FileSystemEntity>> getUploadedFiles() async {
    if (kIsWeb) return []; // No local files on web
    
    try {
      final uploadDir = await getUploadDirectory();
      return uploadDir.list().toList();
    } catch (e) {
      debugPrint('Error listing files: $e');
      return [];
    }
  }

  /// Calculate storage used
  static Future<int> getStorageUsed() async {
    if (kIsWeb) return 0; // No storage tracking on web
    
    try {
      final files = await getUploadedFiles();
      int totalSize = 0;
      
      for (var entity in files) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating storage: $e');
      return 0;
    }
  }
}
