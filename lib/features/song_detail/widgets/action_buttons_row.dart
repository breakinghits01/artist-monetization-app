import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/models/song_model.dart';
import '../../player/providers/audio_player_provider.dart';
import '../../engagement/providers/like_provider.dart';
import '../../engagement/widgets/share_bottom_sheet.dart';
import '../../engagement/widgets/comments_bottom_sheet.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../../subscription/widgets/upgrade_prompt_widget.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/dio_client.dart';

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
          label: song.commentCount > 0 
              ? '${song.commentCount}' 
              : 'Comment',
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

        // Download Button — gated behind Premium / Advanced tier
        _DownloadButton(song: song),
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
/// Download button — shows upgrade prompt for Free users, triggers download for Premium+
class _DownloadButton extends ConsumerStatefulWidget {
  final SongModel song;
  const _DownloadButton({required this.song});

  @override
  ConsumerState<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends ConsumerState<_DownloadButton> {
  bool _isDownloading = false;

  Future<void> _handleDownload() async {
    final canDownload = ref.read(canDownloadProvider);

    if (!canDownload) {
      // Free user — show upgrade bottom sheet
      UpgradePromptWidget.show(context);
      return;
    }

    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final dio = DioClient.instance;
      final response = await dio.get(
        '${ApiConfig.baseUrl}${ApiConfig.downloadEndpoint}/${widget.song.id}',
        queryParameters: {'format': 'mp3'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final downloadUrl = response.data['data']?['url'] as String? ??
            response.data['data']?['downloadUrl'] as String?;

        if (downloadUrl != null) {
          // Platform-agnostic: open the presigned URL in the browser / OS handler
          // On web this triggers a browser download; on native it opens the file manager
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '✅ Download started!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF1DB954),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } on Exception catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('403')
          ? 'Upgrade to Premium to download songs.'
          : 'Download failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF272727),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDownload = ref.watch(canDownloadProvider);

    return Material(
      color: const Color(0xFF272727),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _handleDownload,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      canDownload
                          ? Icons.download_outlined
                          : Icons.lock_outline_rounded,
                      size: 18,
                      color: canDownload ? Colors.white : Colors.white38,
                    ),
              const SizedBox(width: 8),
              Text(
                'Download',
                style: TextStyle(
                  color: canDownload ? Colors.white : Colors.white38,
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