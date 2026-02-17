import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../playlist/providers/playlists_provider.dart';
import '../../../playlist/widgets/create_playlist_dialog.dart';
import '../../../playlist/screens/playlist_detail_screen.dart';
import '../widgets/playlist_list_item.dart';

/// Playlists tab widget for profile screen
class PlaylistsTab extends ConsumerWidget {
  final VoidCallback onShowPlaylistOptions;

  const PlaylistsTab({
    super.key,
    required this.onShowPlaylistOptions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsState = ref.watch(playlistsProvider);
    final theme = Theme.of(context);

    if (playlistsState.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (playlistsState.error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${playlistsState.error}'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ref.read(playlistsProvider.notifier).loadPlaylists();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (playlistsState.playlists.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.playlist_play,
                size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'No Playlists',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first playlist',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => const CreatePlaylistDialog(),
                  );
                  if (result == true) {
                    ref.read(playlistsProvider.notifier).loadPlaylists();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Playlist'),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final playlist = playlistsState.playlists[index];
            return PlaylistListItem(
              playlist: playlist,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistDetailScreen(
                      playlistId: playlist.id,
                      playlistName: playlist.name,
                    ),
                  ),
                );
              },
              onOptions: () {
                // This callback will be provided by parent
                // For now, we'll use a simple implementation
                // The parent can inject the _showPlaylistOptions method
              },
            );
          },
          childCount: playlistsState.playlists.length,
        ),
      ),
    );
  }
}
