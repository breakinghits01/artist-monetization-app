import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../player/models/song_model.dart';
import '../../../playlist/widgets/add_to_playlist_sheet.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/user_songs_provider.dart';

/// Bottom sheet for song options (add to playlist, share, download, info, delete)
class SongOptionsSheet extends ConsumerWidget {
  final SongModel song;

  const SongOptionsSheet({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Check if current user owns this song
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?['_id'] ?? currentUser?['id'];
    final isOwner = userId != null && song.artistId == userId;
    
    // Debug logging
    print('🔍 Delete Option Check:');
    print('   Current User: $currentUser');
    print('   User ID: $userId');
    print('   Song Artist ID: ${song.artistId}');
    print('   Is Owner: $isOwner');
    print('   Song Title: ${song.title}');

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
            // Show delete option only for song owner
            if (isOwner) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Song', style: TextStyle(color: Colors.red)),
                subtitle: const Text('This cannot be undone', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, ref);
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Show confirmation dialog before deleting song
  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref) async {
    print('🗑️ _showDeleteConfirmation called');
    
    // Capture ScaffoldMessenger and notifier before dialog to avoid context/ref issues after disposal
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final userSongsNotifier = ref.read(userSongsProvider.notifier);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text(
          'Delete "${song.title}"?\n\nThis will permanently remove the song from your profile and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('❌ User clicked Cancel');
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              print('✅ User clicked Delete - confirming');
              Navigator.of(dialogContext).pop(true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    print('🔍 Confirmed: $confirmed');

    if (confirmed == true) {
      print('🚀 Starting deletion process...');
      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Deleting song...'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 10), // Will be dismissed when done
        ),
      );

      try {
        print('📞 Calling deleteSong for ID: ${song.id}');
        // Call delete method from provider (using captured notifier to avoid ref after disposal)
        await userSongsNotifier.deleteSong(song.id);
        
        print('✅ deleteSong completed successfully');
        
        // Dismiss loading snackbar
        scaffoldMessenger.hideCurrentSnackBar();
        
        // Show success message
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('"${song.title}" deleted successfully'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e) {
        print('❌ Error in delete flow: $e');
        print('❌ Error type: ${e.runtimeType}');
        
        // Dismiss loading snackbar
        scaffoldMessenger.hideCurrentSnackBar();
        
        // Show error message
        scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(e.toString().replaceFirst('Exception: ', '')),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _showDeleteConfirmation(context, ref),
              ),
            ),
          );
      }
    }
  }
}
