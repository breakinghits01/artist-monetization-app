import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../player/models/song_model.dart';
import '../../../player/data/sample_songs.dart';
import '../../../player/providers/audio_player_provider.dart';
import '../../providers/liked_songs_provider.dart';
import '../../providers/user_songs_provider.dart';
import '../../models/user_profile_model.dart';
import '../../widgets/profile_header.dart';
import '../../widgets/song_card.dart';
import '../../../playlist/widgets/add_to_playlist_sheet.dart';
import '../../../playlist/providers/playlists_provider.dart';
import '../../../playlist/widgets/create_playlist_dialog.dart';
import '../../../playlist/screens/playlist_detail_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'Recent';
  
  // Cache sorted songs to prevent re-shuffling on rebuild
  List<SongModel>? _cachedSortedSongs;
  String? _lastSortBy;
  
  final UserProfile _profile = MockUserProfile.profile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        // Load playlists when switching to playlists tab
        if (_tabController.index == 2) {
          Future.microtask(() {
            ref.read(playlistsProvider.notifier).loadPlaylists();
          });
        }
      }
    });
    
    // Load playlists on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playlistsProvider.notifier).loadPlaylists();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleSongPlay(SongModel song) {
    // Play the song through the audio player
    ref.read(audioPlayerProvider.notifier).playSong(song);
  }

  void _handleSongLike(SongModel song) {
    // Toggle like state in provider
    ref.read(likedSongsProvider.notifier).toggleLike(song.id);
  }

  void _handleSongOptions(SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSongOptionsSheet(song),
    );
  }

  void _handleEditProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit Profile - Coming Soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<SongModel> _getSortedSongs() {
    // Get songs from provider (uploaded songs only)
    final userSongsState = ref.watch(userSongsProvider);
    final uploadedSongs = userSongsState.songs;
    
    debugPrint('🎵 Uploaded songs count: ${uploadedSongs.length}');
    if (uploadedSongs.isNotEmpty) {
      debugPrint('🎵 First uploaded song: ${uploadedSongs.first.title}');
    }
    
    // Show ONLY uploaded songs (no sample songs)
    final allSongs = uploadedSongs;
    
    debugPrint('🎵 Total songs to display: ${allSongs.length}');
    
    // Return cached songs if sort hasn't changed AND song count matches
    if (_cachedSortedSongs != null && 
        _lastSortBy == _sortBy && 
        _cachedSortedSongs!.length == allSongs.length) {
      return _cachedSortedSongs!;
    }
    
    final songs = List<SongModel>.from(allSongs);
    switch (_sortBy) {
      case 'Most Played':
        // TODO: Add playCount to SongModel or use analytics
        // For now, keep original order (don't shuffle)
        break;
      case 'A-Z':
        songs.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Recent':
      default:
        // Keep original order (newest first)
        // Don't shuffle - maintain stable order
        break;
    }
    
    // Cache the result
    _cachedSortedSongs = songs;
    _lastSortBy = _sortBy;
    
    return songs;
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear cache when widget updates
    _cachedSortedSongs = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            title: Text(
              'Profile',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // Refresh button for debugging uploaded songs
              Consumer(
                builder: (context, ref, _) {
                  return IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      // Force refresh songs from backend
                      await ref.read(userSongsProvider.notifier).refresh();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Songs refreshed from server'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {},
              ),
            ],
          ),
          // Profile Header
          SliverToBoxAdapter(
            child: ProfileHeader(
              profile: _profile,
              onEditProfile: _handleEditProfile,
              isOwnProfile: true,
            ),
          ),
          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              tabBar: Container(
                color: theme.scaffoldBackgroundColor,
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      indicatorColor: theme.colorScheme.primary,
                      indicatorWeight: 3,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor:
                          theme.colorScheme.onSurface.withOpacity(0.6),
                      tabs: const [
                        Tab(text: 'My Songs'),
                        Tab(text: 'Liked'),
                        Tab(text: 'Playlists'),
                      ],
                    ),
                    // Sort Options
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Sort by:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildSortChip('Recent'),
                          const SizedBox(width: 8),
                          _buildSortChip('Most Played'),
                          const SizedBox(width: 8),
                          _buildSortChip('A-Z'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              sortBy: _sortBy, // Pass sortBy to delegate
            ),
          ),
          // Tab Content
          if (_tabController.index == 0)
            ..._buildSongsSliverGrid()
          else if (_tabController.index == 1)
            SliverToBoxAdapter(
              child: _buildEmptyState(
                icon: Icons.favorite_border,
                title: 'No Liked Songs',
                subtitle: 'Songs you like will appear here',
              ),
            )
          else
            _buildPlaylistsTab(),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label) {
    final theme = Theme.of(context);
    final isSelected = _sortBy == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = label;
          // Clear cache to force re-sort
          _cachedSortedSongs = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSongsSliverGrid() {
    final sortedSongs = _getSortedSongs();
    final currentSong = ref.watch(currentSongProvider);
    final likedSongIds = ref.watch(likedSongsProvider);
    
    // Show empty state if no songs
    if (sortedSongs.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _buildEmptyState(
            icon: Icons.music_note_outlined,
            title: 'No Songs Yet',
            subtitle: 'Upload your first song to get started',
          ),
        ),
      ];
    }
    
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final song = sortedSongs[index];
              final isCurrentlyPlaying = currentSong?.id == song.id;
              final isLiked = likedSongIds.contains(song.id);
              
              return _buildSongListItem(
                song: song,
                isCurrentlyPlaying: isCurrentlyPlaying,
                isLiked: isLiked,
              );
            },
            childCount: sortedSongs.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildSongListItem({
    required SongModel song,
    required bool isCurrentlyPlaying,
    required bool isLiked,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: isCurrentlyPlaying 
            ? LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.15),
                  theme.colorScheme.primary.withOpacity(0.05),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isCurrentlyPlaying ? null : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentlyPlaying 
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          if (isCurrentlyPlaying)
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.secondary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: song.albumArt != null && song.albumArt!.isNotEmpty
                    ? Image.network(
                        song.albumArt!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.music_note,
                            color: theme.colorScheme.primary,
                            size: 30,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      )
                    : Icon(
                        Icons.music_note,
                        color: theme.colorScheme.primary,
                        size: 30,
                      ),
              ),
            ),
            if (isCurrentlyPlaying)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.pause_circle_filled,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          song.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isCurrentlyPlaying ? FontWeight.bold : FontWeight.w500,
            color: isCurrentlyPlaying ? theme.colorScheme.primary : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (song.genre != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  song.genre!,
                  style: theme.textTheme.labelSmall,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _formatDuration(song.duration),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (song.tokenReward != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '+${song.tokenReward}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : null,
                size: 20,
              ),
              onPressed: () => _handleSongLike(song),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              onPressed: () => _handleSongOptions(song),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        onTap: () => _handleSongPlay(song),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Icon(
              icon,
              size: 60,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongOptionsSheet(SongModel song) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
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
                color: theme.colorScheme.onSurface.withOpacity(0.3),
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

// Sticky Tab Bar Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;
  final String sortBy;

  _StickyTabBarDelegate({required this.tabBar, required this.sortBy});

  @override
  double get minExtent => 105;

  @override
  double get maxExtent => 105;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return tabBar;
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return sortBy != oldDelegate.sortBy;
  }
}

// Playlists tab widget
extension _PlaylistsTab on _ProfileScreenState {
  Widget _buildPlaylistsTab() {
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
                color: theme.colorScheme.primary.withOpacity(0.3),
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
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
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
            return _buildPlaylistListItem(playlist);
          },
          childCount: playlistsState.playlists.length,
        ),
      ),
    );
  }

  Widget _buildPlaylistListItem(playlist) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08),
            theme.colorScheme.secondary.withOpacity(isDark ? 0.1 : 0.05),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Playlist icon with gradient background
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.8),
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.playlist_play,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                // Playlist info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.music_note,
                            size: 16,
                            color: theme.colorScheme.primary.withOpacity(0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${playlist.songCount} ${playlist.songCount == 1 ? 'song' : 'songs'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // More options button
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  onPressed: () {
                    _showPlaylistOptions(playlist);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlaylistOptions(playlist) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                title: const Text('Edit Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Edit playlist
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: theme.colorScheme.primary),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Share playlist
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePlaylist(playlist);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePlaylist(playlist) async {
    if (!mounted) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Delete "${playlist.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      try {
        await ref.read(playlistsProvider.notifier).deletePlaylist(playlist.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Playlist deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
