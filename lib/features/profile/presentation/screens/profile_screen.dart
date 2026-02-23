import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../player/models/song_model.dart';
import '../../../player/providers/audio_player_provider.dart';
import '../../providers/liked_songs_provider.dart';
import '../../providers/user_songs_provider.dart';
import '../../models/user_profile_model.dart';
import '../../widgets/profile_header.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../playlist/providers/playlists_provider.dart';
import '../../../playlist/widgets/create_playlist_dialog.dart';
import '../../../playlist/screens/playlist_detail_screen.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/sort_chip.dart';
import '../widgets/song_list_item.dart';
import '../widgets/song_options_sheet.dart';
import '../widgets/playlist_list_item.dart';

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

  void _handleSongPlay(SongModel song) async {
    try {
      // Get all songs for queue context
      final allSongs = _getSortedSongs();
      
      // Play the song with queue context
      await ref.read(audioPlayerProvider.notifier).playSongWithQueue(song, allSongs);
    } catch (e) {
      debugPrint('❌ Error in _handleSongPlay: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play song: ${song.title}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSongLike(SongModel song) {
    // Toggle like state in provider
    ref.read(likedSongsProvider.notifier).toggleLike(song.id);
  }

  void _handleSongOptions(SongModel song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SongOptionsSheet(song: song),
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
        // Sort by playCount descending (highest first)
        songs.sort((a, b) => b.playCount.compareTo(a.playCount));
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
            child: Consumer(
              builder: (context, ref, _) {
                final authState = ref.watch(authProvider);
                final user = authState.user;
                
                // Create UserProfile from auth data
                final profile = UserProfile(
                  id: user?['_id'] ?? '',
                  username: user?['username'] ?? 'User',
                  email: user?['email'] ?? '',
                  role: user?['role'] ?? 'fan',
                  bio: 'Music enthusiast 🎵 | Cyberpunk vibes | Love discovering new sounds',
                  avatarUrl: user?['avatar'],
                  coverPhotoUrl: 'https://picsum.photos/seed/cover1/1200/400',
                  followerCount: 1234,
                  followingCount: 567,
                  totalPlays: 185600,
                  songCount: 10,
                  joinDate: DateTime.now(),
                  favoriteGenres: ['Electronic', 'Rock', 'Hip Hop', 'Pop'],
                );
                
                return ProfileHeader(
                  profile: profile,
                  onEditProfile: _handleEditProfile,
                  isOwnProfile: true,
                );
              },
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
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SortChip(
                            label: 'Recent',
                            isSelected: _sortBy == 'Recent',
                            onTap: () => _updateSort('Recent'),
                          ),
                          const SizedBox(width: 8),
                          SortChip(
                            label: 'Most Played',
                            isSelected: _sortBy == 'Most Played',
                            onTap: () => _updateSort('Most Played'),
                          ),
                          const SizedBox(width: 8),
                          SortChip(
                            label: 'A-Z',
                            isSelected: _sortBy == 'A-Z',
                            onTap: () => _updateSort('A-Z'),
                          ),
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
            const SliverToBoxAdapter(
              child: EmptyStateWidget(
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

  List<Widget> _buildSongsSliverGrid() {
    final sortedSongs = _getSortedSongs();
    final currentSong = ref.watch(currentSongProvider);
    final likedSongIds = ref.watch(likedSongsProvider);
    
    // Show empty state if no songs
    if (sortedSongs.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: EmptyStateWidget(
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
              
              return SongListItem(
                song: song,
                isCurrentlyPlaying: isCurrentlyPlaying,
                isLiked: isLiked,
                onTap: () => _handleSongPlay(song),
                onLike: () => _handleSongLike(song),
                onOptions: () => _handleSongOptions(song),
              );
            },
            childCount: sortedSongs.length,
          ),
        ),
      ),
    ];
  }

  void _updateSort(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      // Clear cache to force re-sort
      _cachedSortedSongs = null;
    });
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
              onOptions: () => _showPlaylistOptions(playlist),
            );
          },
          childCount: playlistsState.playlists.length,
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
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
