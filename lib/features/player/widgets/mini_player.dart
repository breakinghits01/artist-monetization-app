import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/audio_player_provider.dart';
import '../models/song_model.dart';
import '../models/player_state.dart' as models;
import 'glass_container.dart';
import '../../../core/theme/app_colors_extension.dart';

/// Mini player that appears at bottom of screen
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final song = ref.watch(currentSongProvider);
    final playerState = ref.watch(audioPlayerProvider);
    final tokenState = ref.watch(tokenEarnProvider);
    final isPlayingFromDownload = ref.watch(playingFromDownloadProvider);

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
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            // Progress bar with token indicator
            _buildProgressBar(context, theme, playerState, tokenState),
            const SizedBox(height: 8),
            // Player controls
            Expanded(
              child: Row(
                children: [
                  // Album art
                  _buildAlbumArt(song, theme),
                  const SizedBox(width: 12),
                  // Song info with download indicator
                  Expanded(child: _buildSongInfoWithDownloadIndicator(context, ref, song, theme)),
                  // Controls
                  _buildControls(ref, playerState, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    ThemeData theme,
    models.PlayerState playerState,
    models.TokenEarnState tokenState,
  ) {
    return SizedBox(
      height: 3,
      child: Stack(
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
              left: MediaQuery.of(context).size.width * 0.77,
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
      ),
    );
  }

  Widget _buildAlbumArt(SongModel song, ThemeData theme) {
    return Container(
      width: 56,
      height: 56,
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

  Widget _buildSongInfo(SongModel song, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          song.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

  Widget _buildSongInfoWithDownloadIndicator(
    BuildContext context,
    WidgetRef ref,
    SongModel song,
    ThemeData theme,
  ) {
    final isPlayingFromDownload = ref.watch(playingFromDownloadProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildControls(
    WidgetRef ref,
    models.PlayerState playerState,
    ThemeData theme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Skip backward
        IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 28,
          color: theme.colorScheme.onSurface,
          onPressed: () {
            ref.read(audioPlayerProvider.notifier).playPrevious();
          },
        ),
        // Play/Pause
        Container(
          width: 44,
          height: 44,
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
                size: 24,
              ),
            ),
          ),
        ),
        // Skip forward
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 28,
          color: theme.colorScheme.onSurface,
          onPressed: () {
            ref.read(audioPlayerProvider.notifier).playNext();
          },
        ),
      ],
    );
  }
}
