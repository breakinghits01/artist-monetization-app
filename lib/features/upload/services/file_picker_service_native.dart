import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
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
        withData: true, // CRITICAL: This loads file bytes
      );
      
      debugPrint('[Native] File picker result: ${result != null}');
      
      if (result == null || result.files.isEmpty) {
        debugPrint('[Native] No file selected');
        return null;
      }
      
      final file = result.files.first;
      debugPrint('[Native] File info - Name: ${file.name}, Path: ${file.path}, Size: ${file.size}, Has bytes: ${file.bytes != null}');
      
      // Read bytes if not available from picker
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        debugPrint('[Native] Reading file bytes from path...');
        try {
          final fileHandle = File(file.path!);
          bytes = await fileHandle.readAsBytes();
          debugPrint('[Native] Successfully read ${bytes.length} bytes');
        } catch (e) {
          debugPrint('[Native] Error reading file bytes: $e');
        }
      }
      
      if (file.path == null) {
        debugPrint('[Native] Error: File path is null');
        return null;
      }
      
      if (bytes == null) {
        debugPrint('[Native] Error: Could not read file bytes');
        return null;
      }
      
      return FilePickResult(
        name: file.name,
        path: file.path!,
        size: file.size,
        bytes: bytes,
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
