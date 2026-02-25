import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/storage_service.dart';

/// Share state
class ShareState {
  final bool isLoading;
  final String? error;

  const ShareState({
    this.isLoading = false,
    this.error,
  });

  ShareState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return ShareState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Share provider
final shareProvider = StateNotifierProvider<ShareNotifier, ShareState>(
  (ref) => ShareNotifier(),
);

class ShareNotifier extends StateNotifier<ShareState> {
  final Dio _dio = Dio();

  ShareNotifier() : super(const ShareState());

  /// Track share event
  Future<bool> trackShare(String songId, String platform) async {
    try {
      final token = await StorageService().getAccessToken();
      if (token == null) {
        print('⚠️ No auth token - cannot track share');
        return false;
      }

      state = state.copyWith(isLoading: true);

      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/${ApiConfig.apiVersion}/songs/$songId/share',
        data: {
          'shareType': platform, // 'link', 'whatsapp', 'facebook', 'telegram', 'other'
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 201) {
        print('✅ Share tracked: $songId on $platform');
        state = state.copyWith(isLoading: false, error: null);
        return true;
      }

      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      print('❌ Error tracking share: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to track share',
      );
      return false;
    }
  }

  /// Get share stats for a song
  Future<Map<String, dynamic>?> getShareStats(String songId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/${ApiConfig.apiVersion}/songs/$songId/shares/stats',
      );

      if (response.statusCode == 200) {
        return response.data['stats'];
      }
      return null;
    } catch (e) {
      print('❌ Error getting share stats: $e');
      return null;
    }
  }
}
