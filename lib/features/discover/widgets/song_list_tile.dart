import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../player/models/song_model.dart';
import '../../player/providers/audio_player_provider.dart';
import '../../player/widgets/audio_wave_indicator.dart';
import '../../../shared/widgets/token_icon.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../engagement/providers/like_provider.dart';

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
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
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
                        memCacheHeight: 150,
                        memCacheWidth: 150,
                        placeholder: (context, url) => _buildAlbumPlaceholder(theme),
                        errorWidget: (context, url, error) => _buildAlbumPlaceholder(theme),
                      )
                    : _buildAlbumPlaceholder(theme),
              ),
            ),
            // Playing indicator - animated wave when playing, static icon when paused
            if (isCurrentSong)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: isPlaying
                        ? AudioWaveIndicator(
                            isPlaying: true,
                            color: Colors.white,
                            size: 32,
                          )
                        : Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
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
            // Engagement row (headphones + like + dislike + comment + share)
            const SizedBox(height: 6),
            Row(
              children: [
                // Playcount (headphones icon) - only show if > 0
                if (song.playCount > 0) ...[
                  Icon(
                    Icons.headphones,
                    size: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${song.playCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Like button with rounded background and animation
                Consumer(
                  builder: (context, ref, child) {
                    final likeState = ref.watch(likeProvider(song.id));
                    
                    return AnimatedScale(
                      scale: likeState.isLoading ? 0.9 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: InkWell(
                        onTap: likeState.isLoading
                            ? null
                            : () {
                                print('👆 Like button tapped for song: ${song.id}');
                                ref.read(likeProvider(song.id).notifier).toggleLike();
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: likeState.isLiked
                                ? theme.colorScheme.primary // Pink background when liked
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: likeState.isLiked
                                ? Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 1,
                                  )
                                : null, // No border when unliked
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.thumb_up_outlined,
                                size: 14,
                                color: likeState.isLiked
                                    ? Colors.white // White when liked
                                    : theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                              if (likeState.likeCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${likeState.likeCount}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: likeState.isLiked
                                        ? Colors.white // White when liked
                                        : theme.colorScheme.onSurface.withOpacity(0.5),
                                    fontWeight: likeState.isLiked
                                        ? FontWeight.bold // Bold only when liked
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                // Dislike button with rounded background and animation
                Consumer(
                  builder: (context, ref, child) {
                    final likeState = ref.watch(likeProvider(song.id));
                    
                    return AnimatedScale(
                      scale: likeState.isLoading ? 0.9 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: InkWell(
                        onTap: likeState.isLoading
                            ? null
                            : () {
                                print('👎 Dislike button tapped for song: ${song.id}');
                                ref.read(likeProvider(song.id).notifier).toggleDislike();
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: likeState.isDisliked
                                ? Colors.red.shade400 // Red background when disliked
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: likeState.isDisliked
                                ? Border.all(
                                    color: Colors.red.shade400,
                                    width: 1,
                                  )
                                : null, // No border when not disliked
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.thumb_down_outlined,
                                size: 14,
                                color: likeState.isDisliked
                                    ? Colors.white // White when disliked
                                    : theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                              if (likeState.dislikeCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${likeState.dislikeCount}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: likeState.isDisliked
                                        ? Colors.white // White when disliked
                                        : theme.colorScheme.onSurface.withOpacity(0.5),
                                    fontWeight: likeState.isDisliked
                                        ? FontWeight.bold // Bold only when disliked
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                // Comment icon with consistent padding
                InkWell(
                  onTap: () {
                    // TODO: Open comments bottom sheet
                    print('Comments tapped for song: ${song.id}');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        if (song.commentCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${song.commentCount}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Share icon with consistent padding
                InkWell(
                  onTap: () {
                    // TODO: Open share bottom sheet
                    print('Share tapped for song: ${song.id}');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.share_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        if (song.shareCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${song.shareCount}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
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
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
        size: 30,
      ),
    );
  }
}
