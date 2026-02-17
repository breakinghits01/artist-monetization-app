import 'package:flutter/material.dart';
import '../../../player/models/song_model.dart';
import '../../../playlist/widgets/add_to_playlist_sheet.dart';

/// Bottom sheet for song options (add to playlist, share, download, info)
class SongOptionsSheet extends StatelessWidget {
  final SongModel song;

  const SongOptionsSheet({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.add_to_photos, color: theme.colorScheme.primary),
              title: const Text('Add to Playlist'),
              subtitle: const Text('Add this song to a playlist'),
              onTap: () {
                Navigator.pop(context); // Close options sheet
                // Show add to playlist sheet
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AddToPlaylistSheet(songId: song.id),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: theme.colorScheme.secondary),
              title: const Text('Share'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.download, color: theme.colorScheme.secondary),
              title: const Text('Download'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF9C27B0)),
              title: const Text('Song Info'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
