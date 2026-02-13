import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/artist_provider.dart';
import '../providers/follow_provider.dart';
import '../providers/activity_provider.dart';
import '../widgets/artist_card.dart';
import '../widgets/activity_item.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors_extension.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _discoverScrollController = ScrollController();
  final ScrollController _activityScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Setup infinite scroll for discover tab
    _discoverScrollController.addListener(() {
      if (_discoverScrollController.position.pixels >=
          _discoverScrollController.position.maxScrollExtent * 0.8) {
        ref.read(artistListProvider.notifier).loadMore();
      }
    });

    // Setup infinite scroll for activity feed
    _activityScrollController.addListener(() {
      if (_activityScrollController.position.pixels >=
          _activityScrollController.position.maxScrollExtent * 0.8) {
        ref.read(activityFeedProvider.notifier).loadMore();
      }
    });

    // Load following list
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      Future.microtask(() {
        ref.read(followingListProvider.notifier).setUserId(authState.user!['_id'] as String);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _discoverScrollController.dispose();
    _activityScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Following'),
            Tab(text: 'Discover'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFollowingTab(),
          _buildDiscoverTab(),
          _buildActivityTab(),
        ],
      ),
    );
  }

  Widget _buildFollowingTab() {
    final followingAsync = ref.watch(followingListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return followingAsync.when(
      data: (following) {
        if (following.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: isDark ? Colors.white.withOpacity(0.3) : Colors.black26,
                ),
                const SizedBox(height: 16),
                Text(
                  'Not following anyone yet',
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('Discover Artists'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(followingListProvider.notifier).fetchFollowing(refresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: following.length,
            itemBuilder: (context, index) {
              return ArtistCard(
                artist: following[index],
                onFollowChanged: () {
                  ref.read(followingListProvider.notifier).fetchFollowing(refresh: true);
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load following list',
                style: TextStyle(
                  color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.refresh(followingListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscoverTab() {
    final artistsAsync = ref.watch(artistListProvider);
    final selectedSort = ref.watch(selectedArtistSortProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Search and filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(artistSearchQueryProvider.notifier).state = value;
                  ref.read(artistListProvider.notifier).refresh();
                },
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search artists...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.5) : Colors.black45,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white.withOpacity(0.7) : Colors.black54,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Sort chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSortChip('Most Followers', 'followerCount', selectedSort),
                    const SizedBox(width: 8),
                    _buildSortChip('Most Songs', 'songCount', selectedSort),
                    const SizedBox(width: 8),
                    _buildSortChip('Latest', 'latest', selectedSort),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Artist list
        Expanded(
          child: artistsAsync.when(
            data: (artists) {
              if (artists.isEmpty) {
                return Center(
                  child: Text(
                    'No artists found',
                    style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref.read(artistListProvider.notifier).refresh(),
                child: ListView.builder(
                  controller: _discoverScrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: artists.length,
                  itemBuilder: (context, index) {
                    return ArtistCard(
                      artist: artists[index],
                      onFollowChanged: () {
                        // Optionally refresh the list or update UI
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load artists',
                    style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.refresh(artistListProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTab() {
    final activityAsync = ref.watch(activityFeedProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return activityAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timeline,
                  size: 64,
                  color: isDark ? Colors.white.withOpacity(0.3) : Colors.black26,
                ),
                const SizedBox(height: 16),
                Text(
                  'No activities yet',
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Follow artists to see their activities',
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.4) : Colors.black38,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(activityFeedProvider.notifier).refresh(),
          child: ListView.builder(
            controller: _activityScrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              return ActivityItem(activity: activities[index]);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load activity feed',
              style: TextStyle(
                color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.refresh(activityFeedProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value, String selectedValue) {
    final isSelected = value == selectedValue;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(selectedArtistSortProvider.notifier).state = value;
        ref.read(artistListProvider.notifier).refresh();
      },
      backgroundColor: theme.colorScheme.surfaceVariant2,
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected 
            ? Colors.white 
            : (isDark ? Colors.white.withOpacity(0.7) : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
