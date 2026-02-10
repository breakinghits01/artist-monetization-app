import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'file_picker_service.dart';

/// Native-specific file picker implementation using file_picker package
class FilePickerServiceNative implements FilePickerService {
  @override
  Future<FilePickResult?> pickAudioFile() async {
    try {
      debugPrint('[Native] Starting file picker...');
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'flac', 'ogg', 'aac'],
        allowMultiple: false,
        dialogTitle: 'Select Audio File',
      );
      
      debugPrint('[Native] File picker result: ${result != null}');
      
      if (result == null || result.files.isEmpty) {
        debugPrint('[Native] No file selected');
        return null;
      }
      
      final file = result.files.first;
      debugPrint('[Native] File info - Name: ${file.name}, Path: ${file.path}, Size: ${file.size}');
      
      if (file.path == null) {
        debugPrint('[Native] Error: File path is null');
        return null;
      }
      
      return FilePickResult(
        name: file.name,
        path: file.path!,
        size: file.size,
        bytes: file.bytes,
      );
    } catch (e, stackTrace) {
      debugPrint('[Native] Error in pickAudioFile: $e');
      debugPrint('[Native] Stack trace: $stackTrace');
      return null;
    }
  }
}

/// Factory to create the native implementation
FilePickerService createFilePickerService() => FilePickerServiceNative();
