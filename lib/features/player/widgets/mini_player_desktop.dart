import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/audio_player_provider.dart';
import '../models/song_model.dart';
import '../models/player_state.dart' as models;
import 'glass_container.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../engagement/providers/like_provider.dart';
import '../../engagement/providers/comment_provider.dart';
import '../../engagement/widgets/comments_bottom_sheet.dart';
import '../../engagement/widgets/share_bottom_sheet.dart';

/// Desktop mini player with enhanced controls and features
/// This is a feature-rich version designed for larger screens
class MiniPlayerDesktop extends ConsumerStatefulWidget {
  const MiniPlayerDesktop({super.key});

  @override
  ConsumerState<MiniPlayerDesktop> createState() => _MiniPlayerDesktopState();
}

class _MiniPlayerDesktopState extends ConsumerState<MiniPlayerDesktop> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final song = ref.watch(currentSongProvider);
    final playerState = ref.watch(audioPlayerProvider);
    final tokenState = ref.watch(tokenEarnProvider);

    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        ref.read(playerExpandedProvider.notifier).state = true;
      },
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! < -5) {
          ref.read(playerExpandedProvider.notifier).state = true;
        }
      },
      child: GlassContainer(
        width: double.infinity,
        height: 88,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // Progress bar with token indicator and time
            _buildProgressBar(context, theme, playerState, tokenState),
            const SizedBox(height: 10),
            // Player controls
            Expanded(
              child: Row(
                children: [
                  // LEFT: Album art + Song info + Time
                  _buildLeftSection(context, song, theme, playerState),
                  const SizedBox(width: 24),
                  // CENTER: Playback controls (centered)
                  Expanded(
                    child: Center(
                      child: _buildControls(playerState, theme),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // RIGHT: Engagement buttons + Volume
                  _buildRightSection(context, song, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftSection(
    BuildContext context,
    SongModel song,
    ThemeData theme,
    models.PlayerState playerState,
  ) {
    return SizedBox(
      width: 300,
      child: Row(
        children: [
          // Album art
          _buildAlbumArt(song, theme),
          const SizedBox(width: 12),
          // Song info
          Expanded(
            child: _buildSongInfoWithDownloadIndicator(context, song, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSongInfoWithDownloadIndicator(
    BuildContext context,
    SongModel song,
    ThemeData theme,
  ) {
    final isPlayingFromDownload = ref.watch(playingFromDownloadProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (isPlayingFromDownload) ...[
              const Icon(
                Icons.download_done,
                size: 14,
                color: Colors.green,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                song.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          song.artist,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRightSection(
    BuildContext context,
    SongModel song,
    ThemeData theme,
  ) {
    final likeState = ref.watch(likeProvider(song.id));
    final commentState = ref.watch(commentProvider(song.id));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like button
        _buildEngagementButton(
          icon: likeState.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
          isActive: likeState.isLiked,
          theme: theme,
          onPressed: likeState.isLoading
              ? null
              : () => ref.read(likeProvider(song.id).notifier).toggleLike(),
        ),
        const SizedBox(width: 10),
        
        // Dislike button
        _buildEngagementButton(
          icon: likeState.isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
          isActive: likeState.isDisliked,
          theme: theme,
          onPressed: likeState.isLoading
              ? null
              : () => ref.read(likeProvider(song.id).notifier).toggleDislike(),
        ),
        const SizedBox(width: 10),
        
        // Comment button
        _buildEngagementButton(
          icon: Icons.comment_outlined,
          theme: theme,
          count: song.commentCount > 0 ? song.commentCount : null,
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => CommentsBottomSheet(song: song),
            );
          },
        ),
        const SizedBox(width: 10),
        
        // Share button
        _buildEngagementButton(
          icon: Icons.share_outlined,
          theme: theme,
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => ShareBottomSheet(song: song),
            );
          },
        ),
        const SizedBox(width: 10),
        
        // Options menu (3 dots)
        _buildEngagementButton(
          icon: Icons.more_vert,
          theme: theme,
          onPressed: () => _showOptionsMenu(context, song),
        ),
        const SizedBox(width: 16),
        
        // Volume control
        _buildVolumeControl(theme),
      ],
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required ThemeData theme,
    required VoidCallback? onPressed,
    bool isActive = false,
    int? count,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 22,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              if (count != null && count > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeControl(ThemeData theme) {
    final playerState = ref.watch(audioPlayerProvider);
    final volume = playerState.volume;
    
    return SizedBox(
      width: 140,
      height: 40,
      child: Row(
        children: [
          // Volume icon - always visible
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref.read(audioPlayerProvider.notifier).toggleMute();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  _getVolumeIcon(volume),
                  size: 22,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          
          // Slider - always visible
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                thumbColor: theme.colorScheme.primary,
                overlayColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: volume,
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  ref.read(audioPlayerProvider.notifier).setVolume(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getVolumeIcon(double volume) {
    if (volume == 0) {
      return Icons.volume_off;
    } else if (volume < 0.3) {
      return Icons.volume_mute;
    } else if (volume < 0.7) {
      return Icons.volume_down;
    } else {
      return Icons.volume_up;
    }
  }

  void _showOptionsMenu(BuildContext context, SongModel song) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              _buildOptionTile(
                icon: Icons.playlist_add,
                title: 'Add to playlist',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement add to playlist
                },
                theme: theme,
              ),
              
              _buildOptionTile(
                icon: Icons.download,
                title: 'Download',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement download
                },
                theme: theme,
              ),
              
              _buildOptionTile(
                icon: Icons.person,
                title: 'Go to artist',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to artist profile
                },
                theme: theme,
              ),
              
              _buildOptionTile(
                icon: Icons.report_outlined,
                title: 'Report song',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement report
                },
                theme: theme,
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium,
      ),
      onTap: onTap,
    );
  }

  Widget _buildControls(
    models.PlayerState playerState,
    ThemeData theme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Shuffle
        IconButton(
          icon: const Icon(Icons.shuffle),
          iconSize: 24,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          color: playerState.shuffleMode
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          onPressed: () {
            ref.read(audioPlayerProvider.notifier).toggleShuffle();
          },
        ),
        const SizedBox(width: 8),
        // Skip backward
        IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 32,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          color: theme.colorScheme.onSurface,
          onPressed: () {
            ref.read(audioPlayerProvider.notifier).playPrevious();
          },
        ),
        // Play/Pause
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                ref.read(audioPlayerProvider.notifier).playPause();
              },
              child: Icon(
                playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        // Skip forward
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 32,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          color: theme.colorScheme.onSurface,
          onPressed: () {
            ref.read(audioPlayerProvider.notifier).playNext();
          },
        ),
        const SizedBox(width: 8),
        // Repeat
        IconButton(
          icon: Icon(
            playerState.loopMode == LoopMode.one
                ? Icons.repeat_one
                : Icons.repeat,
          ),
          iconSize: 24,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          color: playerState.loopMode != LoopMode.off
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          onPressed: () {
            ref.read(audioPlayerProvider.notifier).toggleLoopMode();
          },
        ),
      ],
    );
  }

  Widget _buildTimeDisplay(models.PlayerState playerState, ThemeData theme) {
    return SizedBox(
      width: 100, // Fixed width to prevent layout shifts
      child: Text(
        '${_formatDuration(playerState.position)} / ${_formatDuration(playerState.duration)}',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Format duration to mm:ss format
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildProgressBar(
    BuildContext context,
    ThemeData theme,
    models.PlayerState playerState,
    models.TokenEarnState tokenState,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(playerState.position),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
            Text(
              _formatDuration(playerState.duration),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Progress bar
        SizedBox(
          height: 3,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Background
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Progress with gradient
                  FractionallySizedBox(
                    widthFactor: playerState.progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Token earn indicator at 80%
                  if (tokenState.progress >= 0.8 && !tokenState.hasRewarded)
                    Positioned(
                      left: constraints.maxWidth * 0.77,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.tokenPrimary,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.tokenPrimary.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumArt(SongModel song, ThemeData theme) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
                memCacheHeight: 200,
                memCacheWidth: 200,
                placeholder: (context, url) => _buildAlbumPlaceholder(theme),
                errorWidget: (context, url, error) =>
                    _buildAlbumPlaceholder(theme),
              )
            : _buildAlbumPlaceholder(theme),
      ),
    );
  }

  Widget _buildAlbumPlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
      ),
      child: Icon(
        Icons.music_note,
        color: theme.colorScheme.onPrimary,
        size: 28,
      ),
    );
  }
}
