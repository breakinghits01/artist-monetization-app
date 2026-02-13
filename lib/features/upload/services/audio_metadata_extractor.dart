import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// Conditional import for web
import 'audio_metadata_extractor_stub.dart'
    if (dart.library.html) 'audio_metadata_extractor_web.dart';

/// Extract audio metadata from file
class AudioMetadataExtractor {
  /// Get audio duration in seconds from file bytes
  static Future<int?> getDurationFromBytes(Uint8List bytes, String mimeType) async {
    if (!kIsWeb) {
      debugPrint('⚠️ getDurationFromBytes only works on web platform');
      return null;
    }

    return await getDurationFromBytesImpl(bytes, mimeType);
  }
  
  /// Get audio duration in seconds from file path (legacy, for non-web)
  static Future<int?> getDuration(String filePath) async {
    debugPrint('⚠️ getDuration with filePath is deprecated on web, use getDurationFromBytes');
    return null;
  }
}
