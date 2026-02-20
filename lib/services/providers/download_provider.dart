import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../download_service.dart';
import '../../core/api/api_client.dart';

/// Download service provider
final downloadServiceProvider = Provider<DownloadService>((ref) {
  final dio = ref.watch(dioProvider);
  return DownloadService(dio);
});

/// Download progress provider
final downloadProgressProvider = StreamProvider.autoDispose<Map<String, DownloadProgress>>((ref) {
  final downloadService = ref.watch(downloadServiceProvider);
  
  // Listen to download progress changes
  return Stream.periodic(const Duration(milliseconds: 100), (_) {
    return downloadService.downloadProgress;
  });
});

/// Download history provider
final downloadHistoryProvider = FutureProvider.autoDispose<List<DownloadHistory>>((ref) async {
  final downloadService = ref.watch(downloadServiceProvider);
  return await downloadService.getDownloadHistory();
});

/// Available formats provider for a specific song
final availableFormatsProvider = FutureProvider.autoDispose.family<List<DownloadFormat>, String>((ref, songId) async {
  final downloadService = ref.watch(downloadServiceProvider);
  return await downloadService.getAvailableFormats(songId);
});
