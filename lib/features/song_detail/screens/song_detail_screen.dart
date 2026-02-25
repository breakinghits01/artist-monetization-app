import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../player/models/song_model.dart';
import '../widgets/action_buttons_row.dart';
import '../../engagement/providers/like_provider.dart';

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
        if (song.commentCount > 0)
          _StatItem(
            icon: Icons.comment,
            label: '${song.commentCount} comments',
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
      // TODO: Implement comment submission
      // For now just clear the field
      _commentController.clear();
      _focusNode.unfocus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment posted!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post comment: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
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
        
        // No Comments Message
        Expanded(
          child: Center(
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
          ),
        ),
      ],
    );
  }
}
