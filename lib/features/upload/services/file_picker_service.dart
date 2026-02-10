import 'package:flutter/foundation.dart';

/// Abstract file picker result
class FilePickResult {
  final String name;
  final String path;
  final int? size;
  final Uint8List? bytes;

  FilePickResult({
    required this.name,
    required this.path,
    this.size,
    this.bytes,
  });
}

/// Abstract file picker service
abstract class FilePickerService {
  Future<FilePickResult?> pickAudioFile();
}
