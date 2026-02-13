import 'dart:typed_data';

/// Represents an upload session with progress tracking
class UploadSession {
  final String id;
  final String fileName;
  final int fileSize;
  final String fileType;
  final String filePath;
  final Uint8List? fileBytes; // Add bytes for web duration extraction
  final String uploadStatus;
  final double uploadProgress;
  final String? tempStoragePath;
  final String? finalAudioUrl;
  final String? error;
  final DateTime? createdAt;
  final DateTime? completedAt;

  const UploadSession({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.filePath,
    this.fileBytes,
    this.uploadStatus = 'initiated',
    this.uploadProgress = 0.0,
    this.tempStoragePath,
    this.finalAudioUrl,
    this.error,
    this.createdAt,
    this.completedAt,
  });

  UploadSession copyWith({
    String? id,
    String? fileName,
    int? fileSize,
    String? fileType,
    String? filePath,
    Uint8List? fileBytes,
    String? uploadStatus,
    double? uploadProgress,
    String? tempStoragePath,
    String? finalAudioUrl,
    String? error,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return UploadSession(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      filePath: filePath ?? this.filePath,
      fileBytes: fileBytes ?? this.fileBytes,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      tempStoragePath: tempStoragePath ?? this.tempStoragePath,
      finalAudioUrl: finalAudioUrl ?? this.finalAudioUrl,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Upload status enum
enum UploadStatus {
  initiated,
  validating,
  uploading,
  processing,
  completed,
  failed,
  cancelled,
}
