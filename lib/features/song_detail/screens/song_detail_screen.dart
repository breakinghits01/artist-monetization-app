import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:convert';
import '../../player/models/song_model.dart';
import '../widgets/action_buttons_row.dart';
import '../../engagement/providers/like_provider.dart';
import '../../engagement/providers/comment_provider.dart';
import '../../../core/services/storage_service.dart';

/// YouTube-style song detail screen with 2-column layout
class SongDetailScreen extends ConsumerWidget {
  final SongModel song;
  final List<SongModel>? allSongs;

  const SongDetailScreen({
    super.key,
    required this.song,
    this.allSongs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          song.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      body: isDesktop ? _buildDesktopLayout(theme, ref) : _buildMobileLayout(theme, ref),
    );
  }

  Widget _buildDesktopLayout(ThemeData theme, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Panel (70%) - Song Info
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAlbumArt(theme),
                const SizedBox(height: 24),
                _buildSongInfo(theme),
                const SizedBox(height: 20),
                ActionButtonsRow(song: song, allSongs: allSongs),
                const SizedBox(height: 16),
                Divider(color: theme.dividerColor.withOpacity(0.1)),
                const SizedBox(height: 16),
                _buildStats(theme, ref),
              ],
            ),
          ),
        ),
        
        // Right Panel (30%) - Comments
        Container(
          width: 400,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: theme.dividerColor.withOpacity(0.1),
              ),
            ),
          ),
          child: _CommentsPanel(song: song),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ThemeData theme, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAlbumArt(theme),
          const SizedBox(height: 20),
          _buildSongInfo(theme),
          const SizedBox(height: 16),
          ActionButtonsRow(song: song, allSongs: allSongs),
          const SizedBox(height: 16),
          Divider(color: theme.dividerColor.withOpacity(0.1)),
          const SizedBox(height: 16),
          _buildStats(theme, ref),
          const SizedBox(height: 24),
          _CommentsPanel(song: song),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(ThemeData theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 320,
          maxHeight: 320,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: CachedNetworkImage(
              imageUrl: song.albumArt ?? 'https://via.placeholder.com/400',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.music_note, size: 80),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          song.artist,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(ThemeData theme, WidgetRef ref) {
    final likeState = ref.watch(likeProvider(song.id));
    final commentState = ref.watch(commentProvider(song.id));
    
    return Wrap(
      spacing: 20,
      runSpacing: 12,
      children: [
        _StatItem(
          icon: Icons.headphones,
          label: '${song.playCount} plays',
          theme: theme,
        ),
        _StatItem(
          icon: Icons.thumb_up,
          label: '${likeState.likeCount} likes',
          theme: theme,
        ),
        _StatItem(
          icon: Icons.comment,
          label: '${commentState.comments.length} comments',
          theme: theme,
        ),
        if (song.shareCount > 0)
          _StatItem(
            icon: Icons.share,
            label: '${song.shareCount} shares',
            theme: theme,
          ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}


/// Comments panel for right sidebar
class _CommentsPanel extends ConsumerStatefulWidget {
  final SongModel song;

  const _CommentsPanel({required this.song});

  @override
  ConsumerState<_CommentsPanel> createState() => _CommentsPanelState();
}

class _CommentsPanelState extends ConsumerState<_CommentsPanel> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final commentNotifier = ref.read(commentProvider(widget.song.id).notifier);
      final success = await commentNotifier.addComment(_commentController.text.trim());
      
      if (success && mounted) {
        _commentController.clear();
        _focusNode.unfocus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment posted!'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post comment'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Comments',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
        
        // Comment Input
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: theme.dividerColor.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: theme.dividerColor.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    suffixIcon: _commentController.text.isNotEmpty && !_isSubmitting
                        ? IconButton(
                            icon: Icon(
                              Icons.send,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            onPressed: _submitComment,
                          )
                        : _isSubmitting
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(),
                  onChanged: (value) {
                    setState(() {}); // Rebuild to show/hide send button
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Comments List
        Expanded(
          child: _buildCommentsList(),
        ),
      ],
    );
  }

  Widget _buildCommentsList() {
    final commentState = ref.watch(commentProvider(widget.song.id));
    final theme = Theme.of(context);

    if (commentState.isLoading && commentState.comments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (commentState.error != null && commentState.comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load comments',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  ref.read(commentProvider(widget.song.id).notifier).loadComments(refresh: true);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (commentState.comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.comment_outlined,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No comments yet',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
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
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: commentState.comments.length,
      itemBuilder: (context, index) {
        final comment = commentState.comments[index];
        return _CommentListItem(
          comment: comment,
          songId: widget.song.id,
        );
      },
    );
  }
}

/// Individual comment item widget
class _CommentListItem extends ConsumerStatefulWidget {
  final CommentModel comment;
  final String songId;

  const _CommentListItem({
    required this.comment,
    required this.songId,
  });

  @override
  ConsumerState<_CommentListItem> createState() => _CommentListItemState();
}

class _CommentListItemState extends ConsumerState<_CommentListItem> {
  bool _isDeleting = false;
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _editController;
  late FocusNode _editFocusNode;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.text);
    _editFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _editController.text = widget.comment.text;
    });
    // Focus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocusNode.requestFocus();
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editController.text = widget.comment.text;
    });
  }

  Future<void> _saveEdit() async {
    final newText = _editController.text.trim();
    
    if (newText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment cannot be empty'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (newText == widget.comment.text) {
      _cancelEditing();
      return;
    }

    setState(() => _isSaving = true);

    try {
      final commentNotifier = ref.read(commentProvider(widget.songId).notifier);
      final success = await commentNotifier.editComment(widget.comment.id, newText);

      if (mounted) {
        if (success) {
          setState(() {
            _isEditing = false;
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment updated'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update comment'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteComment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      final commentNotifier = ref.read(commentProvider(widget.songId).notifier);
      final success = await commentNotifier.deleteComment(widget.comment.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Comment deleted' : 'Failed to delete comment'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<String?> _getCurrentUserId() async {
    try {
      final userDataJson = await StorageService().getUserData();
      if (userDataJson != null) {
        final userData = jsonDecode(userDataJson);
        return userData['_id'] ?? userData['id'];
      }
    } catch (e) {
      print('Error getting user ID: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = timeago.format(widget.comment.createdAt, locale: 'en_short');

    return FutureBuilder<String?>(
      future: _getCurrentUserId(),
      builder: (context, snapshot) {
        final isOwnComment = snapshot.data == widget.comment.userId;

        return Opacity(
          opacity: _isDeleting ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 16,
                  backgroundImage: widget.comment.userAvatar != null
                      ? CachedNetworkImageProvider(widget.comment.userAvatar!)
                      : null,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: widget.comment.userAvatar == null
                      ? Icon(
                          Icons.person,
                          size: 18,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                
                // Comment Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username and timestamp
                      Row(
                        children: [
                          Text(
                            widget.comment.username,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeAgo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                          // Only show (edited) if actually edited (updatedAt > createdAt by more than 1 second)
                          if (widget.comment.updatedAt != null &&
                              widget.comment.updatedAt!.difference(widget.comment.createdAt).inSeconds > 1) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(edited)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.4),
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Comment text or edit field
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isEditing
                            ? _buildEditField(theme)
                            : Text(
                                widget.comment.text,
                                key: const ValueKey('comment-text'),
                                style: theme.textTheme.bodySmall,
                              ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Action buttons
                      Row(
                        children: [
                          // Like button
                          InkWell(
                            onTap: _isDeleting
                                ? null
                                : () {
                                    ref
                                        .read(commentProvider(widget.songId).notifier)
                                        .toggleLike(widget.comment.id);
                                  },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.comment.isLikedByUser
                                        ? Icons.thumb_up
                                        : Icons.thumb_up_outlined,
                                    size: 14,
                                    color: widget.comment.isLikedByUser
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  if (widget.comment.likeCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.comment.likeCount}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          
                          // Edit and Delete buttons (only for own comments)
                          if (isOwnComment && !_isEditing) ...[
                            const SizedBox(width: 8),
                            // Edit button
                            InkWell(
                              onTap: _isDeleting ? null : _startEditing,
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 14,
                                  color: theme.colorScheme.primary.withOpacity(0.7),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Delete button
                            InkWell(
                              onTap: _isDeleting ? null : _deleteComment,
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: _isDeleting
                                    ? SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.colorScheme.error,
                                        ),
                                      )
                                    : Icon(
                                        Icons.delete_outline,
                                        size: 14,
                                        color: theme.colorScheme.error.withOpacity(0.7),
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
        );
      },
    );
  }

  Widget _buildEditField(ThemeData theme) {
    return Container(
      key: const ValueKey('edit-field'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _editController,
            focusNode: _editFocusNode,
            maxLines: 3,
            minLines: 1,
            enabled: !_isSaving,
            style: theme.textTheme.bodySmall,
            decoration: InputDecoration(
              hintText: 'Edit your comment...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Cancel button
              TextButton(
                onPressed: _isSaving ? null : _cancelEditing,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Cancel',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              // Save button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveEdit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        'Save',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
