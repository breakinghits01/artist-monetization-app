import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../player/models/song_model.dart';
import 'playing_indicator_overlay.dart';
import '../../../../widgets/download_button.dart';

/// Song list item widget for displaying song information
class SongListItem extends StatelessWidget {
  final SongModel song;
  final bool isCurrentlyPlaying;
  final bool isLiked;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onOptions;

  const SongListItem({
    super.key,
    required this.song,
    required this.isCurrentlyPlaying,
    required this.isLiked,
    required this.onTap,
    required this.onLike,
    required this.onOptions,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: isCurrentlyPlaying 
            ? LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.15),
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isCurrentlyPlaying ? null : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentlyPlaying 
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          if (isCurrentlyPlaying)
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: song.albumArt != null && song.albumArt!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: song.albumArt!,
                        fit: BoxFit.cover,
                        memCacheHeight: 150,
                        memCacheWidth: 150,
                        placeholder: (context, url) => Center(
                          child: Icon(
                            Icons.music_note,
                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
                            size: 30,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.music_note,
                          color: theme.colorScheme.primary,
                          size: 30,
                        ),
                      )
                    : Icon(
                        Icons.music_note,
                        color: theme.colorScheme.primary,
                        size: 30,
                      ),
              ),
            ),
            // Show wave indicator when playing, with hover pause for web
            if (isCurrentlyPlaying)
              const PlayingIndicatorOverlay(),
          ],
        ),
        title: Text(
          song.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isCurrentlyPlaying ? FontWeight.bold : FontWeight.w500,
            color: isCurrentlyPlaying ? theme.colorScheme.primary : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (song.genre != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      song.genre!,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.headphones,
                        size: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${song.playCount}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
            if (song.genre == null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.headphones,
                    size: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${song.playCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _formatDuration(song.duration),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '+${song.tokenReward}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            DownloadButton(
              songId: song.id,
              songTitle: song.title,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : null,
                size: 20,
              ),
              onPressed: onLike,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              onPressed: onOptions,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
