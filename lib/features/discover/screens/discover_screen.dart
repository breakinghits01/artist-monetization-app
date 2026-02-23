import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/models/song_model.dart' as player_song;
import '../providers/song_provider.dart';
import '../widgets/song_list_tile.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  Timer? _debounceTimer;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(songListProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(songListProvider.notifier).fetchSongs(refresh: true);
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer to prevent memory leaks
    _debounceTimer?.cancel();
    
    // Update search query state immediately for UI feedback
    ref.read(searchQueryProvider.notifier).state = query;
    
    // Debounce API call to reduce server load
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _searchController.text == query) {
        ref.read(songListProvider.notifier).applyFilters();
      }
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(songListProvider.notifier).applyFilters();
    setState(() => _isSearchExpanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final songsAsync = ref.watch(songListProvider);
    final genresAsync = ref.watch(genresProvider);
    final selectedGenre = ref.watch(selectedGenreProvider);
    final selectedSort = ref.watch(selectedSortProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Modern Header with Search and Filters
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Row with Search Icon
                        Row(
                          children: [
                            Icon(
                              Icons.explore,
                              size: 28,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Discover Music',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Listen to earn tokens',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Search Toggle Button
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _isSearchExpanded = !_isSearchExpanded;
                                  if (!_isSearchExpanded) {
                                    _clearSearch();
                                  }
                                });
                              },
                              icon: Icon(
                                _isSearchExpanded ? Icons.close : Icons.search,
                                color: theme.colorScheme.primary,
                              ),
                              tooltip: _isSearchExpanded ? 'Close search' : 'Search',
                            ),
                          ],
                        ),
                        
                        // Search Bar (Expandable)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _isSearchExpanded
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _onSearchChanged,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: 'Search songs or artists...',
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon: searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: _clearSearch,
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: theme.colorScheme.surface,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Filter and Sort Row
                        Row(
                          children: [
                            // Genre Dropdown
                            Expanded(
                              child: genresAsync.when(
                                loading: () => const SizedBox.shrink(),
                                error: (error, stack) => const SizedBox.shrink(),
                                data: (genres) => PopupMenuButton<String?>(
                                  tooltip: 'Filter by genre',
                                  initialValue: selectedGenre,
                                  onSelected: (value) {
                                    ref.read(selectedGenreProvider.notifier).state = value;
                                    ref.read(songListProvider.notifier).applyFilters();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selectedGenre != null
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outline.withValues(alpha: 0.2),
                                        width: selectedGenre != null ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.category,
                                          size: 20,
                                          color: selectedGenre != null
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            selectedGenre ?? 'All Genres',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: selectedGenre != null ? FontWeight.bold : FontWeight.normal,
                                              color: selectedGenre != null
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          size: 24,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ],
                                    ),
                                  ),
                                  itemBuilder: (context) => [
                                    // All Genres option
                                    PopupMenuItem<String?>(
                                      value: null,
                                      child: Row(
                                        children: [
                                          Icon(
                                            selectedGenre == null ? Icons.check_circle : Icons.music_note,
                                            size: 20,
                                            color: selectedGenre == null
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'All Genres',
                                            style: TextStyle(
                                              fontWeight: selectedGenre == null ? FontWeight.bold : FontWeight.normal,
                                              color: selectedGenre == null
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    // All genre options
                                    ...genres.map((genre) => PopupMenuItem<String?>(
                                      value: genre,
                                      child: Row(
                                        children: [
                                          Icon(
                                            selectedGenre == genre ? Icons.check_circle : Icons.music_note,
                                            size: 20,
                                            color: selectedGenre == genre
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            genre,
                                            style: TextStyle(
                                              fontWeight: selectedGenre == genre ? FontWeight.bold : FontWeight.normal,
                                              color: selectedGenre == genre
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Sort Button
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              tooltip: 'Sort by',
                              initialValue: selectedSort,
                              onSelected: (value) {
                                ref.read(selectedSortProvider.notifier).state = value;
                                ref.read(songListProvider.notifier).applyFilters();
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.tune,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'createdAt',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 20,
                                        color: selectedSort == 'createdAt'
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Recent',
                                        style: TextStyle(
                                          fontWeight: selectedSort == 'createdAt'
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'playCount',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.trending_up,
                                        size: 20,
                                        color: selectedSort == 'playCount'
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Most Played',
                                        style: TextStyle(
                                          fontWeight: selectedSort == 'playCount'
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'title',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.sort_by_alpha,
                                        size: 20,
                                        color: selectedSort == 'title'
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'A-Z',
                                        style: TextStyle(
                                          fontWeight: selectedSort == 'title'
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        // Active Filters Summary
                        if (selectedGenre != null || searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (searchQuery.isNotEmpty)
                                  Chip(
                                    label: Text('Search: "$searchQuery"'),
                                    deleteIcon: const Icon(Icons.close, size: 18),
                                    onDeleted: _clearSearch,
                                    backgroundColor: theme.colorScheme.secondaryContainer,
                                  ),
                                if (selectedGenre != null)
                                  Chip(
                                    label: Text('Genre: $selectedGenre'),
                                    deleteIcon: const Icon(Icons.close, size: 18),
                                    onDeleted: () {
                                      ref.read(selectedGenreProvider.notifier).state = null;
                                      ref.read(songListProvider.notifier).applyFilters();
                                    },
                                    backgroundColor: theme.colorScheme.secondaryContainer,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Content based on state
            songsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: _buildErrorState(error),
              ),
              data: (songs) {
                if (songs.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(),
                  );
                }
                
                return SliverList.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    
                    // Convert to player song model on-demand (lazy conversion)
                    final playerSong = player_song.SongModel(
                      id: song.id,
                      title: song.title,
                      artist: song.artist?.username ?? 'Unknown Artist',
                      artistId: song.artist?.id ?? '',
                      albumArt: song.coverArt,
                      audioUrl: song.audioUrl,
                      duration: Duration(seconds: song.duration),
                      tokenReward: song.price.toInt(),
                      genre: song.genre,
                      isPremium: song.exclusive,
                      playCount: song.playCount,
                    );
                    
                    // Convert all songs for queue context
                    final allPlayerSongs = songs.map((s) => player_song.SongModel(
                      id: s.id,
                      title: s.title,
                      artist: s.artist?.username ?? 'Unknown Artist',
                      artistId: s.artist?.id ?? '',
                      albumArt: s.coverArt,
                      audioUrl: s.audioUrl,
                      duration: Duration(seconds: s.duration),
                      tokenReward: s.price.toInt(),
                      genre: s.genre,
                      isPremium: s.exclusive,
                      playCount: s.playCount,
                    )).toList();
                    
                    return SongListTile(
                      song: playerSong,
                      allSongs: allPlayerSongs,
                    );
                  },
                );
              },
            ),
            
            // Load more indicator - only show if there are more songs to load
            if (songsAsync.hasValue && 
                songsAsync.value!.isNotEmpty && 
                ref.watch(hasMoreSongsProvider))
              SliverToBoxAdapter(
                child: _buildLoadMoreIndicator(),
              ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              'Oops! Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No songs found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new music',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
