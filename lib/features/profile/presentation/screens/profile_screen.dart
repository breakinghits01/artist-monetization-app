import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../player/models/song_model.dart';
import '../../../player/data/sample_songs.dart';
import '../../../player/providers/audio_player_provider.dart';
import '../../providers/liked_songs_provider.dart';
import '../../providers/user_songs_provider.dart';
import '../../models/user_profile_model.dart';
import '../../widgets/profile_header.dart';
import '../../widgets/song_card.dart';

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
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleSongPlay(SongModel song) {
    // Actually play the song through the audio player
    ref.read(audioPlayerProvider.notifier).playSong(song);
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.play_circle_filled, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Playing: ${song.title}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
    // Get songs from provider (uploaded songs + sample songs)
    final userSongsState = ref.watch(userSongsProvider);
    final uploadedSongs = userSongsState.songs;
    
    // Combine uploaded songs with sample songs (for demo purposes)
    final allSongs = [...uploadedSongs, ...SampleSongs.songs];
    
    // Return cached songs if sort hasn't changed
    if (_cachedSortedSongs != null && _lastSortBy == _sortBy) {
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
            SliverToBoxAdapter(
              child: _buildEmptyState(
                icon: Icons.playlist_play,
                title: 'No Playlists',
                subtitle: 'Create your first playlist',
              ),
            ),
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
    
    return [
      SliverPadding(
        padding: const EdgeInsets.all(24),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.crossAxisExtent > 900
                ? 4
                : constraints.crossAxisExtent > 600
                    ? 3
                    : 2;

            return SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = sortedSongs[index];
                  final isCurrentlyPlaying = currentSong?.id == song.id;
                  final isLiked = likedSongIds.contains(song.id);
                  
                  return SongCard(
                    song: song,
                    isCurrentlyPlaying: isCurrentlyPlaying,
                    isLiked: isLiked,
                    onPlay: () => _handleSongPlay(song),
                    onLike: () => _handleSongLike(song),
                    onOptions: () => _handleSongOptions(song),
                  );
                },
                childCount: sortedSongs.length,
              ),
            );
          },
        ),
      ),
    ];
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
              subtitle: const Text('Coming soon'),
              onTap: () => Navigator.pop(context),
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
    return sortBy != oldDelegate.sortBy; // Rebuild when sort changes
  }
}
