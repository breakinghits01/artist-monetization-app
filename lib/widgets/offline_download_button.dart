import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_download_manager.dart';
import '../services/providers/offline_download_provider.dart';
import '../features/player/models/song_model.dart' as player;

/// Offline download button widget (Spotify-like)
/// Shows: Download icon → Circular progress → Green checkmark
class OfflineDownloadButton extends ConsumerWidget {
  final String songId;
  final String songTitle;
  final String artistName;
  final String artistId;
  final String? albumArt;
  final String audioUrl;
  final Duration duration;
  final double iconSize;
  final Color? iconColor;

  const OfflineDownloadButton({
    Key? key,
    required this.songId,
    required this.songTitle,
    required this.artistName,
    required this.artistId,
    this.albumArt,
    required this.audioUrl,
    required this.duration,
    this.iconSize = 24.0,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hide on web - offline downloads not supported
    if (kIsWeb) {
      return const SizedBox.shrink();
    }
    
    final status = ref.watch(songDownloadStatusProvider(songId));
    final progress = ref.watch(songDownloadProgressProvider(songId));
    final theme = Theme.of(context);

    switch (status) {
      case OfflineDownloadStatus.notDownloaded:
        return IconButton(
          icon: Icon(
            Icons.download_outlined,
            size: iconSize,
            color: iconColor ?? theme.iconTheme.color,
          ),
          onPressed: () => _handleDownload(context, ref),
          tooltip: 'Download for offline',
        );

      case OfflineDownloadStatus.downloading:
        return SizedBox(
          width: iconSize + 16,
          height: iconSize + 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: iconSize * 0.5,
                  color: theme.iconTheme.color?.withOpacity(0.7),
                ),
                onPressed: () => _handleCancel(ref),
                tooltip: 'Cancel download',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );

      case OfflineDownloadStatus.downloaded:
        return IconButton(
          icon: Icon(
            Icons.check_circle,
            size: iconSize,
            color: Colors.green,
          ),
          onPressed: () => _showDownloadedOptions(context, ref),
          tooltip: 'Downloaded',
        );

      case OfflineDownloadStatus.failed:
        return IconButton(
          icon: Icon(
            Icons.error_outline,
            size: iconSize,
            color: Colors.red,
          ),
          onPressed: () => _handleRetry(context, ref),
          tooltip: 'Download failed - tap to retry',
        );
      default:
        return IconButton(
          icon: Icon(
            Icons.download_outlined,
            size: iconSize,
            color: iconColor ?? theme.iconTheme.color,
          ),
          onPressed: () => _handleDownload(context, ref),
          tooltip: 'Download for offline',
        );
    }
  }

  void _handleDownload(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(offlineDownloadStateProvider.notifier);
    
    // Create SongModel for download
    final song = player.SongModel(
      id: songId,
      title: songTitle,
      artist: artistName,
      artistId: artistId,
      albumArt: albumArt,
      audioUrl: audioUrl,
      duration: duration,
    );
    
    final success = await notifier.downloadSong(song);
    
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download "$songTitle"'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleCancel(WidgetRef ref) {
    final notifier = ref.read(offlineDownloadStateProvider.notifier);
    notifier.cancelDownload(songId);
  }

  void _handleRetry(BuildContext context, WidgetRef ref) {
    _handleDownload(context, ref);
  }

  void _showDownloadedOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Downloaded'),
              subtitle: const Text('Available offline'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove download'),
              onTap: () {
                Navigator.pop(context);
                _handleDelete(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove download?'),
        content: Text('Remove "$songTitle" from offline downloads?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(offlineDownloadStateProvider.notifier);
      final success = await notifier.deleteDownload(songId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Download removed'
                  : 'Failed to remove download',
            ),
            backgroundColor: success ? null : Colors.red,
          ),
        );
      }
    }
  }
}
