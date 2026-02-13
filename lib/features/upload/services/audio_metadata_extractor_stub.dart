import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Stub implementation for non-web platforms
Future<int?> getDurationFromBytesImpl(Uint8List bytes, String mimeType) async {
  debugPrint('⚠️ Audio duration extraction not supported on this platform');
  return null;
}
