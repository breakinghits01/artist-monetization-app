import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/storage_service.dart';

/// Like state for a song
class LikeState {
  final bool isLiked;
  final bool isDisliked;
  final int likeCount;
  final int dislikeCount;
  final bool isLoading;

  LikeState({
    required this.isLiked,
    required this.isDisliked,
    required this.likeCount,
    required this.dislikeCount,
    this.isLoading = false,
  });

  LikeState copyWith({
    bool? isLiked,
    bool? isDisliked,
    int? likeCount,
    int? dislikeCount,
    bool? isLoading,
  }) {
    return LikeState(
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Provider for managing song likes
class LikeNotifier extends StateNotifier<LikeState> {
  final String songId;
  final Dio _dio = Dio();

  LikeNotifier(this.songId)
      : super(LikeState(
          isLiked: false,
          isDisliked: false,
          likeCount: 0,
          dislikeCount: 0,
        )) {
    _init();
  }

  Future<void> _init() async {
    // Fetch current reaction status
    try {
      final token = await StorageService().getAccessToken();
      if (token == null) return;

      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/${ApiConfig.apiVersion}/songs/$songId/reaction',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        state = state.copyWith(
          isLiked: data['reaction'] == 'like',
          isDisliked: data['reaction'] == 'dislike',
        );
      }
    } catch (e) {
      print('Error fetching reaction: $e');
    }

    // Fetch stats
    await _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/${ApiConfig.apiVersion}/songs/$songId/stats',
      );

      if (response.statusCode == 200) {
        final stats = response.data['stats'];
        state = state.copyWith(
          likeCount: stats['likeCount'] ?? 0,
          dislikeCount: stats['dislikeCount'] ?? 0,
        );
      }
    } catch (e) {
      print('Error fetching stats: $e');
    }
  }

  Future<void> toggleLike() async {
    final token = await StorageService().getAccessToken();
    if (token == null) {
      print('❌ No auth token - user must be logged in');
      return;
    }

    // Optimistic update with toggle behavior
    final wasLiked = state.isLiked;
    final newLikeCount = wasLiked ? state.likeCount - 1 : state.likeCount + 1;
    
    print('🔄 Toggle like: wasLiked=$wasLiked, newCount=$newLikeCount');
    
    state = state.copyWith(
      isLiked: !wasLiked, // Toggle: true -> false, false -> true
      isDisliked: false,
      likeCount: newLikeCount,
      isLoading: true,
    );

    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/${ApiConfig.apiVersion}/songs/$songId/like',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('✅ Like API response: ${response.statusCode}');
      print('📦 API data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        // Backend returns 'reaction': 'like' or null, not 'liked': true/false
        final reaction = data['reaction'];
        final liked = reaction == 'like';
        
        print('📊 Server state: reaction=$reaction, isLiked=$liked');
        
        // Update from server response
        state = state.copyWith(
          isLiked: liked,
          isDisliked: reaction == 'dislike',
          isLoading: false,
        );
        
        // Refresh full stats to ensure accuracy
        await _fetchStats();
      }
    } catch (e) {
      print('❌ Error toggling like: $e');
      // Revert on error
      state = state.copyWith(
        isLiked: wasLiked,
        likeCount: wasLiked ? state.likeCount + 1 : state.likeCount - 1,
        isLoading: false,
      );
    }
  }

  Future<void> toggleDislike() async {
    final token = await StorageService().getAccessToken();
    if (token == null) {
      print('❌ No auth token - user must be logged in');
      return;
    }

    // Optimistic update with toggle behavior
    final wasDisliked = state.isDisliked;
    final newDislikeCount = wasDisliked ? state.dislikeCount - 1 : state.dislikeCount + 1;
    
    print('🔄 Toggle dislike: wasDisliked=$wasDisliked, newCount=$newDislikeCount');
    
    state = state.copyWith(
      isLiked: false, // Clear like if disliking
      isDisliked: !wasDisliked, // Toggle: true -> false, false -> true
      dislikeCount: newDislikeCount,
      isLoading: true,
    );

    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/${ApiConfig.apiVersion}/songs/$songId/dislike',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('✅ Dislike API response: ${response.statusCode}');
      print('📦 API data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        // Backend returns 'reaction': 'dislike' or null
        final reaction = data['reaction'];
        final disliked = reaction == 'dislike';
        
        print('📊 Server state: reaction=$reaction, isDisliked=$disliked');
        
        // Update from server response
        state = state.copyWith(
          isDisliked: disliked,
          isLiked: reaction == 'like',
          isLoading: false,
        );
        
        // Refresh full stats to ensure accuracy
        await _fetchStats();
      }
    } catch (e) {
      print('❌ Error toggling dislike: $e');
      // Revert on error
      state = state.copyWith(
        isDisliked: wasDisliked,
        dislikeCount: wasDisliked ? state.dislikeCount + 1 : state.dislikeCount - 1,
        isLoading: false,
      );
    }
  }
}

/// Provider factory for song likes
final likeProvider = StateNotifierProvider.family<LikeNotifier, LikeState, String>(
  (ref, songId) => LikeNotifier(songId),
);
