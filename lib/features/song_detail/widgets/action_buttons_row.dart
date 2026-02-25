import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/models/song_model.dart';
import '../../player/providers/audio_player_provider.dart';
import '../../engagement/providers/like_provider.dart';
import '../../engagement/widgets/share_bottom_sheet.dart';
import '../../engagement/widgets/comments_bottom_sheet.dart';

/// YouTube-style action buttons for song detail screen
class ActionButtonsRow extends ConsumerWidget {
  final SongModel song;
  final List<SongModel>? allSongs;

  const ActionButtonsRow({
    super.key,
    required this.song,
    this.allSongs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentSong = ref.watch(currentSongProvider);
    final playerState = ref.watch(audioPlayerProvider);
    final isCurrentSong = currentSong?.id == song.id;
    final isPlaying = isCurrentSong && playerState.isPlaying;
    final likeState = ref.watch(likeProvider(song.id));

    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: [
        // Play/Pause Button
        _PrimaryButton(
          icon: isPlaying ? Icons.pause : Icons.play_arrow,
          label: isPlaying ? 'Pause' : 'Play',
          onPressed: () {
            if (isCurrentSong) {
              ref.read(audioPlayerProvider.notifier).playPause();
            } else {
              ref.read(audioPlayerProvider.notifier).playSongWithQueue(
                    song,
                    allSongs ?? [song],
                  );
            }
          },
          theme: theme,
        ),

        // Like/Dislike Connected Buttons
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF272727),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Like Button
              _IconButton(
                icon: likeState.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                label: likeState.likeCount > 0 ? '${likeState.likeCount}' : null,
                isActive: likeState.isLiked,
                onPressed: likeState.isLoading
                    ? null
                    : () => ref.read(likeProvider(song.id).notifier).toggleLike(),
              ),
              Container(
                width: 1,
                height: 24,
                color: Colors.white.withOpacity(0.1),
              ),
              // Dislike Button
              _IconButton(
                icon: likeState.isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                isActive: likeState.isDisliked,
                onPressed: likeState.isLoading
                    ? null
                    : () => ref.read(likeProvider(song.id).notifier).toggleDislike(),
              ),
            ],
          ),
        ),

        // Comment Button
        _SecondaryButton(
          icon: Icons.comment_outlined,
          label: song.commentCount > 0 ? '${song.commentCount}' : 'Comment',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => CommentsBottomSheet(song: song),
            );
          },
        ),

        // Share Button
        _SecondaryButton(
          icon: Icons.share_outlined,
          label: 'Share',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => ShareBottomSheet(song: song),
            );
          },
        ),
      ],
    );
  }
}

/// Primary action button (Play/Pause)
class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final ThemeData theme;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
      ),
    );
  }
}

/// Secondary action button (Comment, Share)
class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF272727),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon-only button for like/dislike
class _IconButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool isActive;
  final VoidCallback? onPressed;

  const _IconButton({
    required this.icon,
    this.label,
    this.isActive = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.blue : Colors.white,
              ),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: TextStyle(
                    color: isActive ? Colors.blue : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
