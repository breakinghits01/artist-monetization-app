import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/storage_service.dart';

/// Comment model
class CommentModel {
  final String id;
  final String userId;
  final String username;
  final String? userAvatar;
  final String songId;
  final String text;
  final String? parentId;
  final int likeCount;
  final bool isLikedByUser;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  CommentModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.songId,
    required this.text,
    this.parentId,
    required this.likeCount,
    required this.isLikedByUser,
    required this.createdAt,
    this.updatedAt,
    required this.isDeleted,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final userData = json['userId'];
    return CommentModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: userData is Map ? (userData['_id'] ?? '') : userData ?? '',
      username: userData is Map ? (userData['username'] ?? 'Unknown') : 'Unknown',
      userAvatar: userData is Map ? userData['avatarUrl'] : null,
      songId: json['songId'] ?? '',
      text: json['text'] ?? '',
      parentId: json['parentId'],
      likeCount: json['likeCount'] ?? 0,
      isLikedByUser: json['isLikedByUser'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isDeleted: json['deletedAt'] != null,
    );
  }
}

/// Comment state
class CommentState {
  final List<CommentModel> comments;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const CommentState({
    this.comments = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  CommentState copyWith({
    List<CommentModel>? comments,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return CommentState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Comment provider for a specific song
final commentProvider = StateNotifierProvider.family<CommentNotifier, CommentState, String>(
  (ref, songId) => CommentNotifier(songId),
);

class CommentNotifier extends StateNotifier<CommentState> {
  final String songId;
  final Dio _dio = Dio();

  CommentNotifier(this.songId) : super(const CommentState()) {
    loadComments();
  }

  /// Load comments from backend
  Future<void> loadComments({bool refresh = false}) async {
    if (refresh) {
      state = const CommentState(isLoading: true);
    } else if (state.isLoading || !state.hasMore) {
      return;
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/${ApiConfig.apiVersion}/songs/$songId/comments',
        queryParameters: {
          'page': refresh ? 1 : state.currentPage,
          'limit': 20,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final commentsList = (data['comments'] as List)
            .map((json) => CommentModel.fromJson(json))
            .toList();

        if (refresh) {
          state = state.copyWith(
            comments: commentsList,
            isLoading: false,
            error: null,
            hasMore: commentsList.length >= 20,
            currentPage: 2,
          );
        } else {
          state = state.copyWith(
            comments: [...state.comments, ...commentsList],
            isLoading: false,
            error: null,
            hasMore: commentsList.length >= 20,
            currentPage: state.currentPage + 1,
          );
        }
      }
    } catch (e) {
      print('❌ Error loading comments: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load comments',
      );
    }
  }

  /// Add new comment
  Future<bool> addComment(String text, {String? parentId}) async {
    try {
      final token = await StorageService().getAccessToken();
      if (token == null) return false;

      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/${ApiConfig.apiVersion}/songs/$songId/comments',
        data: {
          'text': text,
          if (parentId != null) 'parentId': parentId,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201) {
        // Refresh comments to get the new one
        await loadComments(refresh: true);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error adding comment: $e');
      return false;
    }
  }

  /// Edit comment
  Future<bool> editComment(String commentId, String newText) async {
    try {
      final token = await StorageService().getAccessToken();
      if (token == null) return false;

      final response = await _dio.put(
        '${ApiConfig.baseUrl}/api/${ApiConfig.apiVersion}/comments/$commentId',
        data: {'text': newText},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        // Update locally
        final updatedComments = state.comments.map((comment) {
          if (comment.id == commentId) {
            return CommentModel(
              id: comment.id,
              userId: comment.userId,
              username: comment.username,
              userAvatar: comment.userAvatar,
              songId: comment.songId,
              text: newText,
              parentId: comment.parentId,
              likeCount: comment.likeCount,
              isLikedByUser: comment.isLikedByUser,
              createdAt: comment.createdAt,
              updatedAt: DateTime.now(),
              isDeleted: comment.isDeleted,
            );
          }
          return comment;
        }).toList();

        state = state.copyWith(comments: updatedComments);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error editing comment: $e');
      return false;
    }
  }

  /// Delete comment
  Future<bool> deleteComment(String commentId) async {
    try {
      final token = await StorageService().getAccessToken();
      if (token == null) return false;

      final response = await _dio.delete(
        '${ApiConfig.baseUrl}/api/${ApiConfig.apiVersion}/comments/$commentId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        // Remove from local state
        final updatedComments = state.comments
            .where((comment) => comment.id != commentId)
            .toList();
        state = state.copyWith(comments: updatedComments);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error deleting comment: $e');
      return false;
    }
  }

  /// Toggle like on comment
  Future<void> toggleLike(String commentId) async {
    try {
      final token = await StorageService().getAccessToken();
      if (token == null) return;

      // Optimistic update
      final updatedComments = state.comments.map((comment) {
        if (comment.id == commentId) {
          return CommentModel(
            id: comment.id,
            userId: comment.userId,
            username: comment.username,
            userAvatar: comment.userAvatar,
            songId: comment.songId,
            text: comment.text,
            parentId: comment.parentId,
            likeCount: comment.isLikedByUser 
                ? comment.likeCount - 1 
                : comment.likeCount + 1,
            isLikedByUser: !comment.isLikedByUser,
            createdAt: comment.createdAt,
            updatedAt: comment.updatedAt,
            isDeleted: comment.isDeleted,
          );
        }
        return comment;
      }).toList();

      state = state.copyWith(comments: updatedComments);

      // Sync with server
      await _dio.post(
        '${ApiConfig.baseUrl}/api/${ApiConfig.apiVersion}/comments/$commentId/like',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      print('❌ Error toggling comment like: $e');
      // Revert on error
      await loadComments(refresh: true);
    }
  }

  /// Get replies for a comment
  List<CommentModel> getReplies(String parentId) {
    return state.comments
        .where((comment) => comment.parentId == parentId)
        .toList();
  }
}
