import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../player/models/song_model.dart';
import '../../player/providers/audio_player_provider.dart';
import '../../../shared/widgets/token_icon.dart';
import '../../../core/theme/app_colors_extension.dart';

/// Song list tile for browse/discover screens
class SongListTile extends ConsumerWidget {
  final SongModel song;
  final List<SongModel>? allSongs; // For queue context
  final VoidCallback? onTap;

  const SongListTile({
    super.key,
    required this.song,
    this.allSongs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentSong = ref.watch(currentSongProvider);
    final playerState = ref.watch(audioPlayerProvider);
    final isCurrentSong = currentSong?.id == song.id;
    final isPlaying = isCurrentSong && playerState.isPlaying;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Stack(
          children: [
            // Album art
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: song.albumArt != null
                    ? CachedNetworkImage(
                        imageUrl: song.albumArt!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildAlbumPlaceholder(theme),
                        errorWidget: (context, url, error) => _buildAlbumPlaceholder(theme),
                      )
                    : _buildAlbumPlaceholder(theme),
              ),
            ),
            // Playing indicator
            if (isCurrentSong)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          song.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isCurrentSong ? theme.colorScheme.primary : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              song.artist,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  song.genre ?? 'Unknown',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 8),
                const TokenIcon(size: 12, withShadow: false),
                const SizedBox(width: 4),
                Text(
                  '+${song.tokenReward}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tokenPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (song.isPremium) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: theme.colorScheme.primary,
            size: 40,
          ),
          onPressed: () {
            if (isCurrentSong) {
              ref.read(audioPlayerProvider.notifier).playPause();
            } else {
              // Use queue if available, otherwise single song
              if (allSongs != null && allSongs!.isNotEmpty) {
                ref.read(audioPlayerProvider.notifier).playSongWithQueue(song, allSongs!);
              } else {
                ref.read(audioPlayerProvider.notifier).playSong(song);
              }
            }
          },
        ),
        onTap: onTap ?? () {
          if (isCurrentSong) {
            ref.read(audioPlayerProvider.notifier).playPause();
          } else {
            // Use queue if available, otherwise single song
            if (allSongs != null && allSongs!.isNotEmpty) {
              ref.read(audioPlayerProvider.notifier).playSongWithQueue(song, allSongs!);
            } else {
              ref.read(audioPlayerProvider.notifier).playSong(song);
            }
          }
        },
      ),
    );
  }

  Widget _buildAlbumPlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
      ),
      child: Icon(
        Icons.music_note,
        color: theme.colorScheme.onPrimary.withOpacity(0.8),
        size: 30,
      ),
    );
  }
}
