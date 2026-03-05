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
  final int replyCount; // Number of replies from backend
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
    this.replyCount = 0,
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
      userAvatar: userData is Map ? (userData['profilePicture'] ?? userData['avatarUrl']) : null,
      songId: json['songId'] ?? '',
      text: json['content'] ?? json['text'] ?? '', // Backend uses 'content'
      parentId: json['parentCommentId'] ?? json['parentId'],
      likeCount: json['likes'] ?? json['likeCount'] ?? 0,
      isLikedByUser: json['userHasLiked'] ?? json['isLikedByUser'] ?? false,
      replyCount: json['replyCount'] ?? 0, // Backend provides this
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isDeleted: json['deletedAt'] != null,
    );
  }
}

/// Comment state with separated top-level comments and replies
class CommentState {
  final List<CommentModel> comments; // Only top-level comments (parentId == null)
  final Map<String, List<CommentModel>> repliesMap; // Replies grouped by parentId
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const CommentState({
    this.comments = const [],
    this.repliesMap = const {},
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  CommentState copyWith({
    List<CommentModel>? comments,
    Map<String, List<CommentModel>>? repliesMap,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return CommentState(
      comments: comments ?? this.comments,
      repliesMap: repliesMap ?? this.repliesMap,
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

  /// Load comments from backend (only top-level comments)
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
        final allComments = (data['comments'] as List)
            .map((json) => CommentModel.fromJson(json))
            .toList();
        
        print('📊 Total comments from API: ${allComments.length}');
        
        final commentsList = allComments
            .where((comment) => comment.parentId == null) // Only top-level
            .toList();
        
        print('📝 Top-level comments: ${commentsList.length}');

        // Build replies map from all comments
        final newRepliesMap = <String, List<CommentModel>>{};
        for (final comment in allComments) {
          if (comment.parentId != null) {
            print('💬 Reply found: id=${comment.id.substring(0, 8)}, parentId=${comment.parentId?.substring(0, 8)}, text="${comment.text}"');
            if (!newRepliesMap.containsKey(comment.parentId)) {
              newRepliesMap[comment.parentId!] = [];
            }
            newRepliesMap[comment.parentId!]!.add(comment);
          }
        }
        
        print('🗺️ Replies map keys: ${newRepliesMap.keys.map((k) => k.substring(0, 8)).toList()}');
        print('🗺️ Replies map values: ${newRepliesMap.map((k, v) => MapEntry(k.substring(0, 8), v.length))}');

        if (refresh) {
          state = state.copyWith(
            comments: commentsList,
            repliesMap: newRepliesMap,
            isLoading: false,
            error: null,
            hasMore: commentsList.length >= 20,
            currentPage: 2,
          );
        } else {
          // Merge replies maps for pagination
          final mergedRepliesMap = Map<String, List<CommentModel>>.from(state.repliesMap);
          newRepliesMap.forEach((key, value) {
            if (mergedRepliesMap.containsKey(key)) {
              mergedRepliesMap[key] = [...mergedRepliesMap[key]!, ...value];
            } else {
              mergedRepliesMap[key] = value;
            }
          });

          state = state.copyWith(
            comments: [...state.comments, ...commentsList],
            repliesMap: mergedRepliesMap,
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
          'content': text, // Backend expects 'content' not 'text'
          if (parentId != null) 'parentCommentId': parentId,
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
        data: {'content': newText}, // Backend expects 'content'
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        // Update in top-level comments
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
              replyCount: comment.replyCount,
              createdAt: comment.createdAt,
              updatedAt: DateTime.now(),
              isDeleted: comment.isDeleted,
            );
          }
          return comment;
        }).toList();

        // Update in replies map
        final updatedRepliesMap = Map<String, List<CommentModel>>.from(state.repliesMap);
        updatedRepliesMap.forEach((parentId, replies) {
          updatedRepliesMap[parentId] = replies.map((reply) {
            if (reply.id == commentId) {
              return CommentModel(
                id: reply.id,
                userId: reply.userId,
                username: reply.username,
                userAvatar: reply.userAvatar,
                songId: reply.songId,
                text: newText,
                parentId: reply.parentId,
                likeCount: reply.likeCount,
                isLikedByUser: reply.isLikedByUser,
                replyCount: reply.replyCount,
                createdAt: reply.createdAt,
                updatedAt: DateTime.now(),
                isDeleted: reply.isDeleted,
              );
            }
            return reply;
          }).toList();
        });

        state = state.copyWith(
          comments: updatedComments,
          repliesMap: updatedRepliesMap,
        );
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
        // Check if this is a reply (has parentId) and decrement parent's reply count
        String? deletedReplyParentId;
        state.repliesMap.forEach((parentId, replies) {
          if (replies.any((reply) => reply.id == commentId)) {
            deletedReplyParentId = parentId;
          }
        });
        
        // Remove from top-level comments
        final updatedComments = state.comments.map((comment) {
          // If deleting a reply, decrement parent's reply count
          if (deletedReplyParentId != null && comment.id == deletedReplyParentId) {
            return CommentModel(
              id: comment.id,
              userId: comment.userId,
              username: comment.username,
              userAvatar: comment.userAvatar,
              songId: comment.songId,
              text: comment.text,
              parentId: comment.parentId,
              likeCount: comment.likeCount,
              isLikedByUser: comment.isLikedByUser,
              replyCount: comment.replyCount > 0 ? comment.replyCount - 1 : 0,
              createdAt: comment.createdAt,
              updatedAt: comment.updatedAt,
              isDeleted: comment.isDeleted,
            );
          }
          return comment;
        }).where((comment) => comment.id != commentId).toList();
        
        // Remove from replies map
        final updatedRepliesMap = Map<String, List<CommentModel>>.from(state.repliesMap);
        updatedRepliesMap.forEach((parentId, replies) {
          updatedRepliesMap[parentId] = replies
              .where((reply) => reply.id != commentId)
              .toList();
        });
        // Remove empty reply lists
        updatedRepliesMap.removeWhere((key, value) => value.isEmpty);

        state = state.copyWith(
          comments: updatedComments,
          repliesMap: updatedRepliesMap,
        );
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

      // Optimistic update - check top-level comments
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
            replyCount: comment.replyCount,
            createdAt: comment.createdAt,
            updatedAt: comment.updatedAt,
            isDeleted: comment.isDeleted,
          );
        }
        return comment;
      }).toList();

      // Optimistic update - check replies map
      final updatedRepliesMap = Map<String, List<CommentModel>>.from(state.repliesMap);
      updatedRepliesMap.forEach((parentId, replies) {
        updatedRepliesMap[parentId] = replies.map((reply) {
          if (reply.id == commentId) {
            return CommentModel(
              id: reply.id,
              userId: reply.userId,
              username: reply.username,
              userAvatar: reply.userAvatar,
              songId: reply.songId,
              text: reply.text,
              parentId: reply.parentId,
              likeCount: reply.isLikedByUser 
                  ? reply.likeCount - 1 
                  : reply.likeCount + 1,
              isLikedByUser: !reply.isLikedByUser,
              replyCount: reply.replyCount,
              createdAt: reply.createdAt,
              updatedAt: reply.updatedAt,
              isDeleted: reply.isDeleted,
            );
          }
          return reply;
        }).toList();
      });

      state = state.copyWith(
        comments: updatedComments,
        repliesMap: updatedRepliesMap,
      );

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

  /// Get replies for a comment from the repliesMap
  List<CommentModel> getReplies(String parentId) {
    return state.repliesMap[parentId] ?? [];
  }

  /// Load replies for a specific comment
  Future<void> loadReplies(String commentId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/${ApiConfig.apiVersion}/comments/$commentId/replies',
        queryParameters: {'page': 1, 'limit': 50},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final repliesList = (data['replies'] as List)
            .map((json) => CommentModel.fromJson(json))
            .toList();

        // Store replies in the map keyed by parent comment ID
        final updatedRepliesMap = Map<String, List<CommentModel>>.from(state.repliesMap);
        updatedRepliesMap[commentId] = repliesList;

        state = state.copyWith(repliesMap: updatedRepliesMap);
      }
    } catch (e) {
      print('❌ Error loading replies: $e');
    }
  }

  /// Reply to a comment
  Future<bool> replyToComment(String parentCommentId, String text) async {
    try {
      final token = await StorageService().getAccessToken();
      if (token == null) return false;

      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/${ApiConfig.apiVersion}/comments/$parentCommentId/reply',
        data: {'content': text},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201) {
        // Increment reply count for the parent comment
        final updatedComments = state.comments.map((comment) {
          if (comment.id == parentCommentId) {
            return CommentModel(
              id: comment.id,
              userId: comment.userId,
              username: comment.username,
              userAvatar: comment.userAvatar,
              songId: comment.songId,
              text: comment.text,
              parentId: comment.parentId,
              likeCount: comment.likeCount,
              isLikedByUser: comment.isLikedByUser,
              replyCount: comment.replyCount + 1,
              createdAt: comment.createdAt,
              updatedAt: comment.updatedAt,
              isDeleted: comment.isDeleted,
            );
          }
          return comment;
        }).toList();
        
        state = state.copyWith(comments: updatedComments);
        
        // Load/reload replies for this parent to get the new reply
        await loadReplies(parentCommentId);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error replying to comment: $e');
      return false;
    }
  }
}
