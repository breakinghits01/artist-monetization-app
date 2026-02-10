import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/audio_player_provider.dart';
import '../models/song_model.dart';
import '../models/player_state.dart' as models;
import '../../../shared/widgets/token_icon.dart';
import 'glass_container.dart';

/// Full player screen with expanded controls
class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(currentSongProvider);

    if (song == null) {
      // Close player if no song
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(playerExpandedProvider.notifier).state = false;
      });
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context),
        body: _buildBody(context, song),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down, size: 32),
        onPressed: () => _closePlayer(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            _showMoreOptions(context);
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, SongModel song) {
    final theme = Theme.of(context);
    final playerState = ref.watch(audioPlayerProvider);
    final tokenState = ref.watch(tokenEarnProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withOpacity(0.3),
            theme.colorScheme.surface,
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Album art
              _buildAlbumArt(song, theme, playerState.isPlaying),
              const SizedBox(height: 32),
              // Song info
              _buildSongInfo(song, theme, ref),
              const SizedBox(height: 24),
              // Token progress ring
              if (tokenState.progress > 0)
                _buildTokenProgress(context, theme, tokenState, song),
              const SizedBox(height: 24),
              // Progress slider
              _buildProgressSlider(context, ref, playerState, theme),
              const SizedBox(height: 32),
              // Main controls
              _buildMainControls(ref, playerState, theme),
              const SizedBox(height: 24),
              // Secondary controls
              _buildSecondaryControls(ref, playerState, theme),
              const SizedBox(height: 24),
              // Action buttons
              _buildActionButtons(context, ref, song, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(SongModel song, ThemeData theme, bool isPlaying) {
    return Hero(
      tag: 'album_art_${song.id}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.4),
              blurRadius: 40,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Album image
              if (song.albumArt != null)
                CachedNetworkImage(
                  imageUrl: song.albumArt!,
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildAlbumPlaceholder(theme),
                  errorWidget: (context, url, error) =>
                      _buildAlbumPlaceholder(theme),
                )
              else
                _buildAlbumPlaceholder(theme),
              // Playing animation overlay
              if (isPlaying)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.0),
                          theme.colorScheme.primary.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumPlaceholder(ThemeData theme) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
      ),
      child: Icon(
        Icons.music_note,
        size: 120,
        color: theme.colorScheme.onPrimary.withOpacity(0.8),
      ),
    );
  }

  Widget _buildSongInfo(SongModel song, ThemeData theme, WidgetRef ref) {
    return Column(
      children: [
        Text(
          song.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                // Navigate to artist profile
              },
              child: Text(
                song.artist,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                'Follow',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTokenProgress(
    BuildContext context,
    ThemeData theme,
    models.TokenEarnState tokenState,
    SongModel song,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Token icon
          const TokenIcon(size: 32, withShadow: false),
          const SizedBox(width: 12),
          // Progress info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tokenState.hasRewarded
                          ? '+${tokenState.tokensEarned} tokens earned!'
                          : 'Earn ${song.tokenReward} tokens',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: tokenState.progress,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(
                      0.1,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      tokenState.hasRewarded
                          ? theme.colorScheme.secondary
                          : const Color(0xFFFFD700),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tokenState.hasRewarded
                      ? 'Completed!'
                      : 'Listen to 80% to earn',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider(
    BuildContext context,
    WidgetRef ref,
    models.PlayerState playerState,
    ThemeData theme,
  ) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(0.1),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withOpacity(0.2),
          ),
          child: Slider(
            value: playerState.position.inMilliseconds.toDouble(),
            max: playerState.duration.inMilliseconds.toDouble().clamp(
              1.0,
              double.infinity,
            ),
            onChanged: (value) {
              ref
                  .read(audioPlayerProvider.notifier)
                  .seek(Duration(milliseconds: value.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                playerState.formattedPosition,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                playerState.formattedDuration,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainControls(
    WidgetRef ref,
    models.PlayerState playerState,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        IconButton(
          icon: Icon(
            Icons.shuffle,
            color: playerState.shuffleMode
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          iconSize: 28,
          onPressed: () {
            ref.read(audioPlayerProvider.notifier).toggleShuffle();
          },
        ),
        // Previous
        IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 40,
          color: theme.colorScheme.onSurface,
          onPressed: () {
            // TODO: Previous song
          },
        ),
        // Play/Pause
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
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
              child: Center(
                child: Icon(
                  playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ),
        // Next
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 40,
          color: theme.colorScheme.onSurface,
          onPressed: () {
            // TODO: Next song
          },
        ),
        // Repeat
        IconButton(
          icon: Icon(
            playerState.loopMode == LoopMode.off
                ? Icons.repeat
                : playerState.loopMode == LoopMode.one
                ? Icons.repeat_one
                : Icons.repeat,
            color: playerState.loopMode != LoopMode.off
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          iconSize: 28,
          onPressed: () {
            ref.read(audioPlayerProvider.notifier).toggleLoopMode();
          },
        ),
      ],
    );
  }

  Widget _buildSecondaryControls(
    WidgetRef ref,
    models.PlayerState playerState,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10),
          iconSize: 28,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          onPressed: () {
            ref.read(audioPlayerProvider.notifier).skipBackward();
          },
        ),
        IconButton(
          icon: const Icon(Icons.forward_10),
          iconSize: 28,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          onPressed: () {
            ref.read(audioPlayerProvider.notifier).skipForward();
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    SongModel song,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          context,
          icon: Icons.favorite_border,
          label: 'Like',
          onTap: () {
            // TODO: Like song
          },
        ),
        _buildActionButton(
          context,
          icon: Icons.add_to_queue,
          label: 'Queue',
          onTap: () {
            // TODO: Add to queue
          },
        ),
        _buildActionButton(
          context,
          icon: Icons.playlist_add,
          label: 'Playlist',
          onTap: () {
            // TODO: Add to playlist
          },
        ),
        _buildActionButton(
          context,
          icon: Icons.share,
          label: 'Share',
          onTap: () {
            // TODO: Share song
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.onSurface.withOpacity(0.1),
            ),
            child: Icon(icon, color: theme.colorScheme.onSurface, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _closePlayer() async {
    // Reverse animation before closing
    await _controller.reverse();
    if (mounted) {
      ref.read(playerExpandedProvider.notifier).state = false;
    }
  }

  void _showMoreOptions(BuildContext context) {
    // TODO: Show bottom sheet with more options
  }
}
