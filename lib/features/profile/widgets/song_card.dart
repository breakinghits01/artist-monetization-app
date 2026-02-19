import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../player/models/song_model.dart';
import '../../../core/theme/app_colors_extension.dart';

class SongCard extends ConsumerStatefulWidget {
  final SongModel song;
  final bool isCurrentlyPlaying;
  final bool isLiked;
  final VoidCallback? onPlay;
  final VoidCallback? onLike;
  final VoidCallback? onOptions;

  const SongCard({
    super.key,
    required this.song,
    this.isCurrentlyPlaying = false,
    this.isLiked = false,
    this.onPlay,
    this.onLike,
    this.onOptions,
  });

  @override
  ConsumerState<SongCard> createState() => _SongCardState();
}

class _SongCardState extends ConsumerState<SongCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _likeAnimationController;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.primary
                : (isDark ? Colors.white24 : Colors.black12),
            width: 2,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
          // Glass-morphism effect
          color: isDark
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : theme.colorScheme.primary.withValues(alpha: 0.02),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPlay,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Album Art with Play Button Overlay
                  Stack(
                    children: [
                      // Album Art
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: widget.isCurrentlyPlaying
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary.withValues(alpha: 0.3),
                              width: widget.isCurrentlyPlaying ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: widget.song.albumArt != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.song.albumArt!,
                                  fit: BoxFit.cover,
                                  memCacheHeight: 200,
                                  memCacheWidth: 200,
                                  placeholder: (context, url) => Container(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.music_note,
                                      size: 60,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.music_note,
                                    size: 60,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                        ),
                      ),
                      // Currently Playing Indicator
                      if (widget.isCurrentlyPlaying)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Playing',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Play Button Overlay
                      if (_isHovered && !widget.isCurrentlyPlaying)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.1),
                                  Colors.black.withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Like Button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            if (widget.isLiked) {
                              _likeAnimationController.reverse();
                            } else {
                              _likeAnimationController.forward();
                            }
                            widget.onLike?.call();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.6),
                            ),
                            child: Icon(
                              widget.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: widget.isLiked
                                  ? theme.colorScheme.primary
                                  : Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Song Title
                  Flexible(
                    child: Text(
                      widget.song.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Artist Name
                  Flexible(
                    child: Text(
                      widget.song.artist,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Genre and Duration
                  Row(
                    children: [
                      // Genre Badge
                      if (widget.song.genre != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.accentPurple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.accentPurple.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            widget.song.genre!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.accentPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Spacer(),
                      // Duration
                      Text(
                        _formatDuration(widget.song.duration),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(widget.song.duration),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Token Reward and Options
                  Row(
                    children: [
                      Icon(
                        Icons.toll,
                        size: 16,
                        color: theme.colorScheme.tokenPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${widget.song.tokenReward}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.tokenPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onPressed: widget.onOptions,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
