import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../player/models/song_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/comment_provider.dart';

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final SongModel song;

  const CommentsBottomSheet({super.key, required this.song});

  @override
  ConsumerState<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _replyToId;
  String? _replyToUsername;
  String? _editingCommentId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when near bottom
      ref.read(commentProvider(widget.song.id).notifier).loadComments();
    }
  }

  void _startReply(String commentId, String username) {
    setState(() {
      _replyToId = commentId;
      _replyToUsername = username;
      _editingCommentId = null;
    });
    _commentController.clear();
    FocusScope.of(context).requestFocus();
  }

  void _startEdit(String commentId, String currentText) {
    setState(() {
      _editingCommentId = commentId;
      _replyToId = null;
      _replyToUsername = null;
      _commentController.text = currentText;
    });
    FocusScope.of(context).requestFocus();
  }

  void _cancelAction() {
    setState(() {
      _replyToId = null;
      _replyToUsername = null;
      _editingCommentId = null;
      _commentController.clear();
    });
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final notifier = ref.read(commentProvider(widget.song.id).notifier);

    bool success;
    if (_editingCommentId != null) {
      success = await notifier.editComment(_editingCommentId!, text);
    } else {
      success = await notifier.addComment(text, parentId: _replyToId);
    }

    if (success) {
      _cancelAction();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post comment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentState = ref.watch(commentProvider(widget.song.id));
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?['_id'] ?? currentUser?['id'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comments',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.song.commentCount > 0
                            ? '${widget.song.commentCount} ${widget.song.commentCount == 1 ? "comment" : "comments"}'
                            : 'Be the first to comment',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Reply/Edit banner
          if (_replyToUsername != null || _editingCommentId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              child: Row(
                children: [
                  Icon(
                    _editingCommentId != null ? Icons.edit : Icons.reply,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _editingCommentId != null
                          ? 'Editing comment'
                          : 'Replying to @$_replyToUsername',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _cancelAction,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Comments list
          Expanded(
            child: commentState.isLoading && commentState.comments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : commentState.comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to comment!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(commentProvider(widget.song.id).notifier)
                            .loadComments(refresh: true),
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: commentState.comments.length +
                              (commentState.hasMore ? 1 : 0),
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            if (index >= commentState.comments.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final comment = commentState.comments[index];
                            
                            // Skip parent comments when showing replies
                            if (comment.parentId != null) {
                              return const SizedBox.shrink();
                            }

                            final replies = ref
                                .read(commentProvider(widget.song.id).notifier)
                                .getReplies(comment.id);

                            return _CommentTile(
                              comment: comment,
                              replies: replies,
                              currentUserId: currentUserId,
                              onReply: () => _startReply(comment.id, comment.username),
                              onEdit: () => _startEdit(comment.id, comment.text),
                              onDelete: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Comment'),
                                    content: const Text(
                                        'Are you sure you want to delete this comment?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  await ref
                                      .read(commentProvider(widget.song.id).notifier)
                                      .deleteComment(comment.id);
                                }
                              },
                              onLike: () => ref
                                  .read(commentProvider(widget.song.id).notifier)
                                  .toggleLike(comment.id),
                              onReplyToReply: (replyId, username) =>
                                  _startReply(replyId, username),
                            );
                          },
                        ),
                      ),
          ),

          const Divider(height: 1),

          // Input field
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: _replyToUsername != null
                            ? 'Reply to @$_replyToUsername...'
                            : _editingCommentId != null
                                ? 'Edit your comment...'
                                : 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 500,
                      buildCounter: (context,
                          {required currentLength, required isFocused, maxLength}) {
                        if (!isFocused) return null;
                        return Text(
                          '$currentLength/$maxLength',
                          style: theme.textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _editingCommentId != null ? Icons.check : Icons.send,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: _submitComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final List<CommentModel> replies;
  final String? currentUserId;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLike;
  final Function(String, String) onReplyToReply;

  const _CommentTile({
    required this.comment,
    required this.replies,
    required this.currentUserId,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onLike,
    required this.onReplyToReply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwnComment = currentUserId == comment.userId;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  comment.username[0].toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.username,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeago.format(comment.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        if (comment.updatedAt != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(edited)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.text,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        InkWell(
                          onTap: onLike,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  comment.isLikedByUser
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 16,
                                  color: comment.isLikedByUser
                                      ? Colors.red
                                      : theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                                if (comment.likeCount > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '${comment.likeCount}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onReply,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.reply,
                                  size: 16,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Reply',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isOwnComment) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onEdit,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                'Edit',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onDelete,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                'Delete',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Replies
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Column(
              children: replies.map((reply) {
                final isOwnReply = currentUserId == reply.userId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12, right: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        child: Text(
                          reply.username[0].toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  reply.username,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  timeago.format(reply.createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reply.text,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    // Like reply
                                    // You can extend this to like replies
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.favorite_border,
                                        size: 14,
                                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                                      ),
                                      if (reply.likeCount > 0) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '${reply.likeCount}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => onReplyToReply(reply.id, reply.username),
                                  child: Text(
                                    'Reply',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                if (isOwnReply) ...[
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: () {
                                      // Delete reply functionality
                                      // You can extend this
                                    },
                                    child: Text(
                                      'Delete',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
