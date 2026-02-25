import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../player/models/song_model.dart';

/// Song header widget with large album art and metadata
class SongHeader extends StatelessWidget {
  final SongModel song;

  const SongHeader({
    super.key,
    required this.song,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final albumArtSize = isDesktop ? 180.0 : 120.0;

    if (isDesktop) {
      // Desktop: Horizontal layout
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album art
          _buildAlbumArt(theme, albumArtSize),
          const SizedBox(width: 20),
          // Info
          Expanded(child: _buildSongInfo(theme, isDesktop)),
        ],
      );
    }

    // Mobile: Vertical layout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlbumArt(theme, albumArtSize),
            const SizedBox(width: 12),
            Expanded(child: _buildSongInfo(theme, isDesktop)),
          ],
        ),
      ],
    );
  }

  Widget _buildAlbumArt(ThemeData theme, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: song.albumArt != null
          ? CachedNetworkImage(
              imageUrl: song.albumArt!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              memCacheHeight: 400,
              memCacheWidth: 400,
              placeholder: (context, url) => Container(
                width: size,
                height: size,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.music_note,
                  size: size * 0.4,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: size,
                height: size,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.music_note,
                  size: size * 0.4,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : Container(
              width: size,
              height: size,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.music_note,
                size: size * 0.4,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }

  Widget _buildSongInfo(ThemeData theme, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Song Title
        Text(
          song.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isDesktop ? 28 : 24,
          ),
        ),
        const SizedBox(height: 8),
        
        // Artist Name
        Text(
          song.artist,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: isDesktop ? 18 : 16,
          ),
        ),
        const SizedBox(height: 16),
        
        // Metadata Row
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            // Duration
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(song.duration),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),

            // Genre
            if (song.genre != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  song.genre!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

            // Premium Badge
            if (song.isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade600,
                      Colors.orange.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PREMIUM',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
