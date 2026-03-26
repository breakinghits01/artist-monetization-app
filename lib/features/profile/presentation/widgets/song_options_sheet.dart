import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../player/models/song_model.dart';
import '../../../playlist/widgets/add_to_playlist_sheet.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/user_songs_provider.dart';
import '../../providers/liked_songs_provider.dart';
import 'song_info_dialog.dart';

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
            // Token Reward Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Token Reward',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '+${song.tokenReward} tokens per play',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Like/Unlike Option
            Consumer(
              builder: (context, ref, child) {
                final likedSongs = ref.watch(likedSongsProvider);
                final isLiked = likedSongs.contains(song.id);
                
                return ListTile(
                  leading: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : theme.colorScheme.secondary,
                  ),
                  title: Text(isLiked ? 'Unlike' : 'Like'),
                  subtitle: Text(isLiked ? 'Remove from liked songs' : 'Add to liked songs'),
                  onTap: () {
                    ref.read(likedSongsProvider.notifier).toggleLike(song.id);
                    Navigator.pop(context);
                  },
                );
              },
            ),
            const Divider(height: 1),
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
              subtitle: const Text('View song details'),
              onTap: () {
                Navigator.pop(context); // Close options sheet
                // Show song info dialog
                showDialog(
                  context: context,
                  builder: (context) => SongInfoDialog(song: song),
                );
              },
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
    
    // Capture theme, ScaffoldMessenger and notifier before dialog to avoid context/ref issues after disposal
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final userSongsNotifier = ref.read(userSongsProvider.notifier);
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1D2E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_forever,
                color: Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Delete Song',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.music_note,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      song.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This action cannot be undone',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('❌ User clicked Cancel');
              Navigator.of(dialogContext).pop(false);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              print('✅ User clicked Delete - confirming');
              Navigator.of(dialogContext).pop(true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline, size: 18),
                SizedBox(width: 8),
                Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    print('🔍 Confirmed: $confirmed');

    if (confirmed == true) {
      print('🚀 Starting deletion process...');
      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Deleting song...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: isDark ? const Color(0xFF2A2D3E) : const Color(0xFF424242),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 10), // Will be dismissed when done
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
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Song Deleted',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '"${song.title}" was removed',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
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
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Delete Failed',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          e.toString().replaceFirst('Exception: ', ''),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              onPressed: () => _showDeleteConfirmation(context, ref),
            ),
          ),
        );
      }
    }
  }
}
