import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../player/models/song_model.dart';
import '../../../player/providers/audio_player_provider.dart';
import '../../../artist/models/artist_model.dart';
import '../../../artist/providers/artist_provider.dart';
import '../../providers/public_user_profile_provider.dart';
import '../widgets/song_list_item.dart';
import '../widgets/empty_state_widget.dart';
import '../../../auth/providers/auth_provider.dart';

/// Public user profile screen for viewing other users' profiles
/// This is different from ProfileScreen which shows the current user's own profile
class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleSongPlay(SongModel song, List<SongModel> allSongs) async {
    try {
      await ref.read(audioPlayerProvider.notifier).playSongWithQueue(song, allSongs);
    } catch (e) {
      debugPrint('❌ Error playing song: $e');
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

  bool _isCurrentUser() {
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?['_id'] ?? currentUser?['id'];
    return currentUserId == widget.userId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(publicUserProfileProvider(widget.userId));
    final songsAsync = ref.watch(publicUserSongsProvider(widget.userId));

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
      data: (artist) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 900;
            
            return CustomScrollView(
                  slivers: [
                    // Banner - simple gradient container, no app bar
                    SliverToBoxAdapter(
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.9),
                              theme.colorScheme.secondary.withValues(alpha: 0.9),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text(
                              artist.username,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Profile content
                    if (isWideScreen)
                      // Desktop: Two-column layout
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height - 100,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left sidebar - Profile info
                              SizedBox(
                                width: 340,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: _buildProfileSidebar(artist, theme),
                                ),
                              ),
                              
                              // Divider
                              VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                              ),
                              
                              // Right content - Songs and About
                              Expanded(
                                child: _buildContentArea(songsAsync, artist, theme),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // Mobile: Vertical layout
                      ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: _buildProfileSidebar(artist, theme),
                          ),
                        ),
                        SliverFillRemaining(
                          child: _buildContentArea(songsAsync, artist, theme),
                        ),
                      ],
                  ],
                );
              },
            );
          },
        );
  }

  Widget _buildProfileSidebar(ArtistModel artist, ThemeData theme) {
    final followerCount = artist.followerCount;
    final followingCount = artist.followingCount;
    final songCount = artist.songCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        
        // Avatar - no overlap, just normal positioning
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.scaffoldBackgroundColor,
              width: 5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: theme.colorScheme.surfaceVariant,
            backgroundImage: artist.profilePicture != null
                ? CachedNetworkImageProvider(artist.profilePicture!)
                : null,
            child: artist.profilePicture == null
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
        ),

        const SizedBox(height: 20),

        // Bio
        if (artist.bio != null && artist.bio!.isNotEmpty) ...[
          Text(
            artist.bio!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
        ],

        // Stats in vertical cards
        _buildStatsCards(songCount, followerCount, followingCount, theme),

        const SizedBox(height: 20),

        // Action buttons
        if (!_isCurrentUser()) ...[
          SizedBox(
            width: double.infinity,
            child: _buildFollowButtonFull(artist.id, theme),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: _buildShareButtonFull(artist.username, theme),
        ),

        if (artist.createdAt != null) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Joined ${_formatDate(artist.createdAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatsCards(int songs, int followers, int following, ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Songs', songs.toString(), theme)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Followers', _formatNumber(followers), theme)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Following', _formatNumber(following), theme)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(AsyncValue<List<SongModel>> songsAsync, ArtistModel artist, ThemeData theme) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: const TabBar(
              tabs: [
                Tab(text: 'Songs'),
                Tab(text: 'About'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSongsTab(songsAsync, theme),
                _buildAboutTab(artist, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPhoto(ArtistModel artist) {
    // ArtistModel doesn't have coverPhotoUrl, use gradient as default
    return _buildDefaultCover();
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    ArtistModel artist,
    ThemeData theme,
  ) {
    final followerCount = artist.followerCount;
    final followingCount = artist.followingCount;
    final songCount = artist.songCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          // Avatar positioned to slightly overlap header
          Transform.translate(
            offset: const Offset(0, -50),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: theme.colorScheme.surfaceVariant,
                backgroundImage: artist.profilePicture != null
                    ? CachedNetworkImageProvider(artist.profilePicture!)
                    : null,
                child: artist.profilePicture == null
                    ? Icon(
                        Icons.person,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
            ),
          ),

          // Username and bio - reduced spacing since avatar is overlapping
          Transform.translate(
            offset: const Offset(0, -38),
            child: Column(
              children: [
                Text(
                  artist.username,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                
                if (artist.bio != null && artist.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      artist.bio!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Compact Stats Row with dividers
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCompactStatItem('Songs', songCount.toString(), theme),
                      _buildStatDivider(theme),
                      _buildCompactStatItem('Followers', _formatNumber(followerCount), theme),
                      _buildStatDivider(theme),
                      _buildCompactStatItem('Following', _formatNumber(followingCount), theme),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action buttons - Follow and Share (not offset, visible below stats)
          if (!_isCurrentUser()) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFollowButton(artist.id, theme),
                const SizedBox(width: 12),
                _buildShareButton(artist.username, theme),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            _buildShareButton(artist.username, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatItem(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(ThemeData theme) {
    return Container(
      height: 32,
      width: 1,
      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
    );
  }

  Widget _buildFollowButtonFull(String artistId, ThemeData theme) {
    final followStatusAsync = ref.watch(followStatusProvider(artistId));
    final followAction = ref.watch(followActionProvider(artistId));

    return followStatusAsync.when(
      loading: () => const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (isFollowing) {
        return SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: followAction.isLoading
                ? null
                : () {
                    ref
                        .read(followActionProvider(artistId).notifier)
                        .toggleFollow();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing
                  ? theme.colorScheme.surfaceVariant
                  : theme.colorScheme.primary,
              foregroundColor: isFollowing
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onPrimary,
              elevation: isFollowing ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: isFollowing
                    ? BorderSide(color: theme.colorScheme.outline.withOpacity(0.5))
                    : BorderSide.none,
              ),
            ),
            child: followAction.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildShareButtonFull(String username, ThemeData theme) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () async {
          final currentUrl = Uri.base.toString();
          await Clipboard.setData(ClipboardData(text: currentUrl));
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.onInverseSurface,
                    ),
                    const SizedBox(width: 12),
                    const Text('Profile link copied!'),
                  ],
                ),
                backgroundColor: theme.colorScheme.inverseSurface,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
        ),
        icon: Icon(
          Icons.share_outlined,
          size: 18,
          color: theme.colorScheme.onSurface,
        ),
        label: Text(
          'Share Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton(String artistId, ThemeData theme) {
    final followStatusAsync = ref.watch(followStatusProvider(artistId));
    final followAction = ref.watch(followActionProvider(artistId));

    return followStatusAsync.when(
      loading: () => const SizedBox(
        width: 140,
        height: 40,
        child: Center(child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (isFollowing) {
        return SizedBox(
          width: 140,
          height: 40,
          child: ElevatedButton(
            onPressed: followAction.isLoading
                ? null
                : () {
                    ref
                        .read(followActionProvider(artistId).notifier)
                        .toggleFollow();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing
                  ? theme.colorScheme.surfaceVariant
                  : theme.colorScheme.primary,
              foregroundColor: isFollowing
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onPrimary,
              elevation: isFollowing ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: isFollowing
                    ? BorderSide(color: theme.colorScheme.outline.withOpacity(0.5))
                    : BorderSide.none,
              ),
            ),
            child: followAction.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildShareButton(String username, ThemeData theme) {
    return SizedBox(
      width: 48,
      height: 40,
      child: OutlinedButton(
        onPressed: () async {
          final currentUrl = Uri.base.toString();
          await Clipboard.setData(ClipboardData(text: currentUrl));
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.onInverseSurface,
                    ),
                    const SizedBox(width: 12),
                    Text('Profile link copied to clipboard!'),
                  ],
                ),
                backgroundColor: theme.colorScheme.inverseSurface,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
        ),
        child: Icon(
          Icons.share_outlined,
          size: 20,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSongsTab(AsyncValue<List<SongModel>> songsAsync, ThemeData theme) {
    return songsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Failed to load songs',
          subtitle: error.toString(),
        ),
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(
            child: EmptyStateWidget(
              icon: Icons.music_note_outlined,
              title: 'No songs yet',
              subtitle: 'This user hasn\'t uploaded any songs',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final currentSong = ref.watch(currentSongProvider);
            final isCurrentlyPlaying = currentSong?.id == song.id;

            return SongListItem(
              song: song,
              isCurrentlyPlaying: isCurrentlyPlaying,
              isLiked: false, // TODO: Implement liked songs check
              onTap: () {
                _handleSongPlay(song, songs);
              },
              onLike: () {
                // TODO: Implement like functionality
              },
              onOptions: () {
                // TODO: Implement options sheet
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAboutTab(ArtistModel artist, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (artist.bio != null && artist.bio!.isNotEmpty) ...[
            Text(
              'About',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              artist.bio!,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
          ],

          if (artist.createdAt != null) ...[
            Text(
              'Member Since',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(artist.createdAt!),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
