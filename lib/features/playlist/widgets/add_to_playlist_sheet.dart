import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/playlists_provider.dart';
import 'create_playlist_dialog.dart';

class AddToPlaylistSheet extends ConsumerStatefulWidget {
  final String songId;

  const AddToPlaylistSheet({
    super.key,
    required this.songId,
  });

  @override
  ConsumerState<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<AddToPlaylistSheet> {
  @override
  void initState() {
    super.initState();
    // Load playlists when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playlistsProvider.notifier).loadPlaylists();
    });
  }

  Future<void> _addToPlaylist(String playlistId, String playlistName) async {
    try {
      await ref.read(playlistsProvider.notifier).addSongToPlaylist(
            playlistId,
            widget.songId,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to "$playlistName"'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('already')
                ? 'Song already in this playlist'
                : 'Failed to add song'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _createNewPlaylist() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreatePlaylistDialog(songId: widget.songId),
    );

    if (result == true && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlist created and song added'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistsState = ref.watch(playlistsProvider);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.playlist_add, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Add to Playlist',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Create new playlist button
          ListTile(
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
            title: const Text('Create New Playlist'),
            subtitle: const Text('Start a new collection'),
            onTap: _createNewPlaylist,
          ),

          const Divider(height: 1),

          // Playlists list
          if (playlistsState.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else if (playlistsState.playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.playlist_play,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No playlists yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first playlist above',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: playlistsState.playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlistsState.playlists[index];
                  final isSongInPlaylist = ref
                      .read(playlistsProvider.notifier)
                      .isSongInPlaylist(playlist.id, widget.songId);

                  return ListTile(
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        image: playlist.coverImage != null
                            ? DecorationImage(
                                image: NetworkImage(playlist.coverImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: playlist.coverImage == null
                          ? Icon(
                              Icons.music_note,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            )
                          : null,
                    ),
                    title: Text(
                      playlist.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${playlist.songCount} song${playlist.songCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    trailing: isSongInPlaylist
                        ? Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    enabled: !isSongInPlaylist,
                    onTap: isSongInPlaylist
                        ? null
                        : () => _addToPlaylist(playlist.id, playlist.name),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
