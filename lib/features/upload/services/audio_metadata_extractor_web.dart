import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Web implementation for audio metadata extraction
Future<int?> getDurationFromBytesImpl(Uint8List bytes, String mimeType) async {
  try {
    debugPrint('🎵 Extracting duration from ${bytes.length} bytes, type: $mimeType');
    
    // Create blob from bytes
    final blob = html.Blob([bytes], mimeType);
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    debugPrint('🔗 Created blob URL: $blobUrl');
    
    final audio = html.AudioElement();
    audio.src = blobUrl;
    audio.preload = 'metadata';
    
    final completer = Completer<int?>();
    Timer? timeoutTimer;
    
    void onMetadataLoaded(html.Event event) {
      timeoutTimer?.cancel();
      html.Url.revokeObjectUrl(blobUrl); // Clean up blob URL
      
      if (audio.duration != null && !audio.duration!.isNaN && !audio.duration!.isInfinite) {
        final durationSec = audio.duration!.toInt();
        debugPrint('✅ Extracted audio duration: $durationSec seconds');
        completer.complete(durationSec);
      } else {
        debugPrint('⚠️ Invalid duration value');
        completer.complete(null);
      }
    }
    
    void onError(html.Event event) {
      timeoutTimer?.cancel();
      html.Url.revokeObjectUrl(blobUrl); // Clean up blob URL
      debugPrint('❌ Error loading audio metadata');
      completer.complete(null);
    }
    
    audio.onLoadedMetadata.listen(onMetadataLoaded);
    audio.onError.listen(onError);
    
    // Increase timeout to 10 seconds for large files
    timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        html.Url.revokeObjectUrl(blobUrl); // Clean up blob URL
        debugPrint('⏰ Timeout extracting audio duration after 10 seconds');
        completer.complete(null);
      }
    });
    
    return await completer.future;
  } catch (e) {
    debugPrint('❌ Error extracting audio duration: $e');
    return null;
  }
}
