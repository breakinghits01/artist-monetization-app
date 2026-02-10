import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'file_picker_service.dart';

/// Web-specific file picker implementation using HTML file input
class FilePickerServiceWeb implements FilePickerService {
  @override
  Future<FilePickResult?> pickAudioFile() async {
    try {
      debugPrint('[Web] Starting file picker...');
      
      // Create file input element
      final input = html.FileUploadInputElement()
        ..accept = 'audio/*,.mp3,.m4a,.wav,.flac,.ogg,.aac';
      
      debugPrint('[Web] Created file input element');
      
      // Trigger file picker dialog
      input.click();
      
      debugPrint('[Web] Clicked file input');
      
      // Wait for file selection
      await input.onChange.first;
      
      debugPrint('[Web] File selected');
      
      final files = input.files;
      if (files == null || files.isEmpty) {
        debugPrint('[Web] No files selected');
        return null;
      }
      
      final file = files[0];
      debugPrint('[Web] File info - Name: ${file.name}, Size: ${file.size}, Type: ${file.type}');
      
      // Read file as bytes
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      
      final bytes = reader.result as Uint8List?;
      debugPrint('[Web] File read complete, bytes: ${bytes?.length}');
      
      return FilePickResult(
        name: file.name,
        path: file.name, // Web doesn't have real paths
        size: file.size,
        bytes: bytes,
      );
    } catch (e, stackTrace) {
      debugPrint('[Web] Error in pickAudioFile: $e');
      debugPrint('[Web] Stack trace: $stackTrace');
      return null;
    }
  }
}

/// Factory to create the web implementation
FilePickerService createFilePickerService() => FilePickerServiceWeb();
